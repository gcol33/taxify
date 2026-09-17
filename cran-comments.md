## Submission

This is version 0.5.5 of taxify, currently on CRAN at 0.5.0 (accepted
2026-09-02). This release collects everything since 0.5.0. The substantive
changes:

* Fourteen fixes in the core matching path and its side paths (#56-#70), all
  cases where a result depended on something other than the name being
  matched -- how often it was submitted, which backbone happened to answer a
  neighbouring name, or which build was loaded earlier in the session -- plus
  a query-batch-size cap on `add_trait()` that silently emptied sources past
  it (#55).
* A name a backbone holds without placing it (WFO's `UNCHECKED`, COL's
  `PROVISIONALLY ACCEPTED`) no longer reads as accepted; it carries its own
  status in a new `taxonomic_status` column, and resolves through its
  basionym link where the backbone build carries one (#81). A homonym
  collision warning during enrichment joins now distinguishes a genuine tie
  from a concept none of the candidates share any authorship with (#87).
* Breaking: `add_alien_first_records()` takes `location =` in place of
  `country =`, so a source that records islands as their own regions (Hawaii,
  the Canary Islands) is no longer collapsed onto their country and does not
  backdate the country's first record to an island's earlier one.
* `taxify_pin()` is a new exported function pinning or releasing installed
  backbones/enrichments by name, alongside `normalize_kingdom_group()` and
  `backbone_fixed_kingdom()` (low-level building blocks) and
  `basionym_placement()` (exported, backing the #81 basionym resolution).
  taxify requires vectra (>= 0.12.4), released to CRAN 2026-09-16, which ties
  each `.vtr` index to the store it was built for.

Four new exported functions (`taxify_pin`, `normalize_kingdom_group`,
`backbone_fixed_kingdom`, `basionym_placement`); none removed. The package has
no reverse dependencies.

taxify matches taxonomic names against locally stored Darwin Core backbone
databases. The backbone and enrichment data are downloaded on demand from
GitHub Releases into the per-user directory returned by
`tools::R_user_dir("taxify", "data")`, only when the user explicitly calls a
matching or enrichment function. Nothing is written outside the session temp
directory and that per-user directory, and no download happens at load, check
or example time:

* Examples that execute use the bundled example database (a handful of species
  per backbone). Examples needing a full backbone are wrapped in `\dontrun{}`:
  they cannot run on a check machine, because the backbone files they need are
  downloads far too large to fetch during a check.
* Tests use small bundled fixtures and a local test manifest; no network.
* Vignettes do not download data (every chunk is `eval = FALSE`).

taxifydb is the optional companion package that builds the backbone and
enrichment data from source. It is used strictly conditionally (every call site
guards it with a `requireNamespace()` check that errors with an install
instruction if it is absent), and taxify is fully functional without it by
downloading pre-built data files. It is available from the r-universe
repository declared in `Additional_repositories`
(https://gcol33.r-universe.dev), and the sources are on GitHub
(https://github.com/gcol33/taxifydb).

## Test environments

* Local: Windows 11, R 4.6.0 (R CMD check --as-cran)
* win-builder: R-devel
* win-builder: R-release

## R CMD check results

* Local (--as-cran): 0 errors | 0 warnings | 0 notes
* win-builder (R-release, 4.6.1): 0 errors | 0 warnings | 1 note
* win-builder (R-devel, 2026-09-16 r90549): 0 errors | 0 warnings | 1 note

The note is "Suggests or Enhances not in mainstream repositories: taxifydb",
confirmed available via Additional_repositories in the same check output
("taxifydb   yes   https://gcol33.r-universe.dev"). taxifydb is used strictly
conditionally, guarded by `requireNamespace()`, and taxify is fully functional
without it.

Both win-builder flavours also flag URLs/DOIs that respond normally to a plain
request from here and are intermittent automated-request refusals on the
remote end, not broken links:

* https://www.itis.gov (README.md, the ITIS backbone's homepage): 404 on both
  flavours. Responds 200 to a plain request; ITIS intermittently refuses
  automated requests (also seen in the 0.5.0 submission).
* https://europlusmed.org/ (README.md, the Euro+Med backbone's homepage): 502
  on R-devel only. Responds 200 to a plain request.
* doi:10.1111/jbi.13623 (man/add_gift.Rd): 502 on R-release only. Resolves via
  the Crossref API (Wiley, "Journal of Biogeography"); Wiley's server
  occasionally gateway-errors an automated HEAD request.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

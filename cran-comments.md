## Submission

This is version 0.6.0 of taxify, currently on CRAN at 0.5.5 (published
2026-09-18). The release adds one feature and completes one rename:

* Requesting GBIF occurrence data for a matched name list. GBIF serves records
  by taxon key rather than by name, and a name it files under several keys (a
  homonym, or a name held once as accepted and again as a doubtful record)
  needs all of them. `gbif_request()` matches a list, collects every accepted
  key the matches resolve to and submits one asynchronous GBIF download
  covering them as a single predicate, so the list returns as one dataset
  under one citable DOI; `gbif_fetch()` waits for it, imports it and attaches
  the queried names; `gbif_backmatch()` links the returned records back to
  those names, which a join on `taxonKey` alone cannot do, because GBIF
  returns a key's descendants too and a record identified below species level
  carries its own key. A list whose keys exceed GBIF's 12,000-character query
  limit is split across downloads automatically. `cite()` reports the
  download's DOI beside the backbone citations.
* rgbif moves into Suggests. Resolving names and reading off their keys is
  offline work and does not need it; only sending the request does, and every
  call site guards it with `requireNamespace()`.
* Breaking: `taxify_candidates()` is removed in favour of `taxify_ids()`,
  which returns one row per name and accepted ID with the name, authorship,
  rank, status, family and occurrence count of each.

Five new exported functions (`gbif_request`, `gbif_fetch`, `gbif_backmatch`,
`taxify_ids`, `enrichment_authorship_col`); one removed (`taxify_candidates`).
The package has no reverse dependencies, so the removal breaks nothing on
CRAN.

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
  downloads far too large to fetch during a check. The same applies to the
  examples that contact GBIF, which additionally need an account.
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

<!-- FILL BEFORE SUBMITTING: the two win-builder lines below are placeholders.
     Neither flavour has been run for 0.6.0. Replace with the actual results,
     and drop this comment. -->

* Local (--as-cran): 0 errors | 0 warnings | 1 note
* win-builder (R-release): not yet run
* win-builder (R-devel): not yet run

The note is "Suggests or Enhances not in mainstream repositories: taxifydb",
confirmed available via Additional_repositories in the same check output
("taxifydb   yes   https://gcol33.r-universe.dev"). taxifydb is used strictly
conditionally, guarded by `requireNamespace()`, and taxify is fully functional
without it. The same note was present in the accepted 0.5.5 submission.

A "Days since last update" note is expected on the incoming checks, 0.5.5
having been published on 2026-09-18.

Both win-builder flavours have previously flagged URLs/DOIs that respond
normally to a plain request from here and are intermittent automated-request
refusals on the remote end, not broken links:

* https://www.itis.gov (README.md, the ITIS backbone's homepage). Responds 200
  to a plain request; ITIS intermittently refuses automated requests (also
  seen in the 0.5.0 and 0.5.5 submissions).
* https://europlusmed.org/ (README.md, the Euro+Med backbone's homepage).
  Responds 200 to a plain request.
* doi:10.1111/jbi.13623 (man/add_gift.Rd). Resolves via the Crossref API
  (Wiley, "Journal of Biogeography"); Wiley's server occasionally
  gateway-errors an automated HEAD request.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

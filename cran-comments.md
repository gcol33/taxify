## Submission

This is version 0.5.0 of taxify, currently on CRAN at 0.4.0 (accepted
2026-07-23). The 0.4.x series was developed on GitHub and never submitted, so
this release collects everything since 0.4.0. The substantive changes:

* Three backbones join the default fallback chain -- AviList, the Mammal
  Diversity Database and LPSN -- giving birds, mammals and prokaryotes a domain
  authority for the first time. This changes what `taxify()` returns by default
  for names in those groups, which is the intended effect.
* Homonym resolution: taxonomic status is now an ordered vocabulary rather than
  a test for `ACCEPTED`, so a name a backbone keeps as its own unreviewed
  concept no longer scores level with a synonym, and an ordering tiebreak no
  longer clears the ambiguity flag on a genuine name-level tie.
* Enrichment joins recover a name across backbone disagreement about where it
  was moved, and across GBIF's dropped infraspecific rank marker.
* A content-addressed store behind `taxify_lock()` / `taxify_restore()`: a
  lockfile can be restored to the exact data build it recorded, and a refreshed
  build no longer overwrites the one a lockfile pinned.

Twenty new exported functions, mostly trait-enrichment accessors. One export
was removed, `taxify_download_vtr()`, a deprecated alias of `taxify_download()`.
The package has no reverse dependencies.

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

* Local (--as-cran): 0 errors | 0 warnings | 1 note
* win-builder (R-release, 4.6.1): 0 errors | 0 warnings | 1 note
* win-builder (R-devel, 2026-08-31 r90457): 0 errors | 0 warnings | 1 note

The note is "Suggests or Enhances not in mainstream repositories: taxifydb",
confirmed available via Additional_repositories in the same check output
("taxifydb   yes   https://gcol33.r-universe.dev"). taxifydb is used strictly
conditionally, guarded by `requireNamespace()`, and taxify is fully functional
without it.

Both win-builder flavours report that same single note, and it additionally
lists https://www.itis.gov (linked from README.md, the homepage of the ITIS
backbone) as possibly invalid with status 404. The URL is correct and the site
responds 200 to a plain request from here; ITIS intermittently refuses
automated requests.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

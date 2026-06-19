## Submission

Resubmission of taxify (version 0.2.6).

The previous submission (0.2.5) was rejected because the companion package
taxifydb, listed in Suggests, is not in a mainstream repository and the
DESCRIPTION did not declare where to obtain it. This version adds an
`Additional_repositories` field pointing to the r-universe repository that
hosts taxifydb (https://gcol33.r-universe.dev), as the CRAN policy requires.

taxify matches taxonomic names against Darwin Core backbone databases. The
backbone and enrichment data are downloaded on demand from GitHub Releases to
the per-user cache directory returned by `tools::R_user_dir("taxify", "data")`,
and only when the user explicitly calls a matching or enrichment function.
Nothing is written outside the session temp directory or the user cache, and
no download happens at load, check, or example time:

* All examples that touch data are wrapped in `\dontrun{}`.
* Tests use small bundled fixtures (no network), via a local test manifest.
* Vignettes do not download data (all chunks are `eval = FALSE`).

taxifydb is the optional companion package that builds the backbone and
enrichment data from source. It is used strictly conditionally (every call
site guards it with a `requireNamespace()` check that errors with an install
instruction if it is absent), and taxify is fully functional without it by
downloading pre-built data files. It is available from the r-universe
repository declared in `Additional_repositories`, and the sources are on
GitHub (https://github.com/gcol33/taxifydb).

## Test environments

* Local: Windows 11, R 4.6.0 (R CMD check --as-cran)
* win-builder: R-devel

## R CMD check results

0 errors | 0 warnings | 1 note

Checked on win-builder R-devel (status: 1 NOTE). The NOTE is "New submission",
together with:

* "Suggests or Enhances not in mainstream repositories: taxifydb". The check
  confirms availability via the Additional_repositories specification
  ("taxifydb   yes   https://gcol33.r-universe.dev"), as the policy requires.
  taxifydb is used strictly conditionally (guarded by requireNamespace()) and
  taxify is fully functional without it.

* A "(possibly) invalid URL" for https://www.itis.gov/ in README.md, reported
  with status 404. The URL is correct and currently returns 200; the ITIS
  government site intermittently returns 404 to automated link checkers.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None (first submission).

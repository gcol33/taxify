## Submission

First submission of taxify to CRAN (version 0.2.5).

taxify matches taxonomic names against Darwin Core backbone databases. The
backbone and enrichment data are downloaded on demand from GitHub Releases to
the per-user cache directory returned by `tools::R_user_dir("taxify", "data")`,
and only when the user explicitly calls a matching or enrichment function.
Nothing is written outside the session temp directory or the user cache, and
no download happens at load, check, or example time:

* All examples that touch data are wrapped in `\dontrun{}`.
* Tests use small bundled fixtures (no network), via a local test manifest.
* Vignettes do not download data (all chunks are `eval = FALSE`).

## Test environments

* Local: Windows 11, R 4.6.0 (R CMD check --as-cran)
* win-builder: R-devel

## R CMD check results

0 errors | 0 warnings | 1 note

The remaining NOTE is:

* "Suggests or Enhances not in mainstream repositories: taxifydb". taxifydb is
  the optional companion package that builds the backbone and enrichment data
  from source. It is used strictly conditionally (every call site guards it with
  a `requireNamespace()` check that errors with an install instruction if it is
  absent), and taxify is fully functional without it by downloading pre-built
  data files. taxifydb is not yet on CRAN; it is available from GitHub
  (https://github.com/gcol33/taxifydb).

On a first submission the standard "New submission" NOTE also appears. The
database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None (first submission).

## Submission

First submission of taxify to CRAN.

taxify matches taxonomic names against Darwin Core backbone databases. The
backbone and enrichment data are downloaded on demand from GitHub Releases to
the per-user cache directory returned by `tools::R_user_dir("taxify", "data")`,
and only when the user explicitly calls a matching or enrichment function.
Nothing is written outside the session temp directory or the user cache, and
no download happens at load, check, or example time:

* All examples that touch data are wrapped in `\dontrun{}`.
* Tests use small bundled fixtures (no network), via a local test manifest.
* Vignettes do not download data.

## Test environments

* Local: Windows 11, R 4.6.0
* win-builder: R-devel (pending)

## R CMD check results

0 errors | 0 warnings | <NOTES pending local --as-cran run>

## Reverse dependencies

None (first submission).

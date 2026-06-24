## Submission

Resubmission of taxify (version 0.2.12), addressing the review feedback on the
earlier 0.2.6 submission.

Reviewer comment (Konstanze Lauseker): `\dontrun{}` should be reserved for
examples that genuinely cannot be executed; please unwrap runnable examples or
use `\donttest{}`.

Addressed: taxify now ships a small bundled example database
(`taxify_example_data()`), and the examples set
`options(taxify.data_dir = taxify_example_data())` so matching and enrichment
run fully offline against it. No example is wrapped in `\dontrun{}` any more.
The only `\donttest{}` examples left are `add_pignatti()` (fetched live via the
suggested TR8 package) and `list_enrichments()` (reads the online manifest,
falling back to the bundled copy). The version was advanced from 0.2.6 to
0.2.12 because the package gained features in the meantime (regional plant
trait sets, the configurable data directory, and the bundled example database).

taxify matches taxonomic names against locally stored Darwin Core backbone
databases. The full backbone and enrichment data are downloaded on demand from
GitHub Releases to the per-user cache directory returned by
`tools::R_user_dir("taxify", "data")`, only when the user explicitly calls a
matching or enrichment function. Nothing is written outside the session temp
directory or the user cache, and no download happens at load, check, or example
time:

* Examples run offline against the bundled example database; none download data.
* Tests use small bundled fixtures (no network), via a local test manifest.
* Vignettes do not download data (all chunks are `eval = FALSE`).

taxifydb is the optional companion package that builds the backbone and
enrichment data from source. It is used strictly conditionally (every call
site guards it with a `requireNamespace()` check that errors with an install
instruction if it is absent), and taxify is fully functional without it by
downloading pre-built data files. It is available from the r-universe
repository declared in `Additional_repositories`
(https://gcol33.r-universe.dev), and the sources are on GitHub
(https://github.com/gcol33/taxifydb).

## Test environments

* Local: Windows 11, R 4.6.0 (R CMD check --as-cran)
* win-builder: R-devel

## R CMD check results

0 errors | 0 warnings | 1 note

The NOTE is "New submission", together with:

* "Suggests or Enhances not in mainstream repositories: taxifydb". The check
  confirms availability via the Additional_repositories specification
  ("taxifydb   yes   https://gcol33.r-universe.dev"), as the policy requires.
  taxifydb is used strictly conditionally (guarded by requireNamespace()) and
  taxify is fully functional without it.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None (first submission).

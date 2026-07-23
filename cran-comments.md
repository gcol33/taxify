## Submission

This is a feature update (version 0.4.0) of taxify, currently on CRAN at 0.3.4.

The version jumps to 0.4.0 because one argument was renamed with no alias, which
breaks existing code: `backend =` is now `backbone =` in `taxify()` and in every
verb that names a data source. A backbone is a data source and its `.vtr` file;
a backend is the S3 handle that reads one, and the two had shared a name. The
rename is documented at the top of NEWS.md.

Since 0.3.4 the package also gained region-constrained matching beyond plants
(marine ecoregions alongside the WGSRPD plant scheme), nine name-resolution verbs
(`parse_name()`, `id2name()`, `upstream()`, `downstream()`, `reconcile()`,
`comm2sci()`, `sci2comm()`, `class2tree()`, `lowest_common()`), a reproducibility
lockfile (`taxify_lock()`), authorship-aware homonym disambiguation, an offline mode
(`options(taxify.offline = TRUE)`), and further backbones and enrichment
datasets. See NEWS.md for details.

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

The NOTE is:

* "Suggests or Enhances not in mainstream repositories: taxifydb". The check
  confirms availability via the Additional_repositories specification
  ("taxifydb   yes   https://gcol33.r-universe.dev"), as the policy requires.
  taxifydb is used strictly conditionally (guarded by requireNamespace()) and
  taxify is fully functional without it.

The same NOTE lists https://www.itis.gov as a possibly invalid URL. That is
the official ITIS (Integrated Taxonomic Information System) homepage and it is
valid; the US government server intermittently returns 404 to the automated
request, and it returned 200 when checked directly while preparing this
submission.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

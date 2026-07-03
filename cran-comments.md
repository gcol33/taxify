## Submission

This is a feature update (version 0.3.2) of taxify, currently on CRAN at 0.2.12.

Since 0.2.12 the package gained a cross-source trait interface: `add_trait()`
attaches one trait across every enrichment that carries it, harmonizing their
vocabularies and units against the source values. `list_traits()` and
`trait_info()` describe the registry. Several backbones and enrichment datasets
were added, and the per-source `add_*()` doors were renamed to their source
names (the trait name is reserved for `add_trait()`). See NEWS.md for details.

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

If the URL checker flags https://www.itis.gov, that is the official ITIS
(Integrated Taxonomic Information System) homepage and is valid; the US
government server intermittently returns 404 to the automated HEAD request,
but the page resolves with status 200 in a browser and via curl.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

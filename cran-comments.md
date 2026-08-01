## Submission

This is a patch release (version 0.4.3) of taxify, currently on CRAN at 0.4.0
(accepted 2026-07-23, 9 days before this submission). The short gap is because
this release fixes two things discovered right after 0.4.0 shipped:

* The bundled enrichment datasets are built by resolving each source name
  against a subset of taxify's fifteen supported backbones, then joining that
  union to a `taxify()` result. That subset only covered seven of the fifteen,
  so an enrichment value keyed to a name accepted solely by one of the other
  eight domain-specific backbones (Euro+Med, Species Fungorum, AlgaeBase,
  FishBase, SeaLifeBase, Reptile Database, LCVP, WCVP) could silently fail to
  join even though the trait data existed. `inst/manifest.json` now points at
  enrichment data rebuilt against all fifteen backbones.
* Several vignettes and the README described WFO as the default backbone.
  The actual default is a COL-first fallback chain (COL, GBIF, and ITIS are
  installed on first use); the text has been corrected.

No exported function signature or behavior changed; this is a documentation
correction plus a data-pointer update in the manifest, not a code fix, so
there is nothing to test beyond the R CMD check / win-builder cycle below.

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
* win-builder: R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

"Checking CRAN incoming feasibility" reports an INFO (not a NOTE) confirming
taxifydb's availability via Additional_repositories
("taxifydb   yes   https://gcol33.r-universe.dev"), as the policy requires.
taxifydb is used strictly conditionally (guarded by requireNamespace()) and
taxify is fully functional without it.

Two citation URLs in the README and in `add_fishbase()`/`add_sealifebase()`
documentation (https://www.fishbase.org, https://www.sealifebase.org) sit
behind a Cloudflare managed challenge that blocks automated tools (confirmed
with curl, a browser-impersonating HTTP client, and a stealth headless
browser -- all get the interstitial; a normal browser passes). Neither URL is
fetched by any package code; FishBase/SeaLifeBase enrichment data is built
via the rfishbase R package's API, not by downloading these pages. Both URLs
are unchanged from 0.4.0, which CRAN accepted with them present.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

## Submission after archival

taxify was archived on 2026-11-02 ("Left 4.4GB in .local/share/R"), after
Prof. Ripley's report of 2026-10-25 that taxify had stored 4.4 GB (the COL,
GBIF and WFO backbones) in `~/.local/share/R/taxify` on his check server.

Version 0.7.0, accepted on 2026-10-27, stopped taxify from writing there
unasked, but it did not remove what earlier versions had already written:
those files were left by the checks of taxify 0.2.12 / 0.3.4 (June/July
2026), whose tests ran against the real data directory, and nothing in 0.7.0
deleted them. This version does:

* Each session records when it first reads a backbone or enrichment build (a
  `.last_used` stamp in the build's directory).
* When the package is loaded, every outdated build in the data directory that
  has not been read or downloaded for `getOption("taxify.max_unused_days")`
  days (default 90) is deleted, together with the files of interrupted
  downloads and the directories this leaves empty, and a startup message
  reports the space freed. A build is outdated when it is stored in the
  uncompressed format used before 0.7.0, or when a newer build of it has been
  published. The current build of a backbone stays, so a user who has not run
  taxify for a few months does not have to download it again.
  `options(taxify.max_unused_days = Inf)` turns this off.
* On the check server, the first check of this version loads the package with
  the files from June/July in place (old format, more than 90 days old, never
  read since), removes them, and removes the empty `~/.local/share/R/taxify`
  directory. A test reproduces this on a data directory with an old-format
  build aged 120 days (tests/testthat/test-taxify-clean.R).
* `taxify_clean(unused_days = )` applies the same rule on demand.

The behaviour of 0.7.0 stays in place: no backbone is downloaded unless the
user asks for it (`install_backbones()` / `taxify_download()`; any other
function asks via `utils::askYesNo()` in an interactive session and stops
with an error in a non-interactive one), a refresh replaces the installed
build, the stores are several times smaller in the storage format of vectra
0.14.0, and `taxify_clean()` / `taxify_store()` manage and list the data.

What is written where:

* Data are downloaded from GitHub Releases into
  `tools::R_user_dir("taxify", "data")`, only on an explicit install or after
  the user confirms. Nothing is written outside that directory and the session
  temp directory, and no download happens at load, check or example time.
* Examples that execute use the bundled example database (a handful of species
  per backbone), read-only inside the package installation. Examples needing a
  full backbone are wrapped in `\dontrun{}`, as are the examples that contact
  GBIF, which additionally need an account.
* Tests run offline against small fixtures in a directory under `tempdir()`.
* Vignettes are precomputed; the chunks that run read only what ships with the
  package, and every chunk that needs a backbone is `eval = FALSE`.

taxifydb is the optional companion package that builds the backbone and
enrichment data from source. It is used strictly conditionally (every call site
guards it with a `requireNamespace()` check that errors with an install
instruction if it is absent), and taxify is fully functional without it by
downloading pre-built data files. It is available from the r-universe
repository declared in `Additional_repositories`
(https://gcol33.r-universe.dev), and the sources are on GitHub
(https://github.com/gcol33/taxifydb).

## Test environments

* Local: Windows 11, R-devel (2026-10-26 r90766 ucrt), R CMD check --as-cran
  --run-donttest with `_R_CHECK_CRAN_INCOMING_CHECK_FILE_URIS_=TRUE`, and
  R_USER_DATA_DIR / R_USER_CACHE_DIR pointed at empty directories (still empty
  afterwards).
* win-builder R-devel (2026-11-01 r90825 ucrt): Status 1 NOTE, check time
  248 s, for a first build of 0.7.1 whose rule removed every build left unused.
  This version narrows the rule to outdated builds (one R function and its
  tests); the local R-devel check above is of this version.

## R CMD check results

0 errors | 0 warnings | 1 note

The note is the incoming-feasibility note: "New submission / Package was
archived on CRAN" (answered above), and "Suggests or Enhances not in
mainstream repositories: taxifydb", confirmed available via
Additional_repositories in the same check output ("taxifydb   yes
https://gcol33.r-universe.dev"). taxifydb is used strictly conditionally,
guarded by `requireNamespace()`, and taxify is fully functional without it.
The same note was present in the accepted 0.7.0 submission.

The database names in the Description (WFO, COL, GBIF, etc.) are single-quoted.

## Reverse dependencies

None.

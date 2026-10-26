## Submission

This is version 0.7.0 of taxify, currently on CRAN at 0.6.0 (published
2026-09-30). It is submitted 25 days after 0.6.0 because CRAN asked for it:
Prof. Ripley reported on 2026-10-25 that taxify had stored 4.4 GB in
`~/.local/share/R/taxify` on his check server (the COL, GBIF and WFO
backbones), which does not comply with the policy that user data directories
be kept as small as possible by default and actively managed, and scheduled
the package for archival on 2026-11-02. I am aware of the request to reduce
the update frequency; this release answers the report above and would not
have been submitted otherwise.

It requires vectra 0.14.0 (on CRAN since 2026-10-26, submitted for the same
reason): its new
storage format makes the backbone data taxify downloads several times
smaller, so what a user stores is smaller as well as managed.

Those files were written by the checks of taxify 0.2.12 / 0.3.4 (June/July
2026), whose tests ran against the real data directory and let a version
check download the full backbones. A check of the 0.3.4 tarball with
`R_USER_DATA_DIR` pointed at an empty directory reproduces it: `col.vtr`,
`gbif.vtr` and `wfo.vtr` appear there. Since 0.4.0 the tests run offline in a
directory under `tempdir()`, and the same sandboxed check of the CRAN version
0.6.0 and of this version (`--as-cran --run-donttest`) leaves the user data
directory empty.

This version changes the defaults so that the data directory stays small and
is managed:

* No backbone is downloaded unless the user asks for it. `install_backbones()`
  and `taxify_download()` install; any other function that needs a backbone
  that is not on disk asks via `utils::askYesNo()` in an interactive session
  and stops with an error naming the `install_backbones()` call in a
  non-interactive one. Scripts can opt in with
  `options(taxify.auto_download = TRUE)`.
* A refresh replaces the installed build in place for enrichments too (it did
  so already for backbones); superseded builds are no longer kept by default.
* Downloads clear the partial files an interrupted download left behind.
* The new `taxify_clean()` removes superseded builds and interrupted
  downloads, named backbones or enrichments, or the whole data directory.
  `taxify_store()` lists what is on disk with sizes, and the README and the
  backbones vignette say where the data lives and how to remove it.

The release also carries the changes made since 0.6.0 (two vegetation-unit
backbones, `n_ids`/`accepted_ids` in every result, GBIF request options); see
NEWS.md. One new exported function, `taxify_clean()`, is added for the data
directory.

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

* Local: Windows 11, R-devel (2026-09-29 r90598 ucrt), R CMD check --as-cran,
  with R_USER_DATA_DIR pointed at an empty directory (still empty afterwards).
  The win-builder R-devel queue did not move on 2026-10-26 from 17:38 to past
  21:30 (server time), for every package in it, so R-devel was checked
  locally.
* win-builder: R-release

## R CMD check results

* Local R-devel (--as-cran): Status OK
* win-builder (R-release, 4.6.1): 0 errors | 0 warnings | 1 note

The note is "Suggests or Enhances not in mainstream repositories: taxifydb",
confirmed available via Additional_repositories in the same check output
("taxifydb   yes   https://gcol33.r-universe.dev"). taxifydb is used strictly
conditionally, guarded by `requireNamespace()`, and taxify is fully functional
without it. The same note was present in the accepted 0.5.5 submission.

A "Days since last update" note is expected on the incoming checks, 0.6.0
having been published on 2026-09-30; the submission answers CRAN's request
above.

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

# Regression tests for #50: enrich_by_group() joined on a bare accepted-name
# string, so a name that is a homonym in the enrichment source (two distinct
# concepts sharing one canonical_name, told apart only by authorship) could
# silently attach the wrong concept's data -- add_wcvp() reported
# *Erigeron pulchellus* Michx. (eastern North America) as native in Germany,
# which was actually *Erigeron pulchellus* Hoppe & Hornsch. ex Bluff &
# Fingerh.'s European range.

setup_mock_wfo <- function() {
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
}

# Build a WCVP-shaped enrichment .vtr where "Quercus robur" covers two
# distinct concepts (authorship "L." vs the fictitious homonym "Mill."):
# the "L." concept is native to EUR and introduced in NAM, and the "Mill."
# concept -- a different taxon that just happens to share the bare name --
# has its own native record in GER. Pre-fix, a GER lookup would have kept
# whichever row survived the per-group dedup regardless of concept.
setup_mock_wcvp <- function() {
  data_dir <- tempfile("taxify_wcvp_auth_")
  latest <- file.path(data_dir, "enrichment", "wcvp", "latest")
  dir.create(latest, recursive = TRUE)

  wcvp <- data.frame(
    canonical_name = c("Quercus robur", "Quercus robur", "Quercus robur"),
    tdwg_code      = c("EUR", "NAM", "GER"),
    native_status  = c("native", "introduced", "native"),
    taxon_authors  = c("L.", "L.", "Mill."),
    stringsAsFactors = FALSE
  )
  vectra::write_vtr(wcvp, file.path(latest, "wcvp.vtr"))
  jsonlite::write_json(
    list(version = "2026.06", static = TRUE, license = "CC BY 4.0"),
    file.path(latest, "meta.json"), auto_unbox = TRUE
  )

  set_backbone_path("enrichment_wcvp", NULL)
  .taxify_env[[".enrichment_version_checked.wcvp"]] <- NULL

  data_dir
}


test_that("add_wcvp() does not attach a homonym's native range", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  expect_equal(r$accepted_authorship, "L.")

  # EUR and NAM both belong to the "L." concept x actually resolved to, and
  # keep working as before -- the authorship match is unambiguous, so this
  # is the silent, no-warning path.
  in_concept <- expect_no_warning(
    add_wcvp(r, region = c("EUR", "NAM"), verbose = FALSE))
  expect_equal(in_concept$native_status_EUR, "native")
  expect_equal(in_concept$native_status_NAM, "introduced")

  # GER only exists for the "Mill." homonym in this fixture: it must come
  # back NA, not the wrong concept's "native".
  out <- expect_no_warning(
    add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE))
  expect_equal(out$native_status_EUR, "native")
  expect_true(is.na(out$native_status_GER))
})

test_that("add_wcvp() warns once when a homonym collision cannot be resolved", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  # A resolved authorship that matches neither concept in the fixture (e.g.
  # a third backbone's homonym record) cannot be told apart at all -- the
  # earlier "does not attach a homonym's native range" case shows the
  # authorship still resolves the right concept; this is genuine ambiguity.
  r <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  r$accepted_authorship <- "Nomatch."

  expect_warning(add_wcvp(r, region = "GER", verbose = FALSE),
                 "more than one concept")
  out <- suppressWarnings(add_wcvp(r, region = c("EUR", "GER"), verbose = FALSE))
  expect_true(is.na(out$native_status_EUR))
  expect_true(is.na(out$native_status_GER))
})

test_that("a single-concept name is unaffected by the authorship check", {
  setup_mock_wfo()
  data_dir <- setup_mock_wcvp()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  r <- taxify("Quercus petraea", backbone = "wfo", verbose = FALSE)
  # Not in the fixture at all: normal "no data for this name" path, no warning.
  expect_no_warning(add_wcvp(r, region = "EUR", verbose = FALSE))
})

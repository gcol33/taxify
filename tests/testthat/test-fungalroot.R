# Tests for add_fungalroot() — genus-level mycorrhizal type enrichment

setup_mock_backend <- function() {
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, bb_path)
  be
}

# Build a minimal fungalroot enrichment .vtr (+ static meta.json) inside a
# temporary data dir and point taxify at it. Returns the data dir.
setup_mock_fungalroot <- function() {
  data_dir <- tempfile("taxify_fr_")
  latest <- file.path(data_dir, "enrichment", "fungalroot", "latest")
  dir.create(latest, recursive = TRUE)

  fr <- data.frame(
    canonical_name      = c("Quercus", "Pinus", "Trifolium"),
    genus               = c("Quercus", "Pinus", "Trifolium"),
    mycorrhizal_type    = c("EcM", "EcM", "AM"),
    mycorrhizal_status  = c("mycorrhizal", "mycorrhizal", "mycorrhizal"),
    mycorrhizal_records = c(163L, 500L, 193L),
    stringsAsFactors    = FALSE
  )
  vectra::write_vtr(fr, file.path(latest, "fungalroot.vtr"))
  jsonlite::write_json(
    list(version = "2026.06", static = TRUE, license = "CC BY-NC 4.0"),
    file.path(latest, "meta.json"), auto_unbox = TRUE
  )

  # Clear any cached path / version-check flag from earlier tests
  set_backbone_path("enrichment_fungalroot", NULL)
  .taxify_env[[".enrichment_version_checked.fungalroot"]] <- NULL

  data_dir
}

test_that("add_fungalroot joins mycorrhizal type by genus", {
  setup_mock_backend()
  data_dir <- setup_mock_fungalroot()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  result <- taxify("Quercus robur", verbose = FALSE)
  enriched <- add_fungalroot(result, verbose = FALSE)

  expect_true(all(c("mycorrhizal_type", "mycorrhizal_status",
                    "mycorrhizal_records") %in% names(enriched)))
  expect_equal(enriched$mycorrhizal_type, "EcM")
  expect_equal(enriched$mycorrhizal_status, "mycorrhizal")
  expect_equal(enriched$mycorrhizal_records, 163L)
})

test_that("add_fungalroot annotates any species in a covered genus", {
  setup_mock_backend()
  data_dir <- setup_mock_fungalroot()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  # Pinus sylvestris is not in the enrichment by binomial, but its genus is.
  result <- taxify("Pinus sylvestris", verbose = FALSE)
  enriched <- add_fungalroot(result, verbose = FALSE)

  expect_equal(enriched$mycorrhizal_type, "EcM")
  expect_equal(enriched$mycorrhizal_records, 500L)
})

test_that("add_fungalroot returns NA for genera not in FungalRoot", {
  setup_mock_backend()
  data_dir <- setup_mock_fungalroot()
  old <- options(taxify.data_dir = data_dir)
  on.exit(options(old), add = TRUE)

  # Picea is in the mock backbone but absent from the enrichment .vtr
  result <- taxify("Picea polita", verbose = FALSE)
  enriched <- add_fungalroot(result, verbose = FALSE)

  expect_true(is.na(enriched$mycorrhizal_type))
  expect_true(is.na(enriched$mycorrhizal_records))
})

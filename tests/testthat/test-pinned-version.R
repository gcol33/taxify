# A pinned version names a different release tag (#62).
#
# The release layout is <tag>/<name>.vtr with the version at the end of the
# tag. Requesting an older version used to resolve to the current asset and
# stamp the requested version onto it, with pinned = TRUE stopping the next
# session from ever correcting the label.

file_url <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (!startsWith(path, "/")) path <- paste0("/", path)
  paste0("file://", path)
}

stage_release <- function(root, tag, file, bytes) {
  d <- file.path(root, tag)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  writeBin(charToRaw(bytes), file.path(d, file))
  file_url(file.path(d, file))
}

inject_manifest <- function(m) {
  orig <- .taxify_env$manifest
  .taxify_env$manifest <- m
  withr::defer(.taxify_env$manifest <- orig, envir = parent.frame())
}

test_that("versioned_asset_url() swaps the version at the end of the tag", {
  base <- "https://github.com/gcol33/taxifydb/releases/download"
  expect_equal(versioned_asset_url(paste0(base, "/wfo-2026.08/wfo.vtr"), "2026.06"),
               paste0(base, "/wfo-2026.06/wfo.vtr"))
  expect_equal(
    versioned_asset_url(paste0(base, "/enrichment-2026.08/iucn.vtr"), "2026.06"),
    paste0(base, "/enrichment-2026.06/iucn.vtr"))
  expect_equal(
    versioned_asset_url(paste0(base, "/genus_register-2026.08/genus_register.vtr"),
                        "2026.07"),
    paste0(base, "/genus_register-2026.07/genus_register.vtr"))
  expect_null(versioned_asset_url("https://example.org/wfo.vtr", "2026.06"))
  expect_null(versioned_asset_url(NULL, "2026.06"))
})

test_that("manifest_url() points a pinned version at its own tag, and refuses one never published", {
  root   <- tempfile("pinrel_")
  latest <- stage_release(root, "wfo-2026.08", "wfo.vtr", "current")
  old    <- stage_release(root, "wfo-2026.06", "wfo.vtr", "older")
  inject_manifest(list(schema_version = 2L, backends = list(
    wfo = list(latest = "2026.08", full_url = latest))))

  expect_equal(manifest_url("wfo", "latest"), latest)
  expect_equal(manifest_url("wfo", "2026.06"), old)
  expect_error(manifest_url("wfo", "2025.01"),
               "Version '2025.01' of 'wfo' is not published")
})

test_that("a pinned enrichment download fetches that version's bytes", {
  root   <- tempfile("pinenr_")
  latest <- stage_release(root, "enrichment-2026.08", "mockpin.vtr", "current")
  stage_release(root, "enrichment-2026.06", "mockpin.vtr", "older")
  inject_manifest(list(schema_version = 2L, enrichments = list(
    mockpin = list(latest = "2026.08", full_url = latest, static = FALSE))))
  withr::local_options(taxify.data_dir = tempfile("pinenr_dd_"))

  path <- download_enrichment("mockpin", version = "2026.06", verbose = FALSE)
  expect_equal(rawToChar(readBin(path, "raw", 100L)), "older")
  meta <- read_enrichment_meta(path)
  expect_equal(meta$version, "2026.06")
  expect_true(isTRUE(meta$pinned))

  expect_error(download_enrichment("mockpin", version = "2025.01",
                                   verbose = FALSE),
               "not published")
  expect_false(file.exists(enrichment_vtr_path("mockpin", "2025.01")))
})

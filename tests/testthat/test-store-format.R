# A store's release asset carries its store format in the name
# (`<name>.tdcf.vtr`); the local copy keeps the plain name, and a version
# published before the format existed is reached by its plain-named asset.

test_that("a format-qualified asset maps to its plain local name", {
  base <- "https://github.com/o/r/releases/download/enrichment-2026.08"
  expect_identical(local_asset_name(paste0(base, "/leda_references.tdcf.vtr")),
                   "leda_references.vtr")
  expect_identical(local_asset_name("col_species_profile.tdcf.vtr"),
                   "col_species_profile.vtr")
  expect_identical(local_asset_name("col_species_profile.vtr"),
                   "col_species_profile.vtr")
  expect_identical(local_asset_name("wfo-0123456789abcdef0123456789abcdef.vtr"),
                   "wfo-0123456789abcdef0123456789abcdef.vtr")
})

test_that("a pinned version without a format-qualified asset falls back to the plain one", {
  base <- "https://github.com/o/r/releases/download/wfo-2026.06/wfo.tdcf.vtr"
  tried <- character(0L)
  local_mocked_bindings(asset_url_exists = function(url) {
    tried <<- c(tried, url)
    !grepl("tdcf", url, fixed = TRUE)
  })
  expect_identical(
    pinned_asset_url(base, "wfo", "2024.12"),
    "https://github.com/o/r/releases/download/wfo-2024.12/wfo.vtr")
  expect_identical(tried[[1L]],
                   "https://github.com/o/r/releases/download/wfo-2024.12/wfo.tdcf.vtr")
})

test_that("a pinned version with neither asset is refused", {
  local_mocked_bindings(asset_url_exists = function(url) FALSE)
  expect_error(
    pinned_asset_url("https://github.com/o/r/releases/download/wfo-2026.06/wfo.tdcf.vtr",
                     "wfo", "1999.01", latest = "2026.06"),
    "not published")
})

test_that("the bundled manifest points every store at a format-qualified asset", {
  m <- jsonlite::read_json(system.file("manifest_v3.json", package = "taxify"))
  expect_identical(m$schema_version, 3L)
  urls <- c(vapply(m$backends, `[[`, "", "full_url"),
            vapply(m$enrichments, `[[`, "", "full_url"))
  expect_true(all(grepl("\\.tdcf\\.vtr$", urls)))
})

# InvaCost economic-cost aggregates. The runtime door joins three per-species
# indicators (cumulative 2017-USD cost, number of estimates, dominant cost type)
# from a pre-built .vtr; the aggregation itself happens at build time in
# taxifydb. These run against a mock enrichment, so no network or bundled
# fixture is needed.

invacost_fixture <- function() data.frame(
  canonical_name = c("Solenopsis invicta", "Rattus rattus"),
  cost_total_usd = c(1.2e9, 3.4e8),
  cost_n         = c(42L, 17L),
  cost_type      = c("damage", "mixed"),
  stringsAsFactors = FALSE
)

mk_res <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

test_that("add_invacost() attaches the three per-species cost columns", {
  install_mock_enrichment("invacost", invacost_fixture())

  r <- add_invacost(mk_res(c("Solenopsis invicta", "Rattus rattus")),
                    verbose = FALSE)
  expect_true(all(c("invacost_cost_total_usd", "invacost_cost_n",
                    "invacost_cost_type") %in% names(r)))
  expect_equal(r$invacost_cost_total_usd[r$accepted_name == "Solenopsis invicta"],
               1.2e9)
  expect_equal(r$invacost_cost_n[r$accepted_name == "Rattus rattus"], 17L)
  expect_equal(r$invacost_cost_type[r$accepted_name == "Solenopsis invicta"],
               "damage")
})

test_that("add_invacost() leaves a species absent from InvaCost all-NA", {
  install_mock_enrichment("invacost", invacost_fixture())

  r <- add_invacost(mk_res("Abies alba"), verbose = FALSE)
  cost_cols <- grep("^invacost_", names(r), value = TRUE)
  expect_length(cost_cols, 3L)
  expect_true(all(vapply(cost_cols, function(cc) is.na(r[[cc]][1L]), logical(1))))
})

test_that("InvaCost is registered in the bundled manifest as a static enrichment", {
  # Read the shipped manifest directly (offline, deterministic) rather than
  # list_enrichments(), which would fetch the remote main-branch manifest first.
  mpath <- system.file("manifest.json", package = "taxify")
  skip_if_not(nzchar(mpath) && file.exists(mpath), "bundled manifest not found")
  m <- jsonlite::read_json(mpath, simplifyVector = FALSE)
  expect_true("invacost" %in% names(m$enrichments))
  expect_true(isTRUE(m$enrichments$invacost$static))
  expect_setequal(
    unlist(m$enrichments$invacost$trait_cols),
    c("cost_total_usd", "cost_n", "cost_type")
  )
})

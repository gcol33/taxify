# add_euromed_distribution(): per-area Euro+Med status, joined by accepted name,
# with ISO country codes read against the areas the source carries.

local_example_db <- function(env = parent.frame()) {
  old <- options(taxify.data_dir = taxify_example_data(),
                 taxify.offline = TRUE)
  withr::defer(options(old), envir = env)
}

test_that("euromed_areas() lists areas with their country codes", {
  local_example_db()
  a <- euromed_areas()
  expect_named(a, c("area_code", "area_name", "area_level", "iso2"))
  expect_equal(a$iso2[a$area_code == "Au(A)"], "AT")
  expect_true(is.na(a$iso2[a$area_code == "Au"]))
})

test_that("an ISO code reads as the area of that country", {
  local_example_db()
  r <- taxify("Robinia pseudoacacia", backbone = "wfo")
  out <- add_euromed_distribution(r, region = "DE", verbose = FALSE)
  expect_equal(out$euromed_status, "naturalised")
  out <- add_euromed_distribution(r, region = "LI", verbose = FALSE)
  expect_equal(out$euromed_status, "introduced")
})

test_that("an area code reads as itself and several regions suffix", {
  local_example_db()
  r <- taxify("Robinia pseudoacacia", backbone = "wfo")
  out <- add_euromed_distribution(r, region = c("AT", "Ga(F)"),
                                  verbose = FALSE)
  expect_equal(out[["euromed_status_Au(A)"]], "naturalised")
  expect_equal(out[["euromed_status_Ga(F)"]], "native")
})

test_that("cols = 'all' carries the wording, references and the Euro+Med UUID", {
  local_example_db()
  r <- taxify("Robinia pseudoacacia", backbone = "wfo")
  out <- add_euromed_distribution(r, region = "LI", cols = "all",
                                  verbose = FALSE)
  expect_equal(out$euromed_status_detail,
               "introduced: uncertain degree of naturalisation")
  expect_equal(out$euromed_status_source, "ref-ex-2")
  expect_equal(out$taxon_id, "example-taxon-robinia")
})

test_that("an unknown region is refused", {
  local_example_db()
  r <- taxify("Robinia pseudoacacia", backbone = "wfo")
  expect_error(add_euromed_distribution(r, region = "ZZ", verbose = FALSE),
               "neither an ISO code")
  expect_error(add_euromed_distribution(r), "'region' is required")
})

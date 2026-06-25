# Tests for the FishBase and SeaLifeBase backbone backends, run offline against
# the bundled example database.

test_that("fishbase and sealifebase resolve to backend objects", {
  expect_s3_class(resolve_backend("fishbase"), "taxify_fishbase")
  expect_s3_class(resolve_backend("sealifebase"), "taxify_sealifebase")
})

test_that("taxify matches a fish against the FishBase backbone", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Gadus morhua", backend = "fishbase", verbose = FALSE)
  expect_equal(res$accepted_name, "Gadus morhua")
  expect_equal(res$backend, "fishbase")
})

test_that("taxify matches an invertebrate against the SeaLifeBase backbone", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Octopus vulgaris", backend = "sealifebase", verbose = FALSE)
  expect_equal(res$accepted_name, "Octopus vulgaris")
  expect_equal(res$backend, "sealifebase")
})

test_that("unknown backend error lists fishbase and sealifebase", {
  expect_error(resolve_backend("nope"), "fishbase")
  expect_error(resolve_backend("nope"), "sealifebase")
})

# Tests for the FishBase and SeaLifeBase backbone backbones, run offline against
# the bundled example database.

test_that("fishbase and sealifebase resolve to backbone objects", {
  expect_s3_class(resolve_backend("fishbase"), "taxify_fishbase")
  expect_s3_class(resolve_backend("sealifebase"), "taxify_sealifebase")
})

test_that("taxify matches a fish against the FishBase backbone", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Gadus morhua", backbone = "fishbase", verbose = FALSE)
  expect_equal(res$accepted_name, "Gadus morhua")
  expect_equal(res$backbone, "fishbase")
})

test_that("taxify matches an invertebrate against the SeaLifeBase backbone", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Octopus vulgaris", backbone = "sealifebase", verbose = FALSE)
  expect_equal(res$accepted_name, "Octopus vulgaris")
  expect_equal(res$backbone, "sealifebase")
})

test_that("unknown backbone error lists fishbase and sealifebase", {
  expect_error(resolve_backend("nope"), "fishbase")
  expect_error(resolve_backend("nope"), "sealifebase")
})

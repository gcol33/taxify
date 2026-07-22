# Tests for the LCVP and WCVP vascular-plant backbones: runtime dispatch,
# offline matching against the bundled example database, and the shared
# plant-genus register extractor.

test_that("lcvp and wcvp resolve to their backbone objects", {
  lc <- taxify:::resolve_backend("lcvp")
  wc <- taxify:::resolve_backend("wcvp")

  expect_s3_class(lc, "taxify_lcvp")
  expect_s3_class(wc, "taxify_wcvp")
  expect_equal(lc$name, "lcvp")
  expect_equal(wc$name, "wcvp")
  expect_equal(lc$col_map$genus, "genus")
  expect_equal(wc$col_map$genus, "genus")
})

test_that("resolve_backend error lists the new backbones", {
  expect_error(taxify:::resolve_backend("nonsense"), "lcvp")
  expect_error(taxify:::resolve_backend("nonsense"), "wcvp")
})

test_that("lcvp matches an accepted plant name and resolves a synonym", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Quercus robur", backbone = "lcvp", verbose = FALSE)
  expect_equal(res$accepted_name, "Quercus robur")
  expect_equal(res$match_type, "exact")
  expect_equal(res$family, "Fagaceae")
  expect_equal(res$backbone, "lcvp")

  syn <- taxify("Quercus pedunculata", backbone = "lcvp", verbose = FALSE)
  expect_equal(syn$accepted_name, "Quercus robur")
  expect_true(syn$is_synonym)
})

test_that("wcvp matches an accepted plant name and resolves a synonym", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Fagus sylvatica", backbone = "wcvp", verbose = FALSE)
  expect_equal(res$accepted_name, "Fagus sylvatica")
  expect_equal(res$match_type, "exact")
  expect_equal(res$backbone, "wcvp")

  syn <- taxify("Quercus pedunculata", backbone = "wcvp", verbose = FALSE)
  expect_equal(syn$accepted_name, "Quercus robur")
  expect_true(syn$is_synonym)
})

test_that("lcvp and wcvp are reported among installed backbones", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  inst <- installed_backbones()
  expect_true("lcvp" %in% inst)
  expect_true("wcvp" %in% inst)
})

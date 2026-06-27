# Tests for the Reptile Database backbone (reptiledb) and the ReptTraits
# enrichment (add_repttraits), run offline against the bundled example database.

test_that("reptiledb backend matches accepted reptile names", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Python regius", backend = "reptiledb", verbose = FALSE)

  expect_equal(res$accepted_name, "Python regius")
  expect_equal(res$match_type, "exact")
  expect_equal(res$family, "Pythonidae")
  expect_equal(res$backend, "reptiledb")
})

test_that("reptiledb resolves a synonym to its accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Amphibolurus vitticeps", backend = "reptiledb", verbose = FALSE)

  expect_equal(res$accepted_name, "Pogona vitticeps")
  expect_true(res$is_synonym)
  expect_equal(res$genus, "Pogona")
})

test_that("reptiledb fuzzy-matches a misspelt reptile name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Python regus", backend = "reptiledb", verbose = FALSE)

  expect_equal(res$accepted_name, "Python regius")
  expect_equal(res$match_type, "fuzzy")
})

test_that("reptiledb is reported among installed backbones", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  expect_true("reptiledb" %in% installed_backbones())
})

test_that("add_repttraits joins the distribution and trait columns", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Pogona vitticeps", backend = "reptiledb", verbose = FALSE) |>
    add_repttraits(verbose = FALSE)

  rt_cols <- c(
    "biogeographic_realm", "microhabitat", "habitat_type",
    "elevation_min_m", "elevation_max_m", "mean_annual_temp_c",
    "insular_endemic", "body_mass_g", "svl_mm", "total_length_mm",
    "longevity_yr", "diet", "reproductive_mode", "clutch_size",
    "active_time", "foraging_mode"
  )
  expect_true(all(rt_cols %in% names(enriched)))
  expect_false(is.na(enriched$biogeographic_realm))
  expect_type(enriched$elevation_max_m, "double")
})

test_that("add_repttraits returns NA for reptiles absent from ReptTraits", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Naja naja", backend = "reptiledb", verbose = FALSE) |>
    add_repttraits(verbose = FALSE)

  expect_true("biogeographic_realm" %in% names(enriched))
  expect_true(is.na(enriched$biogeographic_realm))
})

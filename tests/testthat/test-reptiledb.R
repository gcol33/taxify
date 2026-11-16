# Tests for the Reptile Database backbone (reptiledb) and the ReptTraits
# enrichment (add_repttraits), run offline against the bundled example database.

test_that("reptiledb backbone matches accepted reptile names", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Python regius", backbone = "reptiledb", verbose = FALSE)

  expect_equal(res$accepted_name, "Python regius")
  expect_equal(res$match_type, "exact")
  expect_equal(res$family, "Pythonidae")
  expect_equal(res$backbone, "reptiledb")
})

test_that("reptiledb resolves a synonym to its accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Amphibolurus vitticeps", backbone = "reptiledb", verbose = FALSE)

  expect_equal(res$accepted_name, "Pogona vitticeps")
  expect_true(res$is_synonym)
  expect_equal(res$genus, "Pogona")
})

test_that("reptiledb fuzzy-matches a misspelt reptile name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Python regus", backbone = "reptiledb", verbose = FALSE)

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

  enriched <- taxify("Pogona vitticeps", backbone = "reptiledb", verbose = FALSE) |>
    add_repttraits(verbose = FALSE)

  rt_cols <- c(
    "repttraits_biogeographic_realm", "repttraits_microhabitat", "repttraits_habitat_type",
    "repttraits_elevation_min_m", "repttraits_elevation_max_m", "repttraits_mean_annual_temp_c",
    "repttraits_insular_endemic", "repttraits_body_mass_g", "repttraits_svl_mm", "repttraits_total_length_mm",
    "repttraits_longevity_yr", "repttraits_diet", "repttraits_reproductive_mode", "repttraits_clutch_size",
    "repttraits_active_time", "repttraits_foraging_mode"
  )
  expect_true(all(rt_cols %in% names(enriched)))
  expect_false(is.na(enriched$repttraits_biogeographic_realm))
  expect_type(enriched$repttraits_elevation_max_m, "double")
})

test_that("add_repttraits returns NA for reptiles absent from ReptTraits", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Naja naja", backbone = "reptiledb", verbose = FALSE) |>
    add_repttraits(verbose = FALSE)

  expect_true("repttraits_biogeographic_realm" %in% names(enriched))
  expect_true(is.na(enriched$repttraits_biogeographic_realm))
})

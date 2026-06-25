# Tests for add_groot() (root traits) and add_sealifebase() (aquatic traits),
# run offline against the bundled example database.

test_that("add_groot joins the nine root-trait columns by accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Abies alba", verbose = FALSE) |>
    add_groot(verbose = FALSE)

  root_cols <- c(
    "root_diameter", "specific_root_length", "root_tissue_density",
    "root_n_concentration", "root_c_concentration", "root_mass_fraction",
    "lateral_spread", "root_mycorrhizal_colonization", "rooting_depth"
  )
  expect_true(all(root_cols %in% names(enriched)))
  expect_false(is.na(enriched$root_diameter))
  expect_type(enriched$root_diameter, "double")
})

test_that("add_groot returns NA for species absent from GRooT", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Bellis perennis", verbose = FALSE) |>
    add_groot(verbose = FALSE)

  expect_true("rooting_depth" %in% names(enriched))
  expect_true(is.na(enriched$rooting_depth))
})

test_that("add_sealifebase joins aquatic traits by accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Octopus vulgaris", backend = "gbif", verbose = FALSE) |>
    add_sealifebase(verbose = FALSE)

  sb_cols <- c(
    "sb_body_length_cm", "sb_body_mass_g", "sb_trophic_level",
    "sb_depth_min_m", "sb_depth_max_m", "sb_vulnerability",
    "sb_habitat", "sb_importance"
  )
  expect_true(all(sb_cols %in% names(enriched)))
  expect_false(is.na(enriched$sb_habitat))
})

test_that("add_sealifebase returns NA for species absent from SeaLifeBase", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Gadus morhua", backend = "gbif", verbose = FALSE) |>
    add_sealifebase(verbose = FALSE)

  expect_true("sb_habitat" %in% names(enriched))
  expect_true(is.na(enriched$sb_habitat))
})

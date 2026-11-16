# Tests for add_groot() (root traits) and add_sealifebase() (aquatic traits),
# run offline against the bundled example database.

test_that("add_groot joins the nine root-trait columns by accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Abies alba", verbose = FALSE) |>
    add_groot(verbose = FALSE)

  root_cols <- c(
    "groot_root_diameter", "groot_specific_root_length", "groot_root_tissue_density",
    "groot_root_n_concentration", "groot_root_c_concentration", "groot_root_mass_fraction",
    "groot_lateral_spread", "groot_root_mycorrhizal_colonization", "groot_rooting_depth"
  )
  expect_true(all(root_cols %in% names(enriched)))
  expect_false(is.na(enriched$groot_root_diameter))
  expect_type(enriched$groot_root_diameter, "double")
})

test_that("add_groot returns NA for species absent from GRooT", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Bellis perennis", verbose = FALSE) |>
    add_groot(verbose = FALSE)

  expect_true("groot_rooting_depth" %in% names(enriched))
  expect_true(is.na(enriched$groot_rooting_depth))
})

test_that("add_sealifebase joins aquatic traits by accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Octopus vulgaris", backbone = "gbif", verbose = FALSE) |>
    add_sealifebase(verbose = FALSE)

  sb_cols <- c(
    "sealifebase_sb_body_length_cm", "sealifebase_sb_body_mass_g", "sealifebase_sb_trophic_level",
    "sealifebase_sb_depth_min_m", "sealifebase_sb_depth_max_m", "sealifebase_sb_vulnerability",
    "sealifebase_sb_habitat", "sealifebase_sb_importance"
  )
  expect_true(all(sb_cols %in% names(enriched)))
  expect_false(is.na(enriched$sealifebase_sb_habitat))
})

test_that("add_sealifebase returns NA for species absent from SeaLifeBase", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  enriched <- taxify("Gadus morhua", backbone = "gbif", verbose = FALSE) |>
    add_sealifebase(verbose = FALSE)

  expect_true("sealifebase_sb_habitat" %in% names(enriched))
  expect_true(is.na(enriched$sealifebase_sb_habitat))
})

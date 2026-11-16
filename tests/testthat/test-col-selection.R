col_map <- c(beak_length = "beak_length",
             avonet_body_mass_g = "body_mass_g",
             migration = "migration")

test_that("cols selects by output name", {
  out <- taxify:::.apply_col_selection(col_map, "avonet_body_mass_g", NULL,
                                       NULL, "avonet")
  expect_identical(out, col_map["avonet_body_mass_g"])
})

test_that("cols selects a renamed curated column by its source name", {
  out <- taxify:::.apply_col_selection(col_map, c("body_mass_g", "migration"),
                                       NULL, NULL, "avonet")
  expect_identical(out, col_map[c("avonet_body_mass_g", "migration")])
})

test_that("cols tolerates a missing prefix", {
  gm <- c(gift_plant_height_max = "plant_height_max")
  out <- taxify:::.apply_col_selection(gm, "plant_height_max", NULL, "gift_",
                                       "gift")
  expect_identical(out, gm)
})

test_that("cols errors on an unknown name", {
  expect_error(
    taxify:::.apply_col_selection(col_map, "wingspan", NULL, NULL, "avonet"),
    "unknown column"
  )
})

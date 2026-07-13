# COMBINE ships two parallel tables over the same ~6.2k mammal species: the
# reported (measured/compiled) values and a phylogenetically imputed table with
# the gaps filled by a model. add_combine_reported() joins the first,
# add_combine_imputed() the second under namespaced combine_imputed_* columns,
# and add_combine() is a thin wrapper on the reported door. These run against
# mock enrichments so they need no network or bundled fixture.

# One row per COMBINE column, in the source's own column names. The imputed
# table fills cells the reported table leaves NA (it never adds species).
combine_fixture <- function(imputed = FALSE) {
  data.frame(
    canonical_name        = c("Vulpes vulpes", "Panthera leo"),
    adult_mass_g          = c(4820, if (imputed) 190000 else NA),
    adult_body_length_mm  = c(700,  if (imputed) 1980   else NA),
    litter_size_n         = c(4.7,  if (imputed) 2.5    else NA),
    litters_per_year_n    = c(1,    if (imputed) 1      else NA),
    max_longevity_d       = c(if (imputed) 5000 else NA, if (imputed) 10000 else NA),
    gestation_length_d    = c(52, 110),
    weaning_age_d         = c(if (imputed) 60 else NA, if (imputed) 210 else NA),
    generation_length_d   = c(if (imputed) 730 else NA, if (imputed) 2500 else NA),
    dispersal_km          = c(if (imputed) 10 else NA, if (imputed) 30 else NA),
    habitat_breadth_n     = c(5, 4),
    diet_breadth_n        = c(3, 1),
    trophic_level         = c(3, 3),
    activity_cycle        = c(1, 3),
    foraging_stratum      = c("G", "G"),
    biogeographical_realm = c("Palearctic", "Afrotropic"),
    stringsAsFactors      = FALSE
  )
}

mk_res <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)


test_that("add_combine_reported() joins reported values under combine_* columns", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))

  r <- add_combine_reported(mk_res(c("Vulpes vulpes", "Panthera leo")),
                            verbose = FALSE)
  expect_true(all(c("combine_adult_mass_g", "combine_gestation_length_d",
                    "combine_biogeographical_realm") %in% names(r)))
  expect_equal(r$combine_adult_mass_g[r$accepted_name == "Vulpes vulpes"], 4820)
  expect_equal(r$combine_gestation_length_d[r$accepted_name == "Panthera leo"], 110)
  expect_equal(r$combine_biogeographical_realm[r$accepted_name == "Vulpes vulpes"],
               "Palearctic")
  # a reported gap stays NA (Panthera leo has no measured adult mass here)
  expect_true(is.na(r$combine_adult_mass_g[r$accepted_name == "Panthera leo"]))
})

test_that("add_combine_imputed() attaches combine_imputed_* columns", {
  install_mock_enrichment("combine_imputed", combine_fixture(imputed = TRUE))

  r <- add_combine_imputed(mk_res(c("Vulpes vulpes", "Panthera leo")),
                           verbose = FALSE)
  expect_true(all(c("combine_imputed_adult_mass_g",
                    "combine_imputed_generation_length_d") %in% names(r)))
  # imputed columns never carry the bare combine_ names
  expect_false(any(grepl("^combine_[^i]", names(r))))
  expect_equal(r$combine_imputed_adult_mass_g[r$accepted_name == "Panthera leo"],
               190000)
})

test_that("imputed table has higher coverage than the reported table", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))
  install_mock_enrichment("combine_imputed", combine_fixture(imputed = TRUE))

  r <- mk_res(c("Vulpes vulpes", "Panthera leo")) |>
    add_combine_reported(verbose = FALSE) |>
    add_combine_imputed(verbose = FALSE)

  # generation length is absent from the reported table, filled in the imputed one
  expect_true(all(is.na(r$combine_generation_length_d)))
  expect_equal(r$combine_imputed_generation_length_d[r$accepted_name == "Vulpes vulpes"],
               730)
  expect_equal(r$combine_imputed_generation_length_d[r$accepted_name == "Panthera leo"],
               2500)
  # reported adult mass is measured for the fox, missing for the lion; imputed
  # fills the lion
  expect_true(is.na(r$combine_adult_mass_g[r$accepted_name == "Panthera leo"]))
  expect_equal(r$combine_imputed_adult_mass_g[r$accepted_name == "Panthera leo"],
               190000)
})

test_that("reported and imputed columns coexist without collision", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))
  install_mock_enrichment("combine_imputed", combine_fixture(imputed = TRUE))

  r <- mk_res("Vulpes vulpes") |>
    add_combine_reported(verbose = FALSE) |>
    add_combine_imputed(verbose = FALSE)

  expect_true("combine_gestation_length_d" %in% names(r))
  expect_true("combine_imputed_gestation_length_d" %in% names(r))
  # no name was silently dropped or clobbered: the two families are disjoint
  rep_cols <- grep("^combine_(?!imputed_)", names(r), value = TRUE, perl = TRUE)
  imp_cols <- grep("^combine_imputed_", names(r), value = TRUE)
  expect_equal(length(rep_cols), 15L)
  expect_equal(length(imp_cols), 15L)
  expect_length(intersect(rep_cols, imp_cols), 0L)
})

test_that("a non-mammal (absent from COMBINE) gets all-NA columns", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))

  r <- add_combine_reported(mk_res("Abies alba"), verbose = FALSE)
  combine_cols <- grep("^combine_", names(r), value = TRUE)
  expect_true(length(combine_cols) >= 15L)
  expect_true(all(vapply(combine_cols, function(cc) is.na(r[[cc]][1L]), logical(1))))
})

test_that("add_combine() is a thin wrapper on add_combine_reported()", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))

  x <- mk_res(c("Vulpes vulpes", "Panthera leo"))
  a <- add_combine(x, verbose = FALSE)
  b <- add_combine_reported(x, verbose = FALSE)
  expect_identical(names(a), names(b))
  expect_equal(a$combine_adult_mass_g, b$combine_adult_mass_g)
  expect_equal(a$combine_biogeographical_realm, b$combine_biogeographical_realm)
})

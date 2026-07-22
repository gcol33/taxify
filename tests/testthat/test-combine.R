# COMBINE ships two parallel tables over the same ~6.2k mammal species: the
# reported (measured/compiled) values and a phylogenetically imputed table with
# the gaps filled by a model. add_combine_reported() joins the first,
# add_combine_imputed() the second under namespaced combine_imputed_* columns,
# and add_combine() coalesces the two -- reported values win, imputed fills the
# gaps -- tagging each cell's origin in a companion combine_*_src column. These
# run against mock enrichments so they need no network or bundled fixture.

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

test_that("add_combine() coalesces reported over imputed and tags provenance", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))
  install_mock_enrichment("combine_imputed", combine_fixture(imputed = TRUE))

  r <- add_combine(mk_res(c("Vulpes vulpes", "Panthera leo")), verbose = FALSE)
  fox  <- r$accepted_name == "Vulpes vulpes"
  lion <- r$accepted_name == "Panthera leo"

  # a measurement is kept and tagged "reported"
  expect_equal(r$combine_adult_mass_g[fox], 4820)
  expect_equal(r$combine_adult_mass_g_src[fox], "reported")

  # a reported gap is filled from the imputed table and tagged "imputed"
  expect_equal(r$combine_adult_mass_g[lion], 190000)
  expect_equal(r$combine_adult_mass_g_src[lion], "imputed")

  # a trait absent from the reported table is fully imputed for both species
  expect_equal(r$combine_generation_length_d[fox], 730)
  expect_equal(r$combine_generation_length_d[lion], 2500)
  expect_equal(r$combine_generation_length_d_src, c("imputed", "imputed"))

  # a non-imputed trait is always "reported" where present
  expect_equal(r$combine_biogeographical_realm[fox], "Palearctic")
  expect_equal(r$combine_biogeographical_realm_src[fox], "reported")

  # no bare combine_imputed_* columns leak into the output
  expect_false(any(grepl("^combine_imputed_", names(r))))

  # every value column is immediately followed by its provenance tag
  nms   <- names(r)
  vcols <- grep("^combine_.*(?<!_src)$", nms, value = TRUE, perl = TRUE)
  for (vcol in vcols) {
    pos <- match(vcol, nms)
    expect_equal(nms[pos + 1L], paste0(vcol, "_src"))
  }
})

test_that("add_combine() after add_combine_imputed() never mislabels imputed columns", {
  install_mock_enrichment("combine", combine_fixture(imputed = FALSE))
  install_mock_enrichment("combine_imputed", combine_fixture(imputed = TRUE))

  # The pipeline attaches the imputed table first, then the coalescing door. The
  # already-present combine_imputed_* columns must not be swept into the
  # reported-value coalesce (a prefix grep would have re-tagged them "reported").
  r <- mk_res(c("Vulpes vulpes", "Panthera leo")) |>
    add_combine_imputed(verbose = FALSE) |>
    add_combine(verbose = FALSE)

  fox  <- r$accepted_name == "Vulpes vulpes"
  lion <- r$accepted_name == "Panthera leo"

  # Pre-existing combine_imputed_* columns pass through untouched: not coalesced
  # as reported values, and given no _src provenance tag.
  expect_true("combine_imputed_adult_mass_g" %in% names(r))
  expect_false("combine_imputed_adult_mass_g_src" %in% names(r))
  expect_length(grep("^combine_imputed_.*_src$", names(r)), 0L)

  # The coalesced reported column still tags provenance correctly.
  expect_equal(r$combine_adult_mass_g_src[fox], "reported")
  expect_equal(r$combine_adult_mass_g_src[lion], "imputed")
})


# ---- [.taxify_result subsetting preserves metadata ----

test_that("[.taxify_result carries taxify_meta and class through subsetting", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  wfo_vtr <- file.path(taxify_example_data(), "wfo", "latest", "wfo.vtr")
  skip_if_not(file.exists(wfo_vtr), "wfo example backbone missing")

  res <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
  expect_s3_class(res, "taxify_result")
  expect_false(is.null(attr(res, "taxify_meta")))

  # A no-op column subset (as add_combine() takes internally) keeps both.
  sub <- res[, names(res)]
  expect_s3_class(sub, "taxify_result")
  expect_false(is.null(attr(sub, "taxify_meta")))

  # A partial column subset likewise carries the attribute.
  sub2 <- res[, c("input_name", "accepted_name"), drop = FALSE]
  expect_s3_class(sub2, "taxify_result")
  expect_false(is.null(attr(sub2, "taxify_meta")))

  # Collapsing to a single column with drop = TRUE returns the bare vector.
  expect_type(res[, "accepted_name"], "character")
})

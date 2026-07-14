# Five source doors shipped from previously-unreleased taxifydb parsers
# (kew_cvalues, copepod_traits, fishtraits, epa_freshwater, cefas_btrait).
# Each joins a pre-built .vtr; these run against mock enrichments, so no network
# or bundled fixture is needed.

mk_res <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

test_that("add_kew_cvalues() attaches prefixed genome-size columns", {
  install_mock_enrichment("kew_cvalues", data.frame(
    canonical_name = "Zea mays", genome_size_1c_pg = 2.7,
    chromosome_2n = 20, ploidy_x = 2, stringsAsFactors = FALSE))
  r <- add_kew_cvalues(mk_res(c("Zea mays", "Abies alba")), verbose = FALSE)
  expect_true(all(c("cval_genome_size_1c_pg", "cval_chromosome_2n",
                    "cval_ploidy_x") %in% names(r)))
  expect_equal(r$cval_genome_size_1c_pg[r$accepted_name == "Zea mays"], 2.7)
  expect_true(is.na(r$cval_genome_size_1c_pg[r$accepted_name == "Abies alba"]))
})

test_that("add_copepod_traits() attaches prefixed body/egg traits", {
  install_mock_enrichment("copepod_traits", data.frame(
    canonical_name = "Calanus finmarchicus", body_length_mm = 3.5,
    egg_diameter_um = 150, clutch_size = 40, feeding_mode = "active",
    spawning_strategy = "broadcaster", stringsAsFactors = FALSE))
  r <- add_copepod_traits(mk_res("Calanus finmarchicus"), verbose = FALSE)
  expect_true(all(c("cop_body_length_mm", "cop_feeding_mode",
                    "cop_spawning_strategy") %in% names(r)))
  expect_equal(r$cop_body_length_mm[1L], 3.5)
  expect_equal(r$cop_feeding_mode[1L], "active")
})

test_that("add_fishtraits() attaches prefixed life-history columns", {
  install_mock_enrichment("fishtraits", data.frame(
    canonical_name = "Micropterus salmoides", common_name = "Largemouth Bass",
    native = "TRUE", max_length_cm = 97, longevity_yr = 23,
    maturity_age_yr = 3, fecundity_max = 1e5, repro_guild = "guarder",
    min_temp_c = 10, max_temp_c = 32, extinct = "FALSE",
    stringsAsFactors = FALSE))
  r <- add_fishtraits(mk_res("Micropterus salmoides"), verbose = FALSE)
  expect_true(all(c("ft_common_name", "ft_max_length_cm",
                    "ft_longevity_yr") %in% names(r)))
  expect_equal(r$ft_max_length_cm[1L], 97)
  expect_equal(r$ft_common_name[1L], "Largemouth Bass")
})

test_that("add_epa_freshwater() attaches prefixed functional traits", {
  install_mock_enrichment("epa_freshwater", data.frame(
    canonical_name = "Baetis", feeding_mode = "collector-gatherer",
    habit = "swimmer", voltinism = "multivoltine",
    thermal_preference = "cool-warm", body_size_class = "small",
    stringsAsFactors = FALSE))
  r <- add_epa_freshwater(mk_res("Baetis"), verbose = FALSE)
  expect_true(all(c("epa_feeding_mode", "epa_habit",
                    "epa_voltinism") %in% names(r)))
  expect_equal(r$epa_habit[1L], "swimmer")
})

test_that("add_cefas_btrait() attaches prefixed benthic traits", {
  install_mock_enrichment("cefas_btrait", data.frame(
    canonical_name = "Abra alba", body_size = "small", morphology = "soft",
    lifespan = "1-3 years", living_habit = "burrower", feeding_mode = "deposit",
    mobility = "low", bioturbation = "biodiffuser", stringsAsFactors = FALSE))
  r <- add_cefas_btrait(mk_res("Abra alba"), verbose = FALSE)
  expect_true(all(c("cefas_body_size", "cefas_feeding_mode",
                    "cefas_bioturbation") %in% names(r)))
  expect_equal(r$cefas_feeding_mode[1L], "deposit")
})

test_that("the five new enrichments are registered in the bundled manifest", {
  mpath <- system.file("manifest.json", package = "taxify")
  skip_if_not(nzchar(mpath) && file.exists(mpath), "bundled manifest not found")
  m <- jsonlite::read_json(mpath, simplifyVector = FALSE)
  for (nm in c("kew_cvalues", "copepod_traits", "fishtraits",
               "epa_freshwater", "cefas_btrait")) {
    expect_true(nm %in% names(m$enrichments), info = nm)
    expect_true(isTRUE(m$enrichments[[nm]]$static), info = nm)
    expect_true(length(m$enrichments[[nm]]$trait_cols) > 0L, info = nm)
  }
})

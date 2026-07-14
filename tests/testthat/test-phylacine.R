# PHYLACINE mammal traits, and the body-mass provenance safeguard. PHYLACINE's
# Mass.g is partly phylogenetically imputed (extinct and data-poor species); the
# build keeps the Mass.Method flag as mass_method + a coarse mass_method_class
# (reported / estimated / imputed). The add_phylacine() door surfaces both, and
# the body_mass trait carries a per-record caution so a modelled mass is never
# served as a measurement where PHYLACINE is the sole source. Mock enrichments,
# so no network or bundled fixture is needed.

phylacine_fixture <- function() data.frame(
  canonical_name        = c("Mammuthus primigenius", "Vulpes vulpes"),
  mass_g                = c(6000000, 4820),
  mass_method           = c("Imputed", "Reported"),
  mass_method_class     = c("imputed", "reported"),
  diet_plant_pct        = c(100, 10),
  diet_vertebrate_pct   = c(0, 70),
  diet_invertebrate_pct = c(0, 20),
  terrestrial           = c(1, 1),
  marine                = c(0, 0),
  freshwater            = c(0, 0),
  aerial                = c(0, 0),
  island_endemicity     = c("0", "0"),
  iucn_status           = c("EP", "LC"),
  stringsAsFactors      = FALSE
)

mk_res <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)


test_that("add_phylacine() surfaces the body-mass provenance columns", {
  install_mock_enrichment("phylacine", phylacine_fixture())

  r <- add_phylacine(mk_res(c("Mammuthus primigenius", "Vulpes vulpes")),
                     verbose = FALSE)
  expect_true(all(c("phylacine_mass_g", "phylacine_mass_method",
                    "phylacine_mass_method_class") %in% names(r)))
  expect_equal(r$phylacine_mass_method_class[r$accepted_name == "Mammuthus primigenius"],
               "imputed")
  expect_equal(r$phylacine_mass_method_class[r$accepted_name == "Vulpes vulpes"],
               "reported")
})

test_that(".phylacine_mass_caution flags modelled masses only", {
  cau <- taxify:::.phylacine_mass_caution(
    c("imputed", "estimated", "reported", NA))
  expect_match(cau[1], "phylogenetically imputed")
  expect_match(cau[2], "allometric")
  expect_true(is.na(cau[3]))   # a reported (measured) mass gets no caution
  expect_true(is.na(cau[4]))
})

test_that("body_mass registers PHYLACINE with a per-record caution", {
  reg <- taxify:::.trait_registry()
  ph  <- reg$body_mass$sources$phylacine
  expect_equal(ph$enrichment, "phylacine")
  expect_equal(ph$col, "mass_g")
  expect_equal(ph$caution_col, "mass_method_class")
  expect_true(is.function(ph$caution_fn))
})

test_that("add_trait('body_mass') cautions an imputed PHYLACINE mass per row", {
  install_mock_enrichment("phylacine", phylacine_fixture())

  x <- mk_res(c("Mammuthus primigenius", "Vulpes vulpes"))
  r <- add_trait(x, "body_mass", sources = "phylacine", verbose = FALSE)

  # The value itself is served for both species...
  expect_equal(r$body_mass[r$accepted_name == "Mammuthus primigenius"], 6000000)
  expect_equal(r$body_mass[r$accepted_name == "Vulpes vulpes"], 4820)
  # ...but only the imputed (extinct) species carries a caution.
  expect_true("body_mass_caution" %in% names(r))
  expect_match(r$body_mass_caution[r$accepted_name == "Mammuthus primigenius"],
               "imputed")
  expect_true(is.na(r$body_mass_caution[r$accepted_name == "Vulpes vulpes"]))
})

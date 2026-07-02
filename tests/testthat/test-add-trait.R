# add_trait() attaches a single trait across every source that carries it,
# harmonizing vocabularies (categorical) and units (numeric). These run against
# the bundled example database, where Abies alba carries woodiness (Zanne +
# GIFT), seed mass (Diaz + GIFT), plant height (Diaz + GIFT), and SLA
# (LEDA + GIFT).

mk <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

trait_ready <- function() {
  p <- file.path(taxify_example_data(), "enrichment", "woodiness", "latest",
                 "woodiness.vtr")
  file.exists(p)
}

test_that("add_trait() errors on input without accepted_name", {
  expect_error(add_trait(data.frame(x = 1), "woodiness"), "accepted_name")
})

test_that("list_traits() advertises the registered traits", {
  lt <- list_traits()
  expect_true(all(c("trait", "kind", "unit", "n_sources", "sources") %in% names(lt)))
  expect_true(all(c("woodiness", "plant_height", "seed_mass", "sla") %in% lt$trait))
  expect_equal(lt$kind[lt$trait == "woodiness"], "categorical")
  expect_equal(lt$kind[lt$trait == "seed_mass"], "numeric")
  expect_equal(lt$unit[lt$trait == "seed_mass"], "mg")
})

test_that("trait_info() returns one row per source with harmonization notes", {
  ti <- suppressMessages(trait_info("seed_mass"))
  expect_true(all(c("source", "enrichment", "column", "note") %in% names(ti)))
  expect_setequal(ti$source, c("diaz", "gift", "austraits", "bien", "brot", "ecoflora"))
  expect_true(any(grepl("x1000", ti$note)))          # GIFT g -> mg conversion noted
  expect_error(suppressMessages(trait_info("nope")), "unknown trait")
})

test_that("wide mode attaches one harmonized column per source (categorical)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "woodiness", verbose = FALSE)
  expect_true(all(c("woodiness_zanne", "woodiness_gift") %in% names(r)))
  # Zanne 'woody' and GIFT 'woody' both map to canonical 'woody'.
  expect_equal(r$woodiness_zanne, "woody")
  expect_equal(r$woodiness_gift, "woody")
})

test_that("numeric sources are converted to the canonical unit", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  # Seed mass: Diaz already mg; GIFT grams x1000 -> mg.
  sm <- add_trait(mk("Abies alba"), "seed_mass", verbose = FALSE)
  expect_type(sm$seed_mass_diaz, "double")
  expect_type(sm$seed_mass_gift, "double")
  expect_equal(sm$seed_mass_diaz, 62.007, tolerance = 1e-3)
  expect_equal(sm$seed_mass_gift, 73.9425, tolerance = 1e-3)   # 0.0739425 * 1000

  # SLA: LEDA mm2/mg; GIFT cm2/g x0.1 -> mm2/mg. Same species -> equal here.
  sl <- add_trait(mk("Abies alba"), "sla", verbose = FALSE)
  expect_equal(sl$sla_leda, 5.87, tolerance = 1e-3)
  expect_equal(sl$sla_gift, 5.87, tolerance = 1e-3)            # 58.7 * 0.1
})

test_that("coalesce defaults to median for numeric traits", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  # Default numeric combine is median across all sources that carry the row.
  w <- add_trait(mk("Abies alba"), "seed_mass", mode = "wide", verbose = FALSE)
  wide_vals <- unlist(w[1, grepl("^seed_mass_", names(w))], use.names = FALSE)
  wide_vals <- wide_vals[!is.na(wide_vals)]

  d <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce", verbose = FALSE)
  expect_true(all(c("seed_mass", "seed_mass_source", "seed_mass_n") %in% names(d)))
  expect_gte(d$seed_mass_n, 2L)
  expect_equal(d$seed_mass_n, length(wide_vals))
  expect_equal(d$seed_mass, stats::median(wide_vals), tolerance = 1e-6)
  expect_match(d$seed_mass_source, "diaz")
  expect_match(d$seed_mass_source, "gift")
})

test_that("combine = 'first' honours priority order", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  d <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                 combine = "first", verbose = FALSE)
  expect_equal(d$seed_mass_source, "diaz")        # default priority diaz > gift
  expect_equal(d$seed_mass, 62.007, tolerance = 1e-3)

  g <- add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                 combine = "first", priority = "gift", verbose = FALSE)
  expect_equal(g$seed_mass_source, "gift")
  expect_equal(g$seed_mass, 73.9425, tolerance = 1e-3)
})

test_that("combine rejects reducers that do not fit the trait kind", {
  expect_error(add_trait(mk("Abies alba"), "seed_mass", mode = "coalesce",
                         combine = "vote"), "not valid for a numeric")
  expect_error(add_trait(mk("Abies alba"), "woodiness", mode = "coalesce",
                         combine = "median"), "not valid for a categorical")
})

test_that("sources= restricts which sources are joined", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Abies alba"), "woodiness", sources = "gift", verbose = FALSE)
  expect_true("woodiness_gift" %in% names(r))
  expect_false("woodiness_zanne" %in% names(r))
})

test_that("unknown trait and unknown source error informatively", {
  expect_error(add_trait(mk("Abies alba"), "woodyness"),
               "unknown trait|Did you mean")
  expect_error(add_trait(mk("Abies alba"), "woodiness", sources = "bogus"),
               "unknown source")
})

test_that("absent species get NA across sources", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_trait(mk("Zzznotaspecies fakename"), "seed_mass", verbose = FALSE)
  expect_true(is.na(r$seed_mass_diaz))
  expect_true(is.na(r$seed_mass_gift))
})

test_that("add_zanne() is the source-named woodiness door", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(trait_ready(), "example enrichments not available")

  r <- add_zanne(mk("Quercus robur"), verbose = FALSE)
  expect_true("woodiness" %in% names(r))
  expect_equal(r$woodiness, "woody")
})

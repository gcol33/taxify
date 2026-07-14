# GIDIAS invasion-impact aggregates (EICAT / SEICAT). The runtime door joins
# per-species impact indicators from a pre-built .vtr; the record-to-species
# aggregation happens at build time in taxifydb. These run against a mock
# enrichment, so no network or bundled fixture is needed.

gidias_fixture <- function() data.frame(
  canonical_name           = c("Felis catus", "Robinia pseudoacacia"),
  gidias_eicat_category    = c("MV", "MO"),
  gidias_eicat_magnitude   = c(3L, 2L),
  gidias_eicat_mechanism   = c("(2) Predation", "(1) Competition"),
  gidias_seicat_category   = c("DD", "MN"),
  gidias_seicat_magnitude  = c(NA_integer_, 1L),
  gidias_seicat_affected   = c(NA_character_, "Material and immaterial assets;"),
  gidias_ias_taxon         = c("Vertebrate", "Plant"),
  gidias_kingdom           = c("Animalia", "Plantae"),
  gidias_realms            = c("Terrestrial", "Terrestrial"),
  gidias_n_records         = c(167L, 274L),
  gidias_n_negative        = c(120L, 200L),
  gidias_n_sources         = c(44L, 32L),
  gidias_global_extinction = c(TRUE, FALSE),
  stringsAsFactors = FALSE
)

mk_res <- function(sp) data.frame(
  query = sp, accepted_name = sp, matched_name = sp, stringsAsFactors = FALSE
)

test_that("add_gidias() attaches the curated EICAT/SEICAT columns", {
  install_mock_enrichment("gidias", gidias_fixture())

  r <- add_gidias(mk_res(c("Felis catus", "Robinia pseudoacacia")),
                  verbose = FALSE)
  expect_true(all(c("gidias_eicat_category", "gidias_eicat_mechanism",
                    "gidias_seicat_category", "gidias_ias_taxon",
                    "gidias_realms", "gidias_n_records",
                    "gidias_n_sources") %in% names(r)))
  # The extended set is not attached by default.
  expect_false("gidias_global_extinction" %in% names(r))
  expect_equal(r$gidias_eicat_category[r$accepted_name == "Felis catus"], "MV")
  expect_equal(r$gidias_seicat_category[r$accepted_name == "Robinia pseudoacacia"],
               "MN")
  expect_equal(r$gidias_n_sources[r$accepted_name == "Felis catus"], 44L)
})

test_that("add_gidias(cols = 'all') attaches the extended columns", {
  install_mock_enrichment("gidias", gidias_fixture())

  r <- add_gidias(mk_res("Felis catus"), cols = "all", verbose = FALSE)
  expect_true(all(c("gidias_eicat_magnitude", "gidias_seicat_affected",
                    "gidias_kingdom", "gidias_n_negative",
                    "gidias_global_extinction") %in% names(r)))
  # enrich_simple exposes booleans through its character/numeric na-type path,
  # so a logical .vtr column is delivered as "TRUE"/"FALSE" (engine behaviour).
  expect_equal(as.character(r$gidias_global_extinction[1L]), "TRUE")
  expect_equal(r$gidias_eicat_magnitude[1L], 3)
})

test_that("add_gidias() leaves a species absent from GIDIAS all-NA", {
  install_mock_enrichment("gidias", gidias_fixture())

  r <- add_gidias(mk_res("Quercus robur"), verbose = FALSE)
  gcols <- grep("^gidias_", names(r), value = TRUE)
  expect_length(gcols, 7L)
  expect_true(all(vapply(gcols, function(cc) is.na(r[[cc]][1L]), logical(1))))
})

test_that("EICAT and SEICAT resolve through add_trait()", {
  install_mock_enrichment("gidias", gidias_fixture())

  r <- suppressMessages(add_trait(
    mk_res(c("Felis catus", "Robinia pseudoacacia")),
    "environmental_impact", sources = "gidias"))
  expect_true("environmental_impact" %in% names(r))
  expect_equal(r$environmental_impact[r$accepted_name == "Felis catus"], "MV")
  expect_equal(r$environmental_impact[r$accepted_name == "Robinia pseudoacacia"],
               "MO")

  r2 <- suppressMessages(add_trait(
    mk_res("Robinia pseudoacacia"), "socioeconomic_impact", sources = "gidias"))
  expect_equal(r2$socioeconomic_impact[1L], "MN")
})

test_that("environmental_impact / socioeconomic_impact are registered traits", {
  lt <- list_traits()
  expect_true(all(c("environmental_impact", "socioeconomic_impact") %in% lt$trait))
  expect_equal(lt$kind[lt$trait == "environmental_impact"], "categorical")

  ti <- suppressMessages(trait_info("environmental_impact"))
  expect_equal(ti$source, "gidias")
  expect_equal(ti$column, "gidias_eicat_category")
})

test_that("GIDIAS is registered in the bundled manifest as a static enrichment", {
  mpath <- system.file("manifest.json", package = "taxify")
  skip_if_not(nzchar(mpath) && file.exists(mpath), "bundled manifest not found")
  m <- jsonlite::read_json(mpath, simplifyVector = FALSE)
  expect_true("gidias" %in% names(m$enrichments))
  expect_true(isTRUE(m$enrichments$gidias$static))
  expect_length(m$enrichments$gidias$trait_cols, 13L)
})

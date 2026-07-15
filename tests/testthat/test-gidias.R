# GIDIAS invasion-impact aggregates (EICAT / SEICAT). The runtime door joins
# per-species impact indicators from a pre-built .vtr; the record-to-species
# aggregation happens at build time in taxifydb. These run against a mock
# enrichment, so no network or bundled fixture is needed.
#
# taxifydb builds the .vtr at two grains keyed on affected_taxon: "Any" (every
# record for the species) plus one row per affected native taxon. The fixture
# mirrors that, with a cat whose vertebrate impacts are more severe than its
# invertebrate ones, so a door reading the wrong grain shows up as a wrong
# category rather than as a missing column.
gidias_fixture <- function() data.frame(
  canonical_name           = c("Felis catus", "Felis catus", "Felis catus",
                               "Robinia pseudoacacia"),
  affected_taxon           = c("Any", "Invertebrate", "Vertebrate", "Any"),
  gidias_eicat_category    = c("MV", "MO", "MV", "MO"),
  gidias_eicat_magnitude   = c(3L, 2L, 3L, 2L),
  gidias_eicat_mechanism   = c("(2) Predation", "(2) Predation", "(2) Predation",
                               "(1) Competition"),
  # SEICAT is carried by the "Any" grain alone: the affected-native-taxon axis
  # slices environmental impact, not impact on people's activities.
  gidias_seicat_category   = c("DD", NA, NA, "MN"),
  gidias_seicat_magnitude  = c(NA_integer_, NA_integer_, NA_integer_, 1L),
  gidias_seicat_affected   = c(NA_character_, NA_character_, NA_character_,
                               "Material and immaterial assets;"),
  gidias_ias_taxon         = c("Vertebrate", "Vertebrate", "Vertebrate", "Plant"),
  gidias_kingdom           = c("Animalia", "Animalia", "Animalia", "Plantae"),
  gidias_realms            = c("Terrestrial", "Terrestrial", "Terrestrial",
                               "Terrestrial"),
  gidias_n_records         = c(167L, 3L, 160L, 274L),
  gidias_n_negative        = c(120L, 3L, 115L, 200L),
  gidias_n_sources         = c(44L, 2L, 40L, 32L),
  gidias_global_extinction = c(TRUE, FALSE, TRUE, FALSE),
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

test_that("add_gidias(group = ) reads the impact on one affected taxon", {
  install_mock_enrichment("gidias", gidias_fixture())

  # The collapse the grain exists to undo: the cat drove global extinctions
  # among vertebrates, but only reduced invertebrate populations.
  inv <- add_gidias(mk_res("Felis catus"), group = "Invertebrate", verbose = FALSE)
  expect_equal(inv$gidias_eicat_category[1L], "MO")
  expect_equal(inv$gidias_n_records[1L], 3L)

  vert <- add_gidias(mk_res("Felis catus"), group = "Vertebrate", verbose = FALSE)
  expect_equal(vert$gidias_eicat_category[1L], "MV")

  # A single group keeps the column names the default grain uses.
  expect_true("gidias_eicat_category" %in% names(inv))
  # The group column itself is not attached.
  expect_false("affected_taxon" %in% names(inv))
})

test_that("add_gidias() with several groups suffixes each column set", {
  install_mock_enrichment("gidias", gidias_fixture())

  r <- suppressMessages(
    add_gidias(mk_res("Felis catus"), group = c("Invertebrate", "Vertebrate"),
               verbose = FALSE))
  expect_true(all(c("gidias_eicat_category_Invertebrate",
                    "gidias_eicat_category_Vertebrate") %in% names(r)))
  expect_equal(r$gidias_eicat_category_Invertebrate[1L], "MO")
  expect_equal(r$gidias_eicat_category_Vertebrate[1L], "MV")
})

test_that("SEICAT is carried by the aggregate grain only", {
  install_mock_enrichment("gidias", gidias_fixture())

  expect_equal(
    add_gidias(mk_res("Felis catus"), verbose = FALSE)$gidias_seicat_category[1L],
    "DD")
  expect_true(is.na(
    add_gidias(mk_res("Felis catus"), group = "Vertebrate",
               verbose = FALSE)$gidias_seicat_category[1L]))
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

test_that("add_trait() pins the aggregate grain instead of taking the first row", {
  # Put a per-taxon row ahead of the aggregate. Sorted output happens to lead
  # with "Any" today, but the vocabulary is GIDIAS's to extend -- one new term
  # sorting before "Any" would silently turn every EICAT answer into that
  # group's. The grain has to be selected, not inherited from row order.
  fx <- gidias_fixture()
  fx <- fx[order(fx$affected_taxon != "Any"), ]
  fx <- rbind(fx[fx$affected_taxon != "Any", ], fx[fx$affected_taxon == "Any", ])
  expect_equal(fx$affected_taxon[1L], "Invertebrate")   # aggregate is not first
  install_mock_enrichment("gidias", fx)

  r <- suppressMessages(add_trait(mk_res("Felis catus"),
                                  "environmental_impact", sources = "gidias"))
  expect_equal(r$environmental_impact[1L], "MV")        # not the Invertebrate MO

  r2 <- suppressMessages(add_trait(mk_res("Felis catus"),
                                   "socioeconomic_impact", sources = "gidias"))
  expect_equal(r2$socioeconomic_impact[1L], "DD")       # SEICAT lives on "Any"
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

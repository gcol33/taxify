# Infraspecific rank-marker recovery (gcol33/taxifydb#45).
#
# GBIF renders an infraspecific accepted name without its rank connecting term
# ("Erica tenella var. tenella" -> "Erica tenella tenella"), where every other
# backbone and botanical source keeps the marker. A join keyed on the rendered
# name then misses. The runtime fallback retries the still-empty rows under the
# name's alternative marker renderings, matching only when the marker is the
# sole difference, and refusing a guess when the rank-insensitive form names
# more than one distinct taxon.
#
# These inject a mock enrichment into the session cache (offline, no backbone
# opened -- the single seeded wfo yields no cross-backbone alternatives), so
# they pin the marker-recovery wiring itself.

test_that("enrich_simple() recovers a marker-ful key against a marker-less GBIF name", {
  install_mock_enrichment("mockinfra", data.frame(
    canonical_name = "Erica tenella var. tenella",
    regions        = 12L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Erica tenella tenella",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- taxify:::enrich_simple(x, "mockinfra", col_map = c(regions = "regions"),
                              source_label = "mock", verbose = FALSE)
  expect_equal(r$regions, 12L)
})

test_that("enrich_simple() recovers in the reverse direction (marker-less key, marker-ful name)", {
  install_mock_enrichment("mockinfrarev", data.frame(
    canonical_name = "Erica tenella tenella",
    regions        = 7L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Erica tenella var. tenella",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- taxify:::enrich_simple(x, "mockinfrarev", col_map = c(regions = "regions"),
                              source_label = "mock", verbose = FALSE)
  expect_equal(r$regions, 7L)
})

test_that("a zoological trinomial matched directly is not altered, and a missing one stays NA", {
  install_mock_enrichment("mockzoo", data.frame(
    canonical_name = "Panthera leo persica",
    mass           = 190L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = c("Panthera leo persica", "Panthera leo nubica"),
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- taxify:::enrich_simple(x, "mockzoo", col_map = c(mass = "mass"),
                              source_label = "mock", verbose = FALSE)
  # The trinomial the source carries matches directly and keeps its value; the
  # one the source lacks has no marker-ful botanical form to recover and is NA.
  expect_equal(r$mass, c(190L, NA_integer_))
})

test_that("an ambiguous rank-insensitive collision is left unmatched, not guessed", {
  install_mock_enrichment("mockambig", data.frame(
    canonical_name = c("Aus bus var. cus", "Aus bus subsp. cus"),
    regions        = c(1L, 2L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Aus bus cus", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  r <- taxify:::enrich_simple(x, "mockambig", col_map = c(regions = "regions"),
                              source_label = "mock", verbose = FALSE)
  expect_true(is.na(r$regions))
})

test_that("options(taxify.infra_marker_recovery = FALSE) leaves the gap empty", {
  install_mock_enrichment("mockinfraoff", data.frame(
    canonical_name = "Erica tenella var. tenella",
    regions        = 12L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Erica tenella tenella",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  withr::local_options(taxify.infra_marker_recovery = FALSE)
  r <- taxify:::enrich_simple(x, "mockinfraoff", col_map = c(regions = "regions"),
                              source_label = "mock", verbose = FALSE)
  expect_true(is.na(r$regions))
})

test_that("a direct hit survives the marker fallback (only empty cells are filled)", {
  install_mock_enrichment("mockinfradirect", data.frame(
    canonical_name = c("Quercus robur", "Erica tenella var. tenella"),
    regions        = c(3L, 12L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = c("Quercus robur", "Erica tenella tenella"),
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- taxify:::enrich_simple(x, "mockinfradirect", col_map = c(regions = "regions"),
                              source_label = "mock", verbose = FALSE)
  expect_equal(r$regions, c(3L, 12L))
})

test_that("enrich_by_group() recovers a marker-ful key against a marker-less GBIF name", {
  install_mock_enrichment("mockinfragroup", data.frame(
    canonical_name = rep("Erica tenella var. tenella", 2L),
    tdwg_code      = c("BGM", "GER"),
    native_status  = c("native", "introduced"),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Erica tenella tenella",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- taxify:::enrich_by_group(x, "mockinfragroup", group_col = "tdwg_code",
                                groups = c("BGM", "GER"),
                                value_cols = c(native_status = "native_status"),
                                source_label = "mock", verbose = FALSE)
  expect_equal(r$native_status_BGM, "native")
  expect_equal(r$native_status_GER, "introduced")
})

test_that(".infra_marker_variants() yields marker alternatives and skips non-infraspecific names", {
  v <- taxify:::.infra_marker_variants("Erica tenella var. tenella")
  expect_true("Erica tenella tenella" %in% v)
  expect_true("Erica tenella subsp. tenella" %in% v)
  expect_false("Erica tenella var. tenella" %in% v)  # the original is excluded

  vlm <- taxify:::.infra_marker_variants("Erica tenella tenella")
  expect_true("Erica tenella var. tenella" %in% vlm)
  expect_false("Erica tenella tenella" %in% vlm)      # the original is excluded

  expect_length(taxify:::.infra_marker_variants("Quercus robur"), 0L)
  expect_length(taxify:::.infra_marker_variants("Quercus"), 0L)
})

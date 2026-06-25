# Aggregate handling: name-key helpers, preserve/collapse key attachment,
# and the directional enrichment-join rule (traits inherit down, never up).

test_that("strip_agg_marker / canon_agg_marker fold marker spellings", {
  expect_equal(strip_agg_marker("Achillea millefolium aggr."), "Achillea millefolium")
  expect_equal(strip_agg_marker("Arion agg"), "Arion")
  expect_equal(strip_agg_marker("Cheilosia vernalis-agg"), "Cheilosia vernalis")
  expect_equal(strip_agg_marker("Quercus robur"), "Quercus robur")

  expect_equal(canon_agg_marker("Achillea millefolium agg."), "Achillea millefolium aggr.")
  expect_equal(canon_agg_marker("Arion agg"), "Arion aggr.")
  expect_equal(canon_agg_marker("Quercus robur"), "Quercus robur")
  expect_true(is.na(canon_agg_marker(NA_character_)))
})

test_that("attach_agg_key populates agg_key only in preserve mode", {
  nd <- clean_names(c("Rubus fruticosus agg.", "Quercus robur"))

  p <- attach_agg_key(nd, "preserve")
  expect_equal(p$agg_key, c("Rubus fruticosus aggr.", NA))

  cc <- attach_agg_key(nd, "collapse")
  expect_true(all(is.na(cc$agg_key)))
})

test_that("agg_join_keys encodes the directional inheritance rule", {
  # species query: own name primary, aggregate form as downward fallback
  sp <- agg_join_keys("Achillea millefolium", NA_character_)
  expect_equal(sp$primary, "Achillea millefolium")
  expect_equal(sp$inherit, "Achillea millefolium aggr.")

  # aggregate query: aggregate key only, never falls down to the species
  ag <- agg_join_keys("Achillea millefolium aggr.", "agg.")
  expect_equal(ag$primary, "Achillea millefolium aggr.")
  expect_true(is.na(ag$inherit))

  # aggregate query that fell back to the binomial still targets the aggregate
  ag2 <- agg_join_keys("Achillea millefolium", "agg.")
  expect_equal(ag2$primary, "Achillea millefolium aggr.")
  expect_true(is.na(ag2$inherit))

  # s.l. is treated as aggregate too
  sl <- agg_join_keys("Ranunculus auricomus", "s.l.")
  expect_equal(sl$primary, "Ranunculus auricomus aggr.")
})

test_that("agg_select_idx prefers same-level, flags downward inheritance", {
  enr <- c("Achillea millefolium", "Agropyron pectinatum aggr.")

  # case 4 + case 3: species->species exact, species->agg inherited
  keys <- agg_join_keys(c("Achillea millefolium", "Agropyron pectinatum"),
                        c(NA, NA))
  sel <- agg_select_idx(keys, enr)
  expect_equal(sel$idx, c(1L, 2L))
  expect_equal(sel$inherited, c(FALSE, TRUE))

  # case 1: aggregate query, only a species key present -> no match (no leak up)
  keys2 <- agg_join_keys("Achillea millefolium", "agg.")
  sel2 <- agg_select_idx(keys2, enr)
  expect_true(is.na(sel2$idx))
})

test_that("normalize_aggregate_name covers all marker spellings", {
  spellings <- c(
    "Achillea millefolium aggr.",
    "Achillea millefolium agg.",
    "Achillea millefolium agg",
    "Cheilosia vernalis-agg",
    "Ranunculus auricomus s.l.",
    "Ranunculus auricomus s. l.",
    "Taraxacum officinale sensu lato",
    "Galium mollugo coll. sp.",
    "Pilosella setifolia coll."
  )
  out <- normalize_aggregate_name(spellings)
  expect_equal(out, c(
    "Achillea millefolium aggr.",
    "Achillea millefolium aggr.",
    "Achillea millefolium aggr.",
    "Cheilosia vernalis aggr.",
    "Ranunculus auricomus aggr.",
    "Ranunculus auricomus aggr.",
    "Taraxacum officinale aggr.",
    "Galium mollugo aggr.",
    "Pilosella setifolia aggr."
  ))
  # plain names untouched
  expect_equal(normalize_aggregate_name("Quercus robur"), "Quercus robur")
})

test_that("is_aggregate_name detects every marker spelling", {
  expect_equal(
    is_aggregate_name(c("Achillea millefolium aggr.", "Arion agg",
                        "Ranunculus auricomus s.l.", "Quercus robur", NA)),
    c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )
})

test_that("normalize_aggregate_name appends marker for aggregate-rank rows", {
  name <- c("Taraxacum officinale", "Quercus robur", "Rubus fruticosus")
  rank <- c("SPECIES AGGREGATE", "SPECIES", "AGGR.")
  out <- normalize_aggregate_name(name, rank)
  expect_equal(out, c("Taraxacum officinale aggr.", "Quercus robur",
                      "Rubus fruticosus aggr."))

  # a rank-aggregate row that already carries a marker is not doubled
  expect_equal(
    normalize_aggregate_name("Achillea millefolium aggr.", "SPECIES AGGREGATE"),
    "Achillea millefolium aggr."
  )
})

test_that("aggregates argument is validated", {
  expect_error(taxify("Quercus robur", aggregates = "nonsense", verbose = FALSE))
})

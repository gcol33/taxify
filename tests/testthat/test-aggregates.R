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

test_that("agg_join_keys encodes the directional resolution rule", {
  # species query: own name primary, aggregate form as downward fallback
  sp <- agg_join_keys("Achillea millefolium", NA_character_)
  expect_equal(sp$primary, "Achillea millefolium")
  expect_equal(sp$inherit, "Achillea millefolium aggr.")
  expect_false(sp$is_agg)

  # aggregate query: aggregate key primary, nominal binomial as upward fallback
  ag <- agg_join_keys("Achillea millefolium aggr.", "agg.")
  expect_equal(ag$primary, "Achillea millefolium aggr.")
  expect_equal(ag$inherit, "Achillea millefolium")
  expect_true(ag$is_agg)

  # a preserve-fell-back aggregate (accepted_name is the binomial) still targets
  # the aggregate first, then the binomial
  ag2 <- agg_join_keys("Achillea millefolium", "agg.")
  expect_equal(ag2$primary, "Achillea millefolium aggr.")
  expect_equal(ag2$inherit, "Achillea millefolium")

  # binomial_fallback = FALSE keeps an aggregate query aggregate-only (no leak up)
  agf <- agg_join_keys("Achillea millefolium aggr.", "agg.",
                       binomial_fallback = FALSE)
  expect_equal(agf$primary, "Achillea millefolium aggr.")
  expect_true(is.na(agf$inherit))

  # s.l. is treated as aggregate too
  sl <- agg_join_keys("Ranunculus auricomus", "s.l.")
  expect_equal(sl$primary, "Ranunculus auricomus aggr.")
  expect_true(sl$is_agg)
})

test_that("agg_select_idx prefers same-level, records the fill basis", {
  enr <- c("Achillea millefolium", "Agropyron pectinatum aggr.")

  # species->species exact (primary), species->aggregate inherited (downward)
  keys <- agg_join_keys(c("Achillea millefolium", "Agropyron pectinatum"),
                        c(NA, NA))
  sel <- agg_select_idx(keys, enr)
  expect_equal(sel$idx, c(1L, 2L))
  expect_equal(sel$inherited, c(FALSE, TRUE))
  expect_equal(sel$basis, c("primary", "aggregate"))

  # aggregate query, only the nominal binomial present -> upward binomial fallback
  keys2 <- agg_join_keys("Achillea millefolium", "agg.")
  sel2 <- agg_select_idx(keys2, enr)
  expect_equal(sel2$idx, 1L)
  expect_equal(sel2$basis, "binomial")

  # with the fallback off, the same aggregate query stays unmatched
  keys3 <- agg_join_keys("Achillea millefolium", "agg.",
                         binomial_fallback = FALSE)
  sel3 <- agg_select_idx(keys3, enr)
  expect_true(is.na(sel3$idx))
  expect_true(is.na(sel3$basis))

  # aggregate query with a real aggregate-level row -> primary, not a fallback
  keys4 <- agg_join_keys("Agropyron pectinatum aggr.", "agg.")
  sel4 <- agg_select_idx(keys4, enr)
  expect_equal(sel4$idx, 2L)
  expect_equal(sel4$basis, "primary")
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


# ---- End-to-end: preserve resolves aggregates, collapse resolves binomials ----
#
# The mock Euro+Med backbone carries a dedicated aggregate taxon
# ("Taraxacum officinale aggr.", SPECIES AGGREGATE) alongside its binomial
# ("Taraxacum officinale"), mirroring the 433 aggregate taxa the real Euro+Med
# 2020.1 backbone holds. Fagus sylvatica has a binomial but no aggregate taxon,
# so it exercises the preserve-fell-back path.

setup_mock_euromed <- function() {
  bb <- mock_euromed_backbone_vtr()
  set_backbone_path("euromed", bb)
  # skip the once-per-session network version check
  .taxify_env[[".version_checked.euromed"]] <- TRUE
  # defer cleanup to the calling test's frame, not this helper's
  withr::defer(set_backbone_path("euromed", NULL), envir = parent.frame())
  invisible(bb)
}

test_that("the aggregates default is preserve", {
  expect_equal(eval(formals(taxify)$aggregates)[[1L]], "preserve")
})

test_that("preserve (default) resolves an aggregate query to the aggregate taxon", {
  setup_mock_euromed()
  res <- taxify("Taraxacum officinale agg.", backend = "euromed", verbose = FALSE)

  expect_equal(res$match_type, "exact")
  expect_equal(res$matched_name, "Taraxacum officinale aggr.")
  expect_equal(res$accepted_name, "Taraxacum officinale aggr.")
  expect_match(res$rank, "aggregate", ignore.case = TRUE)
  # preserve honoured the aggregate concept: no fallback
  expect_false(res$aggregate_fallback)
  # the input marker is still recorded
  expect_equal(res$qualifier, "agg.")
})

test_that("collapse resolves an aggregate query to the binomial", {
  setup_mock_euromed()
  res <- taxify("Taraxacum officinale agg.", backend = "euromed",
                aggregates = "collapse", verbose = FALSE)

  expect_equal(res$match_type, "exact")
  expect_equal(res$matched_name, "Taraxacum officinale")
  expect_equal(res$accepted_name, "Taraxacum officinale")
  # collapse is explicit, so no "fallback" is flagged
  expect_true(is.na(res$aggregate_fallback))
  # the marker is still recorded even though it was stripped for matching
  expect_equal(res$qualifier, "agg.")
})

test_that("preserve flags a silent fallback when the backbone lacks the aggregate taxon", {
  setup_mock_euromed()
  # Fagus sylvatica has no "Fagus sylvatica aggr." in the backbone, so preserve
  # falls through to the binomial -- and must say so.
  res <- taxify("Fagus sylvatica agg.", backend = "euromed", verbose = FALSE)

  expect_equal(res$matched_name, "Fagus sylvatica")
  expect_true(res$aggregate_fallback)
})

test_that("aggregate_fallback is NA for non-aggregate queries", {
  setup_mock_euromed()
  res <- taxify(c("Quercus robur", "Taraxacum officinale agg."),
                backend = "euromed", verbose = FALSE)
  # plain binomial: not an aggregate query at all
  expect_true(is.na(res$aggregate_fallback[1L]))
  # aggregate query that resolved: FALSE, not NA
  expect_false(res$aggregate_fallback[2L])
})


# ---- Trait join: aggregate query falls back to the nominal binomial ----
#
# When a source carries no aggregate-level value, an aggregate query pulls the
# nominal binomial's trait as a pragmatic stand-in (default on), recorded as
# basis = "binomial". aggregate_trait_fallback = FALSE keeps it NA.

test_that("an aggregate query inherits the nominal binomial's trait by default", {
  setup_mock_euromed()
  install_mock_enrichment("mockagg", data.frame(
    canonical_name = "Taraxacum officinale", plant_height = 30,
    stringsAsFactors = FALSE))
  x <- taxify("Taraxacum officinale agg.", backend = "euromed", verbose = FALSE)
  # resolved to the aggregate taxon, which the source does not carry
  expect_equal(x$accepted_name, "Taraxacum officinale aggr.")
  x <- enrich_simple(x, "mockagg", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  # falls up to the nominal binomial's value
  expect_equal(x$plant_height, 30)
})

test_that("aggregate_trait_fallback = FALSE keeps the aggregate NA", {
  setup_mock_euromed()
  install_mock_enrichment("mockagg2", data.frame(
    canonical_name = "Taraxacum officinale", plant_height = 30,
    stringsAsFactors = FALSE))
  x <- taxify("Taraxacum officinale agg.", backend = "euromed", verbose = FALSE)
  x <- enrich_simple(x, "mockagg2", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE, aggregate_trait_fallback = FALSE)
  expect_true(is.na(x$plant_height))
})

test_that("a real aggregate-level value wins over the binomial fallback", {
  setup_mock_euromed()
  install_mock_enrichment("mockagg3", data.frame(
    canonical_name = c("Taraxacum officinale aggr.", "Taraxacum officinale"),
    plant_height = c(45, 30), stringsAsFactors = FALSE))
  x <- taxify("Taraxacum officinale agg.", backend = "euromed", verbose = FALSE)
  x <- enrich_simple(x, "mockagg3", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  # the aggregate-level measurement, not the binomial stand-in
  expect_equal(x$plant_height, 45)
})

test_that("the trait provenance option records basis = 'binomial'", {
  setup_mock_euromed()
  install_mock_enrichment("mockagg4", data.frame(
    canonical_name = "Taraxacum officinale", plant_height = 30,
    stringsAsFactors = FALSE))
  withr::local_options(taxify.trait_provenance = TRUE)
  x <- taxify("Taraxacum officinale agg.", backend = "euromed", verbose = FALSE)
  x <- enrich_simple(x, "mockagg4", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  expect_equal(x$mockagg4_basis, "binomial")
})

test_that("a preserve-fell-back aggregate still reaches the binomial's trait", {
  setup_mock_euromed()
  # Fagus sylvatica has no aggregate taxon, so the query fell back to the
  # binomial at match time; the trait join must still find the binomial's value.
  install_mock_enrichment("mockagg5", data.frame(
    canonical_name = "Fagus sylvatica", plant_height = 40,
    stringsAsFactors = FALSE))
  x <- taxify("Fagus sylvatica agg.", backend = "euromed", verbose = FALSE)
  expect_true(x$aggregate_fallback)
  x <- enrich_simple(x, "mockagg5", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  expect_equal(x$plant_height, 40)
})

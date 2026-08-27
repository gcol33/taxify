# Cross-backbone name recovery (#52).
#
# An enrichment .vtr is keyed on its source's own accepted names, expanded at
# build time onto every backbone's treatment of the same concept. Where that
# expansion missed a backbone, the join finds nothing under the name that
# backbone routed the query to -- the same code path, and the same empty
# output, as a name the source genuinely does not cover.
#
# These stage the alternatives directly rather than opening real backbones, so
# they run offline and pin the recovery wiring rather than any one backbone's
# synonymy.

alt_frame <- function(...) {
  rows <- list(...)
  do.call(rbind, lapply(rows, function(r) {
    data.frame(input_name = r[[1L]], backbone = r[[2L]], alt_name = r[[3L]],
               alt_authorship = if (length(r) >= 4L) r[[4L]] else NA_character_,
               alt_genus = sub(" .*", "", r[[3L]]),
               stringsAsFactors = FALSE)
  }))
}

test_that("enrich_simple() recovers a row the source holds under another backbone's name", {
  install_mock_enrichment("mockrecovery", data.frame(
    canonical_name = "Sabulina tenuifolia subsp. tenuifolia",
    regions        = 49L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "mockrecovery", col_map = c(regions = "regions"),
                           source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      alt_frame(list("Minuartia hybrida", "wcvp",
                     "Sabulina tenuifolia subsp. tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$regions, 49L)

  meta <- attr(r, "taxify_meta")$enrichments[[1L]]
  expect_equal(meta$n_recovered, 1L)
  expect_equal(meta$n_matched, 1L)
})

test_that("recovery reports once per call, naming the backbone that supplied it", {
  install_mock_enrichment("mockreport", data.frame(
    canonical_name = c("Sabulina tenuifolia", "Jacobaea vulgaris"),
    regions        = c(4L, 7L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = c("Minuartia hybrida", "Senecio jacobaea"),
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  expect_message(
    testthat::with_mocked_bindings(
      taxify:::enrich_simple(x, "mockreport", col_map = c(regions = "regions"),
                             source_label = "mock", verbose = TRUE),
      .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
        alt_frame(list("Minuartia hybrida", "col", "Sabulina tenuifolia"),
                  list("Senecio jacobaea", "col", "Jacobaea vulgaris"))
      },
      .package = "taxify"
    ),
    "2 name\\(s\\) had no row under the accepted name they were matched to; recovered via col"
  )
})

test_that("recovery leaves a direct hit alone and only fills empty cells", {
  install_mock_enrichment("mockdirect", data.frame(
    canonical_name = c("Quercus robur", "Sabulina tenuifolia"),
    regions        = c(1L, 4L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = c("Quercus robur", "Minuartia hybrida"),
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "mockdirect", col_map = c(regions = "regions"),
                           source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      # An alternative is offered for the row that already matched too; the
      # direct value must survive it.
      alt_frame(list("Quercus robur", "col", "Sabulina tenuifolia"),
                list("Minuartia hybrida", "col", "Sabulina tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$regions, c(1L, 4L))
  expect_equal(attr(r, "taxify_meta")$enrichments[[1L]]$n_recovered, 1L)
})

test_that("options(taxify.cross_backbone_recovery = FALSE) leaves the gap empty", {
  install_mock_enrichment("mockoff", data.frame(
    canonical_name = "Sabulina tenuifolia", regions = 4L,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  withr::local_options(taxify.cross_backbone_recovery = FALSE)
  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "mockoff", col_map = c(regions = "regions"),
                           source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      stop("alternatives must not be resolved when recovery is off")
    },
    .package = "taxify"
  )
  expect_true(is.na(r$regions))
  expect_equal(attr(r, "taxify_meta")$enrichments[[1L]]$n_recovered, 0L)
})

test_that("recovery prefers the backbone the enrichment is named after", {
  # Backbones disagree about where a moved name went, and the source gives the
  # two destinations different data. The source's own treatment wins, even
  # though COL comes first in the fallback priority.
  install_mock_enrichment("wcvp", data.frame(
    canonical_name = c("Sabulina tenuifolia subsp. tenuifolia",
                       "Sabulina tenuifolia subsp. hybrida"),
    regions        = c(49L, 1L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "wcvp", col_map = c(regions = "regions"),
                           source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      alt_frame(list("Minuartia hybrida", "col",
                     "Sabulina tenuifolia subsp. hybrida"),
                list("Minuartia hybrida", "wcvp",
                     "Sabulina tenuifolia subsp. tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$regions, 49L)
})

test_that("recovery falls back to fallback priority when the source is not a backbone", {
  install_mock_enrichment("mockprio", data.frame(
    canonical_name = c("Sabulina tenuifolia subsp. tenuifolia",
                       "Sabulina tenuifolia subsp. hybrida"),
    regions        = c(49L, 1L),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "mockprio", col_map = c(regions = "regions"),
                           source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      # Offered lowest-priority first, so a bare "take the first row" would
      # pick GBIF; COL outranks it.
      alt_frame(list("Minuartia hybrida", "gbif",
                     "Sabulina tenuifolia subsp. hybrida"),
                list("Minuartia hybrida", "col",
                     "Sabulina tenuifolia subsp. tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$regions, 49L)
})

test_that("a genus-keyed enrichment recovers on the alternative's genus", {
  install_mock_enrichment("mockgenusrec", data.frame(
    canonical_name = "Sabulina", genus = "Sabulina", myco = "AM",
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", genus = "Minuartia",
                  qualifier = NA_character_, stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_simple(x, "mockgenusrec", col_map = c(myco = "myco"),
                           source_label = "mock", join_col = "genus",
                           verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      alt_frame(list("Minuartia hybrida", "col", "Sabulina tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$myco, "AM")
})

test_that("enrich_by_group() recovers, including when the direct join matched nothing", {
  install_mock_enrichment("mockgroup", data.frame(
    canonical_name = rep("Sabulina tenuifolia", 2L),
    tdwg_code      = c("BGM", "GER"),
    native_status  = c("native", "introduced"),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Minuartia hybrida", qualifier = NA_character_,
                  stringsAsFactors = FALSE)

  r <- testthat::with_mocked_bindings(
    taxify:::enrich_by_group(x, "mockgroup", group_col = "tdwg_code",
                             groups = c("BGM", "GER"),
                             value_cols = c(native_status = "native_status"),
                             source_label = "mock", verbose = FALSE),
    .cross_backbone_alternatives = function(names_in, kingdoms = NULL) {
      alt_frame(list("Minuartia hybrida", "col", "Sabulina tenuifolia"))
    },
    .package = "taxify"
  )
  expect_equal(r$native_status_BGM, "native")
  expect_equal(r$native_status_GER, "introduced")
  expect_equal(attr(r, "taxify_meta")$enrichments[[1L]]$n_recovered, 1L)
})

test_that("a single installed backbone yields no alternatives", {
  # Nothing to cross-check against, so the pass is skipped rather than run.
  alts <- testthat::with_mocked_bindings(
    taxify:::.cross_backbone_alternatives("Minuartia hybrida"),
    installed_backbones = function(...) "wfo",
    .package = "taxify"
  )
  expect_equal(nrow(alts), 0L)
})

test_that("a backbone fixed to another kingdom is not opened", {
  seen <- character(0L)
  testthat::with_mocked_bindings(
    taxify:::.cross_backbone_alternatives("Turdus merula", kingdoms = "animalia"),
    installed_backbones = function(...) {
      c("col", "gbif", "wfo", "wcvp", "lcvp", "euromed", "fungorum")
    },
    taxify = function(x, backbone, ...) {
      seen <<- c(seen, backbone)
      data.frame(input_name = x, accepted_name = NA_character_,
                 accepted_authorship = NA_character_, genus = NA_character_,
                 stringsAsFactors = FALSE)
    },
    .package = "taxify"
  )
  expect_setequal(seen, c("col", "gbif"))
})

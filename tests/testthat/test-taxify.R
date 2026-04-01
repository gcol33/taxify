# Integration tests for the main taxify() function.
# These use a mock backbone injected via the cache.

setup_mock_backend <- function() {
  # Create mock backbone and inject path into cache
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, bb_path)
  be
}

test_that("taxify returns correct 15-column schema", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expected_cols <- c("input_name", "matched_name", "accepted_name",
                     "taxon_id", "accepted_id", "rank", "family",
                     "genus", "epithet", "authorship", "is_synonym",
                     "is_hybrid", "match_type", "fuzzy_dist", "backend")
  expect_named(result, expected_cols)
})

test_that("taxify matches known species", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)
  expect_equal(result$matched_name, "Quercus robur")
  expect_equal(result$accepted_name, "Quercus robur")
  expect_equal(result$match_type, "exact")
  expect_false(result$is_synonym)
  expect_equal(result$backend, "wfo")
})

test_that("taxify resolves synonyms", {
  setup_mock_backend()
  result <- taxify("Quercus pedunculata", verbose = FALSE)
  expect_equal(result$matched_name, "Quercus pedunculata")
  expect_equal(result$accepted_name, "Quercus robur")
  expect_true(result$is_synonym)
})

test_that("taxify handles fuzzy matching", {
  setup_mock_backend()
  result <- taxify("Quercus robus", verbose = FALSE)
  expect_equal(result$matched_name, "Quercus robur")
  expect_equal(result$match_type, "fuzzy")
  expect_true(result$fuzzy_dist > 0)
})

test_that("taxify handles unmatched names", {
  setup_mock_backend()
  result <- taxify("Nonexistus imaginus", verbose = FALSE)
  expect_equal(result$match_type, "none")
  expect_true(is.na(result$matched_name))
  expect_true(is.na(result$accepted_name))
  expect_true(is.na(result$backend))
})

test_that("taxify handles multiple inputs", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris", "Nonexistus foo"),
                   verbose = FALSE)
  expect_equal(nrow(result), 3L)
  expect_equal(result$match_type, c("exact", "exact", "none"))
  expect_equal(result$matched_name[1:2], c("Quercus robur", "Pinus sylvestris"))
  expect_true(is.na(result$matched_name[3L]))
})

test_that("taxify with fuzzy = FALSE skips fuzzy", {
  setup_mock_backend()
  result <- taxify("Quercus robus", fuzzy = FALSE, verbose = FALSE)
  expect_equal(result$match_type, "none")
})

test_that("taxify strips authorship before matching", {
  setup_mock_backend()
  result <- taxify("Quercus robur L.", verbose = FALSE)
  expect_equal(result$matched_name, "Quercus robur")
  expect_equal(result$match_type, "exact")
})

test_that("taxify handles NA input", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", NA), verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(result$match_type[1L], "exact")
  expect_true(is.na(result$match_type[2L]))
  expect_true(is.na(result$matched_name[2L]))
})

test_that("taxify detects hybrids", {
  setup_mock_backend()
  result <- taxify("Quercus \u00d7 hispanica", verbose = FALSE)
  expect_true(result$is_hybrid)
  expect_equal(result$matched_name, "Quercus hispanica")
})

test_that("taxify rejects non-character input", {
  expect_error(taxify(123), "x must be a character")
})

test_that("taxify rejects empty input", {
  expect_error(taxify(character(0)), "at least one element")
})

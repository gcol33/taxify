# Integration tests for the main taxify() function.
# These use a mock backbone injected via the cache.

setup_mock_backend <- function() {
  # Create mock backbone and inject path into cache
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, bb_path)
  be
}

test_that("taxify returns correct schema", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)
  expect_s3_class(result, "taxify_result")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expected_cols <- c("input_name", "matched_name", "accepted_name",
                     "taxon_id", "accepted_id", "rank", "family",
                     "genus", "epithet", "authorship", "accepted_authorship",
                     "is_synonym", "is_hybrid", "match_type", "fuzzy_dist",
                     "backend", "backbone_version", "life_form")
  expect_true(all(expected_cols %in% names(result)),
              info = paste("Missing cols:", paste(setdiff(expected_cols, names(result)),
                                                  collapse = ", ")))
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

test_that("taxify reports the accepted name's authorship", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Quercus pedunculata"), verbose = FALSE)

  # Direct accepted match: matched author and accepted author agree.
  expect_equal(result$authorship[1L], "L.")
  expect_equal(result$accepted_authorship[1L], "L.")

  # Synonym: `authorship` keeps the synonym's own author, while
  # `accepted_authorship` carries the resolved accepted name's author, so
  # `accepted_name` + `accepted_authorship` cite the accepted taxon correctly.
  expect_true(result$is_synonym[2L])
  expect_equal(result$accepted_name[2L], "Quercus robur")
  expect_equal(result$authorship[2L], "(Mattusch.) Bonnier & Layens")
  expect_equal(result$accepted_authorship[2L], "L.")
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


# ---- taxify_result class and metadata ----

test_that("taxify() returns a taxify_result with taxify_meta attribute", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris", "Nonexistus foo"),
                   verbose = FALSE)

  expect_s3_class(result, "taxify_result")
  meta <- attr(result, "taxify_meta")
  expect_type(meta, "list")
  expect_true(all(c("backend", "n_input", "match_tally",
                    "out_of_scope_tally", "life_form_tally") %in% names(meta)))
})

test_that("taxify_meta tallies are correct", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris", "Nonexistus foo"),
                   fuzzy = FALSE, verbose = FALSE)

  meta <- attr(result, "taxify_meta")
  expect_equal(meta$n_input, 3L)
  expect_equal(meta$match_tally$exact, 2L)
  expect_equal(meta$match_tally$unmatched, 1L)
  expect_equal(meta$match_tally$fuzzy, 0L)
  expect_equal(meta$match_tally$abbrev, 0L)
  expect_equal(meta$match_tally$out_of_scope, 0L)
})

test_that("print.taxify_result() delegates to data.frame print", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)
  # print() should not error and should return invisibly
  out <- capture.output(print(result))
  expect_true(length(out) > 0L)
})

test_that("summary.taxify_result() produces output and returns invisibly", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris", "Nonexistus foo"),
                   fuzzy = FALSE, verbose = FALSE)

  out <- capture.output(ret <- summary(result))
  # Should produce lines of output
  expect_true(length(out) > 0L)
  # Should mention the backend
  expect_true(any(grepl("WFO", out, ignore.case = TRUE)))
  # Should mention name count
  expect_true(any(grepl("3", out)))
  # Returns invisibly (same object)
  expect_identical(ret, result)
})

test_that("summary.taxify_result() shows out_of_scope line when present", {
  setup_mock_backend()
  # Inject a mock register so Boletus gets classified as out_of_scope
  .taxify_env$register <- data.frame(
    genus     = c("Quercus", "Boletus"),
    kingdom   = c("Plantae", "Fungi"),
    phylum    = c("Tracheophyta", "Basidiomycota"),
    class     = c("Magnoliopsida", NA_character_),
    order     = c("Fagales", "Boletales"),
    family    = c("Fagaceae", "Boletaceae"),
    life_form = c("vascular", "fungus"),
    stringsAsFactors = FALSE
  )
  on.exit(.taxify_env$register <- NULL, add = TRUE)

  # WFO covers Quercus but not Boletus, so Boletus is out_of_scope. Mock the
  # coverage file so the test does not depend on a real coverage .vtr.
  cov_path <- mock_coverage_vtr(genus = "Quercus", backend = "wfo")
  clear_coverage_cache()
  on.exit(clear_coverage_cache(), add = TRUE)

  result <- with_mocked_bindings(
    coverage_vtr_path = function() cov_path,
    taxify(c("Quercus robur", "Boletus edulis"), fuzzy = FALSE, verbose = FALSE)
  )

  meta <- attr(result, "taxify_meta")
  expect_equal(meta$match_tally$out_of_scope, 1L)

  out <- capture.output(summary(result))
  expect_true(any(grepl("out of scope", out, ignore.case = TRUE)))
})

test_that("summary.taxify_result() counts abbreviated-genus matches", {
  setup_mock_backend()
  # "Q. robur" resolves via genus initial plus epithet (match_type "abbrev").
  # The unabbreviated "Quercus robur" in the batch disambiguates the initial.
  result <- taxify(c("Quercus robur", "Q. robur"), fuzzy = FALSE, verbose = FALSE)
  expect_true("abbrev" %in% result$match_type)

  meta <- attr(result, "taxify_meta")
  expect_equal(meta$match_tally$abbrev, 1L)

  # The abbrev match is counted in the matched total and shown in the breakdown
  # (regression: abbrev was previously omitted from both).
  out <- capture.output(summary(result))
  matched_line <- grep("matched", out, value = TRUE)[1]
  expect_match(matched_line, "abbrev: 1")
  expect_match(matched_line, "matched\\s+2")
})

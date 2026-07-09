# Formula-first matching and the hybrid-aware trait ladder.

sx <- intToUtf8(0x00D7)

# A Salix backbone with both parents; optionally also the cross stored as a
# synonym of the nothospecies (Salix x rubens), to exercise formula-first.
salix_backbone <- function(with_cross = FALSE) {
  canon  <- c("Salix alba", "Salix fragilis")
  tid    <- c("t3", "t4")
  status <- c("ACCEPTED", "ACCEPTED")
  accid  <- c(NA_character_, NA_character_)
  epi    <- c("alba", "fragilis")
  if (with_cross) {
    canon  <- c(paste0("Salix alba ", sx, " Salix fragilis"),
                paste0("Salix ", sx, " rubens"), canon)
    tid    <- c("t1", "t2", tid)
    status <- c("SYNONYM", "ACCEPTED", status)
    accid  <- c("t2", NA_character_, accid)
    epi    <- c(NA_character_, "rubens", epi)
  }
  df <- data.frame(
    canonical_name = canon, taxon_id = tid, taxon_rank = "SPECIES",
    taxonomic_status = status, accepted_name_usage_id = accid,
    family = "Salicaceae", genus = "Salix", specific_epithet = epi,
    authorship = NA_character_, infraspecific_epithet = NA_character_,
    stringsAsFactors = FALSE)
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(df, id_col = "taxon_id",
    acc_id_col = "accepted_name_usage_id", name_col = "canonical_name",
    family_col = "family", genus_col = "genus",
    status_col = "taxonomic_status", authorship_col = "authorship")
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  be <- wfo_backend()
  set_backbone_path(be$name, tmp)
  # Restore the wfo cache when the calling test ends, so later test files that
  # resolve wfo from the example data dir are not affected by this mock.
  withr::defer(set_backbone_path(be$name, NULL), envir = parent.frame())
  be
}

# install_mock_enrichment() lives in helper-mock-enrichment.R (shared with the
# aggregate-fallback tests).

test_that("a formula resolves to a stored nothospecies (formula-first)", {
  salix_backbone(with_cross = TRUE)
  r <- taxify("Salix alba x Salix fragilis", verbose = FALSE)
  expect_equal(r$match_type, "exact")
  expect_equal(r$accepted_name, paste0("Salix ", sx, " rubens"))
  expect_equal(r$hybrid_type, "formula")
  expect_true(r$is_hybrid)
})

test_that("a formula with no stored cross is a hybrid_formula named by its parents", {
  salix_backbone(with_cross = FALSE)
  r <- taxify("Salix alba x Salix fragilis", verbose = FALSE)
  expect_equal(r$match_type, "hybrid_formula")
  # both parents resolve, so the cross is named by them (no false single match)
  cross <- paste0("Salix alba ", sx, " Salix fragilis")
  expect_equal(r$matched_name, cross)
  expect_equal(r$accepted_name, cross)
  expect_true(r$is_hybrid)
})

test_that("a formula with an unmatchable parent leaves the cross name NA", {
  salix_backbone(with_cross = FALSE)
  r <- taxify("Salix alba x Salix nonexistus", verbose = FALSE)
  expect_equal(r$match_type, "hybrid_formula")
  expect_true(is.na(r$accepted_name))
  expect_true(is.na(r$matched_name))
})

test_that("trait ladder averages numeric parents and keeps agreeing categoricals", {
  salix_backbone(with_cross = FALSE)
  install_mock_enrichment("mocktrait", data.frame(
    canonical_name = c("Salix alba", "Salix fragilis"),
    plant_height = c(20, 15), woodiness = c("woody", "woody"),
    stringsAsFactors = FALSE))
  x <- taxify("Salix alba x Salix fragilis", verbose = FALSE)
  x <- enrich_simple(x, "mocktrait",
    col_map = c(plant_height = "plant_height", woodiness = "woodiness"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  expect_equal(x$plant_height, 17.5)
  expect_equal(x$woodiness, "woody")
})

test_that("trait ladder flags a categorical conflict as 'A x B' with a warning", {
  salix_backbone(with_cross = FALSE)
  install_mock_enrichment("mockconf", data.frame(
    canonical_name = c("Salix alba", "Salix fragilis"),
    woodiness = c("woody", "non-woody"), stringsAsFactors = FALSE))
  x <- taxify("Salix alba x Salix fragilis", verbose = FALSE)
  expect_warning(
    x <- enrich_simple(x, "mockconf", col_map = c(woodiness = "woodiness"),
      source_label = "mock", join_col = "accepted_name",
      expose_all = TRUE, verbose = TRUE),
    "combined as")
  expect_equal(x$woodiness, "woody x non-woody")
})

test_that("trait ladder uses the single available parent", {
  salix_backbone(with_cross = FALSE)
  install_mock_enrichment("mockone", data.frame(
    canonical_name = "Salix alba", plant_height = 20, stringsAsFactors = FALSE))
  x <- taxify("Salix alba x Salix fragilis", verbose = FALSE)
  x <- enrich_simple(x, "mockone", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  expect_equal(x$plant_height, 20)
})

test_that("per-parent trait columns appear when parents are materialized", {
  salix_backbone(with_cross = FALSE)
  install_mock_enrichment("mockpp", data.frame(
    canonical_name = c("Salix alba", "Salix fragilis"),
    plant_height = c(20, 15), stringsAsFactors = FALSE))
  x <- taxify("Salix alba x Salix fragilis", verbose = FALSE) |> add_hybrid_info()
  x <- enrich_simple(x, "mockpp", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = TRUE, verbose = FALSE)
  expect_equal(x$plant_height, 17.5)
  expect_true(all(c("plant_height_parent1", "plant_height_parent2") %in% names(x)))
  expect_equal(x$plant_height_parent1, 20)
  expect_equal(x$plant_height_parent2, 15)
})

test_that("a non-hybrid row is unaffected by the ladder", {
  salix_backbone(with_cross = FALSE)
  install_mock_enrichment("mockplain", data.frame(
    canonical_name = c("Salix alba", "Salix fragilis"),
    plant_height = c(20, 15), stringsAsFactors = FALSE))
  x <- taxify("Salix alba", verbose = FALSE)
  x <- enrich_simple(x, "mockplain", col_map = c(plant_height = "plant_height"),
    source_label = "mock", join_col = "accepted_name",
    expose_all = FALSE, verbose = FALSE)
  expect_equal(x$plant_height, 20)
  expect_false("plant_height_parent1" %in% names(x))
})

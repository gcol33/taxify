test_that("exact matching finds known species", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "wfo-0000001")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("exact matching handles multiple inputs", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name, c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("case-insensitive matching works", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("unmatched names have NA match_type", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("exact matching finds synonyms and resolves accepted info", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "wfo-0000001")
})

test_that("fuzzy matching catches typos", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()

  # Start from a result where exact failed
  names_df <- clean_names("Quercus robus")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  # Now fuzzy
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("fuzzy matching respects threshold", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()

  # Very different name — should not match at 0.2 threshold
  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})

test_that("accepted info is precomputed for synonyms", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "wfo-0000001")
  expect_true(result$is_synonym[1L])
})

test_that("accepted info is self for accepted names", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "wfo-0000001")
  expect_false(result$is_synonym[1L])
})

test_that("pick_best prefers ACCEPTED over SYNONYM", {
  candidates <- data.frame(
    taxonID = c("wfo-0000002", "wfo-0000001"),
    taxonomicStatus = c("SYNONYM", "ACCEPTED"),
    taxonRank = c("SPECIES", "SPECIES"),
    stringsAsFactors = FALSE
  )
  best <- pick_best(candidates)
  expect_equal(best$taxonID, "wfo-0000001")
})

test_that("pick_best prefers SPECIES over higher ranks", {
  candidates <- data.frame(
    taxonID = c("wfo-0000001", "wfo-0000002"),
    taxonomicStatus = c("ACCEPTED", "ACCEPTED"),
    taxonRank = c("GENUS", "SPECIES"),
    stringsAsFactors = FALSE
  )
  best <- pick_best(candidates)
  expect_equal(best$taxonID, "wfo-0000002")
})

test_that("NA inputs don't crash matching", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

# ---- Homonym synonyms (Valid-filter + is_ambiguous) ----

test_that("pick_best_vec flags homonym synonyms as ambiguous (no Valid filter)", {
  # Same scientificName, three synonym rows, three different accepted IDs.
  # Without nomenclaturalStatus column, the Valid-filter cannot help —
  # ambiguity must still be reported.
  matches <- data.frame(
    row_idx           = c(1L, 1L, 1L),
    taxonID           = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus   = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank         = c("SPECIES", "SPECIES", "SPECIES"),
    accepted_taxon_id = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors  = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(nrow(best), 1L)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets,
               "wfo-0000005|wfo-0000019|wfo-0000022")
})

test_that("pick_best_vec uses Valid-filter to disambiguate homonyms", {
  # Of three synonym rows, only one is nomenclaturally Valid — that one wins.
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Illegitimate", "Valid", "Illegitimate"),
    accepted_taxon_id   = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(best$taxonID, "wfo-0000020")
  expect_equal(best$accepted_taxon_id, "wfo-0000005")
  expect_false(best$is_ambiguous)
  expect_true(is.na(best$ambiguous_targets))
})

test_that("pick_best_vec keeps ambiguity flag when 2+ Valid rows disagree", {
  # Two of three synonym rows are Valid but point to different accepted IDs.
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Valid", "Illegitimate"),
    accepted_taxon_id   = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets, "wfo-0000005|wfo-0000019")
})

test_that("case-tolerant ACCEPTED detection (Accepted vs ACCEPTED)", {
  # Real WFO data uses 'Accepted' / 'Synonym' (mixed case), the mock fixture
  # uses 'ACCEPTED' / 'SYNONYM'. Both must work.
  for (lab_acc in c("Accepted", "ACCEPTED")) {
    for (lab_syn in c("Synonym", "SYNONYM")) {
      candidates <- data.frame(
        taxonID = c("wfo-x", "wfo-y"),
        taxonomicStatus = c(lab_syn, lab_acc),
        taxonRank = c("SPECIES", "SPECIES"),
        stringsAsFactors = FALSE
      )
      best <- pick_best(candidates)
      expect_equal(best$taxonID, "wfo-y",
                   info = sprintf("acc=%s, syn=%s", lab_acc, lab_syn))
    }
  }
})

test_that("end-to-end: WFO mock with nom_status disambiguates Pinus abies", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr(with_nom_status = TRUE)
  names_df <- clean_names("Pinus abies")

  result <- match_exact(be, names_df, backbone)
  # Of three synonym rows, two are Valid (Thunb. → Picea polita,
  # L. → Pinus sylvestris). One is Illegitimate. Two Valid rows disagree →
  # is_ambiguous should be TRUE.
  expect_equal(result$match_type[1L], "exact")
  expect_true(result$is_synonym[1L])
  expect_true(result$is_ambiguous[1L])
  expect_match(result$ambiguous_targets[1L], "wfo-0000005")
  expect_match(result$ambiguous_targets[1L], "wfo-0000019")
})

test_that("backbone without nomenclaturalStatus still reports ambiguity", {
  be <- wfo_backend()
  backbone <- mock_backbone_vtr(with_nom_status = FALSE)
  names_df <- clean_names("Pinus abies")
  result <- match_exact(be, names_df, backbone)
  expect_equal(result$match_type[1L], "exact")
  expect_true(result$is_ambiguous[1L])
  expect_match(result$ambiguous_targets[1L], "\\|")
})

# ---- Fuzzy uniqueness: dedup_fuzzy_targets ----

test_that("dedup_fuzzy_targets keeps only closest query per target", {
  # Three distinct queries fuzzy-mapped to the same backbone row, the second
  # being closest. Only the second should survive.
  best <- data.frame(
    row_idx    = c(1L, 2L, 3L),
    taxonID    = c("wfo-x", "wfo-x", "wfo-x"),
    fuzzy_dist = c(0.2, 0.1, 0.3),
    stringsAsFactors = FALSE
  )
  out <- dedup_fuzzy_targets(best, id_col = "taxonID")
  expect_equal(nrow(out), 1L)
  expect_equal(out$row_idx, 2L)
})

test_that("dedup_fuzzy_targets preserves exact (distance = 0) hits", {
  # Two queries hit the same target — one with distance 0 (exact synonym
  # pointing to same accepted), one with distance 0.1 (fuzzy). The exact one
  # is genuine and must be kept; the fuzzy one over the same target should be
  # filtered as a spurious collapse.
  best <- data.frame(
    row_idx    = c(1L, 2L),
    taxonID    = c("wfo-x", "wfo-x"),
    fuzzy_dist = c(0.0, 0.1),
    stringsAsFactors = FALSE
  )
  out <- dedup_fuzzy_targets(best, id_col = "taxonID")
  expect_equal(nrow(out), 1L)
  expect_equal(out$row_idx, 1L)
})

test_that("dedup_fuzzy_targets is a no-op for distinct targets", {
  best <- data.frame(
    row_idx    = c(1L, 2L, 3L),
    taxonID    = c("wfo-a", "wfo-b", "wfo-c"),
    fuzzy_dist = c(0.1, 0.2, 0.3),
    stringsAsFactors = FALSE
  )
  expect_equal(dedup_fuzzy_targets(best, id_col = "taxonID"), best)
})

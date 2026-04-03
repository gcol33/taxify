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

# ---- WoRMS backend tests ----

# -- Backend construction --

test_that("worms_backend creates correct object", {
  be <- worms_backend()
  expect_s3_class(be, "taxify_worms")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "worms")
})


# -- Exact matching --

test_that("WoRMS exact matching finds known species", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names("Gadus morhua")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Gadus morhua")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "127160")
  expect_equal(result$genus[1L], "Gadus")
  expect_equal(result$epithet[1L], "morhua")
  expect_equal(result$family[1L], "Gadidae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("WoRMS exact matching handles multiple inputs", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names(c("Gadus morhua", "Salmo salar", "Tursiops truncatus"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Gadus morhua", "Salmo salar", "Tursiops truncatus"))
  expect_true(all(result$match_type == "exact"))
})

test_that("WoRMS case-insensitive matching works", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names("gadus morhua")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Gadus morhua")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("WoRMS unmatched names have NA match_type", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("WoRMS exact matching finds synonyms and resolves accepted info", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names("Gadus callarias")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Gadus callarias")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Gadus morhua")
  expect_equal(result$accepted_id[1L], "127160")
})

test_that("WoRMS synonym with old spelling resolves correctly", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names("Salmo salmo")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Salmo salmo")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Salmo salar")
  expect_equal(result$accepted_id[1L], "127162")
})


# -- Fuzzy matching --

test_that("WoRMS fuzzy matching catches typos", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()

  names_df <- clean_names("Gadus morhau")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Gadus morhua")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("WoRMS fuzzy matching respects threshold", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("WoRMS accepted info is precomputed for synonyms", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()

  names_df <- clean_names("Gadus callarias")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Gadus morhua")
  expect_equal(result$accepted_id[1L], "127160")
  expect_true(result$is_synonym[1L])
})

test_that("WoRMS accepted info is self for accepted names", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()

  names_df <- clean_names("Gadus morhua")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Gadus morhua")
  expect_equal(result$accepted_id[1L], "127160")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("WoRMS handles NA inputs without crashing", {
  be <- worms_backend()
  backbone <- mock_worms_backbone_vtr()
  names_df <- clean_names(c("Gadus morhua", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Gadus morhua")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

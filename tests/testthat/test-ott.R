# ---- OTT (Open Tree of Life) backend tests ----

# -- Backend construction --

test_that("ott_backend creates correct object", {
  be <- ott_backend()
  expect_s3_class(be, "taxify_ott")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "ott")
})


# -- Exact matching --

test_that("OTT exact matching finds known species", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "532768")
  expect_equal(result$genus[1L], "Quercus")
  expect_equal(result$epithet[1L], "robur")
  expect_equal(result$family[1L], "Fagaceae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("OTT exact matching handles multiple inputs", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("OTT case-insensitive matching works", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("OTT unmatched names have NA match_type", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("OTT exact matching finds synonyms and resolves accepted info", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "532768")
})

test_that("OTT synonym with old spelling resolves correctly", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names("Pinus silvestris")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Pinus silvestris")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_equal(result$accepted_id[1L], "126218")
})


# -- Fuzzy matching --

test_that("OTT fuzzy matching catches typos", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()

  names_df <- clean_names("Quercus robus")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("OTT fuzzy matching respects threshold", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("OTT accepted info is precomputed for synonyms", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "532768")
  expect_true(result$is_synonym[1L])
})

test_that("OTT accepted info is self for accepted names", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "532768")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("OTT handles NA inputs without crashing", {
  be <- ott_backend()
  backbone <- mock_ott_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

# ---- Euro+Med backend tests ----

# -- Backend construction --

test_that("euromed_backend creates correct object", {
  be <- euromed_backend()
  expect_s3_class(be, "taxify_euromed")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "euromed")
})


# -- Exact matching --

test_that("Euro+Med exact matching finds known species", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "adb99dfe-7c2b-4396-a957-33e56cddd057")
  expect_equal(result$genus[1L], "Quercus")
  expect_equal(result$epithet[1L], "robur")
  expect_equal(result$family[1L], "Fagaceae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("Euro+Med exact matching handles multiple inputs", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Fagus sylvatica", "Pinus sylvestris"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Quercus robur", "Fagus sylvatica", "Pinus sylvestris"))
  expect_true(all(result$match_type == "exact"))
})

test_that("Euro+Med case-insensitive matching works", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("Euro+Med unmatched names have NA match_type", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})


# -- Synonym resolution --

test_that("Euro+Med synonym resolves to accepted name", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "adb99dfe-7c2b-4396-a957-33e56cddd057")
})

test_that("Euro+Med synonym with old genus resolves correctly", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Ranunculus acer")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Ranunculus acer")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Ranunculus acris")
})

test_that("Euro+Med accepted info is self for accepted names", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_false(result$is_synonym[1L])
})


# -- Fuzzy matching --

test_that("Euro+Med fuzzy matching catches typos", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()

  names_df <- clean_names("Quercus robor")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("Euro+Med fuzzy matching respects threshold", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Genus matching --

test_that("Euro+Med genus-only match works", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names("Quercus")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus")
  expect_equal(result$taxon_id[1L], "f03c28b8-3cd7-4cdc-ac8e-67caef8839be")
  expect_equal(result$family[1L], "Fagaceae")
})


# -- NA handling --

test_that("Euro+Med handles NA inputs without crashing", {
  be <- euromed_backend()
  backbone <- mock_euromed_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

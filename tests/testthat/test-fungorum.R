# ---- Species Fungorum Plus backend tests ----

# -- Backend construction --

test_that("fungorum_backend creates correct object", {
  be <- fungorum_backend()
  expect_s3_class(be, "taxify_fungorum")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "fungorum")
})


# -- Exact matching --

test_that("Fungorum exact matching finds known species", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names("Amanita muscaria")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Amanita muscaria")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "100001")
  expect_equal(result$genus[1L], "Amanita")
  expect_equal(result$epithet[1L], "muscaria")
  expect_equal(result$family[1L], "Amanitaceae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("Fungorum exact matching handles multiple inputs", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names(c("Amanita muscaria", "Boletus edulis",
                            "Cantharellus cibarius"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Amanita muscaria", "Boletus edulis", "Cantharellus cibarius"))
  expect_true(all(result$match_type == "exact"))
})

test_that("Fungorum case-insensitive matching works", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names("amanita muscaria")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Amanita muscaria")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("Fungorum unmatched names have NA match_type", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("Fungorum exact matching finds synonyms and resolves accepted info", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names("Boletus bulbosus")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Boletus bulbosus")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Boletus edulis")
  expect_equal(result$accepted_id[1L], "100003")
})

test_that("Fungorum synonym with old name resolves correctly", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names("Cantharellus pallens")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Cantharellus pallens")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Cantharellus cibarius")
  expect_equal(result$accepted_id[1L], "100004")
})


# -- Fuzzy matching --

test_that("Fungorum fuzzy matching catches typos", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()

  names_df <- clean_names("Amanita muscarai")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Amanita muscaria")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("Fungorum fuzzy matching respects threshold", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("Fungorum accepted info is precomputed for synonyms", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()

  names_df <- clean_names("Boletus bulbosus")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Boletus edulis")
  expect_equal(result$accepted_id[1L], "100003")
  expect_true(result$is_synonym[1L])
})

test_that("Fungorum accepted info is self for accepted names", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()

  names_df <- clean_names("Amanita muscaria")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Amanita muscaria")
  expect_equal(result$accepted_id[1L], "100001")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("Fungorum handles NA inputs without crashing", {
  be <- fungorum_backend()
  backbone <- mock_fungorum_backbone_vtr()
  names_df <- clean_names(c("Amanita muscaria", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Amanita muscaria")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

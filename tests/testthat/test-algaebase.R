# ---- AlgaeBase backend tests ----

# -- Backend construction --

test_that("algaebase_backend creates correct object", {
  be <- algaebase_backend()
  expect_s3_class(be, "taxify_algaebase")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "algaebase")
})


# -- Exact matching --

test_that("AlgaeBase exact matching finds known species", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names("Chlorella vulgaris")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Chlorella vulgaris")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "200001")
  expect_equal(result$genus[1L], "Chlorella")
  expect_equal(result$epithet[1L], "vulgaris")
  expect_equal(result$family[1L], "Chlorellaceae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("AlgaeBase exact matching handles multiple inputs", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names(c("Chlorella vulgaris", "Ulva lactuca",
                            "Fucus vesiculosus"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Chlorella vulgaris", "Ulva lactuca", "Fucus vesiculosus"))
  expect_true(all(result$match_type == "exact"))
})

test_that("AlgaeBase case-insensitive matching works", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names("chlorella vulgaris")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Chlorella vulgaris")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("AlgaeBase unmatched names have NA match_type", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("AlgaeBase exact matching finds synonyms and resolves accepted info", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names("Ulva latissima")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Ulva latissima")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Ulva lactuca")
  expect_equal(result$accepted_id[1L], "200003")
})

test_that("AlgaeBase synonym with old name resolves correctly", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names("Fucus inflatus")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Fucus inflatus")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Fucus vesiculosus")
  expect_equal(result$accepted_id[1L], "200004")
})


# -- Fuzzy matching --

test_that("AlgaeBase fuzzy matching catches typos", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()

  names_df <- clean_names("Chlorella vulgares")
  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Chlorella vulgaris")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("AlgaeBase fuzzy matching respects threshold", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("AlgaeBase accepted info is precomputed for synonyms", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()

  names_df <- clean_names("Ulva latissima")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Ulva lactuca")
  expect_equal(result$accepted_id[1L], "200003")
  expect_true(result$is_synonym[1L])
})

test_that("AlgaeBase accepted info is self for accepted names", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()

  names_df <- clean_names("Chlorella vulgaris")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Chlorella vulgaris")
  expect_equal(result$accepted_id[1L], "200001")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("AlgaeBase handles NA inputs without crashing", {
  be <- algaebase_backend()
  backbone <- mock_algaebase_backbone_vtr()
  names_df <- clean_names(c("Chlorella vulgaris", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Chlorella vulgaris")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

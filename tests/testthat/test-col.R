# ---- COL backend tests ----

# -- Backend construction --

test_that("col_backend creates correct object", {
  be <- col_backend()
  expect_s3_class(be, "taxify_col")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "col")
  expect_equal(be$version, "2025")
})


# -- Exact matching --

test_that("COL exact matching finds known species", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "5T6MX")
  expect_equal(result$genus[1L], "Quercus")
  expect_equal(result$epithet[1L], "robur")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("COL exact matching handles multiple inputs", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name, c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("COL case-insensitive matching works", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("COL unmatched names have NA match_type", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("COL exact matching finds synonyms and resolves accepted info", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "5T6MX")
})


# -- Fuzzy matching --

test_that("COL fuzzy matching catches typos", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()

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

test_that("COL fuzzy matching respects threshold", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("COL accepted info is precomputed for synonyms", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "5T6MX")
  expect_true(result$is_synonym[1L])
})

test_that("COL accepted info is self for accepted names", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "5T6MX")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("COL handles NA inputs without crashing", {
  be <- col_backend()
  backbone <- mock_col_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

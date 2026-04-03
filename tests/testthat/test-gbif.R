# ---- GBIF backend tests ----

# -- Backend construction --

test_that("gbif_backend creates correct object", {
  be <- gbif_backend()
  expect_s3_class(be, "taxify_gbif")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "gbif")
  expect_equal(be$version, "current")
})


# -- Exact matching --

test_that("GBIF exact matching finds known species", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "2878688")
  expect_equal(result$genus[1L], "Quercus")
  expect_equal(result$epithet[1L], "robur")
  expect_equal(result$family[1L], "Fagaceae")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("GBIF exact matching handles multiple inputs", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("GBIF case-insensitive matching works", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("GBIF unmatched names have NA match_type", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("GBIF exact matching finds synonyms and resolves accepted info", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
})

test_that("GBIF maps HOMOTYPIC_SYNONYM and resolves accepted", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Pinus silvestris")

  result <- match_exact(be, names_df, backbone)
  expect_equal(result$matched_name[1L], "Pinus silvestris")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_equal(result$accepted_id[1L], "5285637")
})


# -- Fuzzy matching --

test_that("GBIF fuzzy matching catches typos", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()

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

test_that("GBIF fuzzy matching respects threshold", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("GBIF accepted info is precomputed for synonyms", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
  expect_true(result$is_synonym[1L])
})

test_that("GBIF HOMOTYPIC_SYNONYM accepted info is precomputed", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Pinus silvestris")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_equal(result$accepted_id[1L], "5285637")
  expect_true(result$is_synonym[1L])
})

test_that("GBIF accepted info is self for accepted names", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, backbone)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
  expect_false(result$is_synonym[1L])
})


# -- NA handling --

test_that("GBIF handles NA inputs without crashing", {
  be <- gbif_backend()
  backbone <- mock_gbif_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, backbone)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})


# -- Status mapping --

test_that("gbif_status_to_standard maps correctly", {
  expect_equal(gbif_status_to_standard("ACCEPTED"), "ACCEPTED")
  expect_equal(gbif_status_to_standard("DOUBTFUL"), "ACCEPTED")
  expect_equal(gbif_status_to_standard("PROVISIONALLY_ACCEPTED"), "ACCEPTED")
  expect_equal(gbif_status_to_standard("SYNONYM"), "SYNONYM")
  expect_equal(gbif_status_to_standard("HOMOTYPIC_SYNONYM"), "SYNONYM")
  expect_equal(gbif_status_to_standard("HETEROTYPIC_SYNONYM"), "SYNONYM")
  expect_equal(gbif_status_to_standard("PROPARTE_SYNONYM"), "SYNONYM")
  expect_equal(gbif_status_to_standard("MISAPPLIED"), "SYNONYM")
  expect_equal(gbif_status_to_standard("AMBIGUOUS_SYNONYM"), "SYNONYM")
})

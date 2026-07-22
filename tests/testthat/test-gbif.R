# ---- GBIF vtr_path tests ----

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
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, vtr_path)
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
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name,
               c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("GBIF case-insensitive matching works", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("GBIF unmatched names have NA match_type", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, vtr_path)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("GBIF exact matching finds synonyms and resolves accepted info", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
})

test_that("GBIF maps HOMOTYPIC_SYNONYM and resolves accepted", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names("Pinus silvestris")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Pinus silvestris")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_equal(result$accepted_id[1L], "5285637")
})


# -- Fuzzy matching --

test_that("GBIF fuzzy matching catches typos", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Quercus robus")
  result <- match_exact(be, names_df, vtr_path)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, vtr_path, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("GBIF fuzzy matching respects threshold", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, vtr_path)
  result <- match_fuzzy(be, result, vtr_path, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- Precomputed accepted info --

test_that("GBIF accepted info is precomputed for synonyms", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, vtr_path)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
  expect_true(result$is_synonym[1L])
})

test_that("GBIF HOMOTYPIC_SYNONYM accepted info is precomputed", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Pinus silvestris")
  result <- match_exact(be, names_df, vtr_path)

  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_equal(result$accepted_id[1L], "5285637")
  expect_true(result$is_synonym[1L])
})

test_that("GBIF accepted info is self for accepted names", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, vtr_path)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "2878688")
  expect_false(result$is_synonym[1L])
})


# -- Backbone-specific accepted taxon (GBIF differs from COL) --
#
# GBIF's Backbone Taxonomy treats Macropus rufus / Macropus parma as the
# accepted names and Osphranter rufus / Notamacropus parma as synonyms of them;
# Catalogue of Life splits Macropus and accepts Osphranter / Notamacropus. The
# vtr_path must return GBIF's own treatment, not COL's, so these lock the
# direction of resolution. See ?taxify for the documented difference.

test_that("GBIF keeps Macropus rufus / parma as the accepted names", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  result <- match_exact(be, clean_names(c("Macropus rufus", "Macropus parma")),
                        vtr_path)
  expect_equal(result$matched_name, c("Macropus rufus", "Macropus parma"))
  expect_false(any(result$is_synonym))
  expect_equal(result$accepted_name, c("Macropus rufus", "Macropus parma"))
  expect_equal(result$accepted_id, c("5219963", "5219984"))
})

test_that("GBIF resolves Osphranter rufus to accepted Macropus rufus", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  result <- match_exact(be, clean_names("Osphranter rufus"), vtr_path)
  expect_equal(result$matched_name[1L], "Osphranter rufus")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Macropus rufus")
  expect_equal(result$accepted_id[1L], "5219963")
})

test_that("GBIF resolves Notamacropus parma to accepted Macropus parma", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()

  result <- match_exact(be, clean_names("Notamacropus parma"), vtr_path)
  expect_equal(result$matched_name[1L], "Notamacropus parma")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Macropus parma")
  expect_equal(result$accepted_id[1L], "5219984")
})


# -- NA handling --

test_that("GBIF handles NA inputs without crashing", {
  be <- gbif_backend()
  vtr_path <- mock_gbif_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

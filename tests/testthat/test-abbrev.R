# ---- Abbreviated-genus matching (e.g. "Q. robur") ----
#
# Uses the OTT/unified schema (canonical_name, taxon_id, ...) so the existing
# ott_backend() col_map drives the shared matching engine. The fixture is built
# to exercise: a unique resolution, an initial shared by two genera where the
# epithet is still unique, a genuine ambiguity (two genera with the same initial
# and epithet), an in-list disambiguation, and a synonym reached by abbreviation.

mock_abbrev_backbone_df <- function() {
  data.frame(
    taxon_id = c("1", "2", "3", "4", "5", "6", "7"),
    canonical_name = c(
      "Quercus robur", "Quercus petraea", "Pinus sylvestris",
      "Picea abies", "Abies alba", "Acer alba", "Quercus pedunculata"
    ),
    taxon_rank = rep("SPECIES", 7L),
    taxonomic_status = c(
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM"
    ),
    accepted_name_usage_id = c(NA, NA, NA, NA, NA, NA, "1"),
    family = c(
      "Fagaceae", "Fagaceae", "Pinaceae", "Pinaceae",
      "Pinaceae", "Sapindaceae", "Fagaceae"
    ),
    genus = c("Quercus", "Quercus", "Pinus", "Picea", "Abies", "Acer", "Quercus"),
    specific_epithet = c(
      "robur", "petraea", "sylvestris", "abies", "alba", "alba", "pedunculata"
    ),
    authorship = rep(NA_character_, 7L),
    infraspecific_epithet = rep(NA_character_, 7L),
    stringsAsFactors = FALSE
  )
}

mock_abbrev_backbone_vtr <- function() {
  df <- mock_abbrev_backbone_df()
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(df,
    id_col     = "taxon_id",
    acc_id_col = "accepted_name_usage_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus",
    status_col = "taxonomic_status"
  )
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}


# -- Detection in clean_names --

test_that("clean_names flags abbreviated genera", {
  df <- clean_names(c("Q. robur", "Quercus robur", "Q robur",
                      "Q.", "Quercus", "A. alba"))
  expect_equal(df$genus_abbrev,
               c(TRUE, FALSE, TRUE, FALSE, FALSE, TRUE))
})

test_that("clean_names abbreviation flag survives stripped authorship", {
  df <- clean_names("Q. robur L.")
  expect_true(df$genus_abbrev[1L])
  expect_equal(df$cleaned[1L], "Q. robur")
})

test_that("clean_names does not flag hybrids as abbreviations", {
  df <- clean_names("x Festulolium")
  expect_false(df$genus_abbrev[1L])
})


# -- Unique resolution --

test_that("abbreviated genus resolves when unique", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  names_df <- clean_names("Q. petraea")

  result <- match_exact(be, names_df, backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_abbrev_genus(be, result, names_df, backbone)
  expect_equal(result$match_type[1L], "abbrev")
  expect_equal(result$accepted_name[1L], "Quercus petraea")
  expect_equal(result$genus[1L], "Quercus")
  expect_false(isTRUE(result$is_ambiguous[1L]))
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("abbreviated genus resolves when initial is shared but epithet unique", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  # Initial P covers Pinus and Picea, but only Pinus has "sylvestris".
  names_df <- clean_names("P. sylvestris")

  result <- match_exact(be, names_df, backbone)
  result <- match_abbrev_genus(be, result, names_df, backbone)

  expect_equal(result$match_type[1L], "abbrev")
  expect_equal(result$accepted_name[1L], "Pinus sylvestris")
  expect_false(isTRUE(result$is_ambiguous[1L]))
})

test_that("abbreviated genus reaches a synonym and resolves accepted info", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  names_df <- clean_names("Q. pedunculata")

  result <- match_exact(be, names_df, backbone)
  result <- match_abbrev_genus(be, result, names_df, backbone)

  expect_equal(result$match_type[1L], "abbrev")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "1")
})


# -- Ambiguity: flag, do not guess --

test_that("abbreviated genus stays unmatched and flags ambiguity", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  # Initial A covers Abies alba and Acer alba: genuinely ambiguous.
  names_df <- clean_names("A. alba")

  result <- match_exact(be, names_df, backbone)
  result <- match_abbrev_genus(be, result, names_df, backbone)

  expect_true(is.na(result$match_type[1L]))
  expect_true(result$is_ambiguous[1L])
  expect_equal(result$ambiguous_targets[1L], "5|6")
  expect_true(is.na(result$accepted_name[1L]))
})


# -- In-list disambiguation --

test_that("a genus spelled out in the batch disambiguates the abbreviation", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  # "Abies alba" spelled out makes "A. alba" resolve to Abies, not Acer.
  names_df <- clean_names(c("Abies alba", "A. alba"))

  result <- match_exact(be, names_df, backbone)
  result <- match_abbrev_genus(be, result, names_df, backbone)

  expect_equal(result$match_type[2L], "abbrev")
  expect_equal(result$accepted_name[2L], "Abies alba")
  expect_equal(result$genus[2L], "Abies")
  expect_false(isTRUE(result$is_ambiguous[2L]))
})


# -- No candidates --

test_that("abbreviated genus with no candidate epithet stays unmatched", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  names_df <- clean_names("Z. nonexistus")

  result <- match_exact(be, names_df, backbone)
  result <- match_abbrev_genus(be, result, names_df, backbone)

  expect_true(is.na(result$match_type[1L]))
  expect_false(isTRUE(result$is_ambiguous[1L]))
})


# -- Pipeline integration --

test_that("run_match_stages handles normal and abbreviated names together", {
  be <- ott_backend()
  backbone <- mock_abbrev_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Q. petraea", "A. alba"))

  result <- run_match_stages(be, names_df, backbone,
                             fuzzy = TRUE, fuzzy_threshold = 0.2,
                             fuzzy_method = "dl")

  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$match_type[2L], "abbrev")
  expect_equal(result$accepted_name[2L], "Quercus petraea")
  expect_true(is.na(result$match_type[3L]))
  expect_true(result$is_ambiguous[3L])
})

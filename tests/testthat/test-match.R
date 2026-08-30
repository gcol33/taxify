test_that("exact matching finds known species", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names("Quercus robur")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "wfo-0000001")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("exact matching handles multiple inputs", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", "Pinus sylvestris", "Rosa canina"))

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name, c("Quercus robur", "Pinus sylvestris", "Rosa canina"))
  expect_true(all(result$match_type == "exact"))
})

test_that("case-insensitive matching works", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names("quercus robur")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "exact_ci")
})

test_that("unmatched names have NA match_type", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names("Nonexistus imaginus")

  result <- match_exact(be, names_df, vtr_path)
  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})

test_that("exact matching finds synonyms and resolves accepted info", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names("Quercus pedunculata")

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$matched_name[1L], "Quercus pedunculata")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "wfo-0000001")
})

test_that("fuzzy matching catches typos", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()

  # Start from a result where exact failed
  names_df <- clean_names("Quercus robus")
  result <- match_exact(be, names_df, vtr_path)
  expect_true(is.na(result$match_type[1L]))

  # Now fuzzy
  result <- match_fuzzy(be, result, vtr_path, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_true(!is.na(result$fuzzy_dist[1L]))
  expect_true(result$fuzzy_dist[1L] > 0)
  expect_true(result$fuzzy_dist[1L] <= 0.2)
})

test_that("fuzzy matching respects threshold", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()

  # Very different name — should not match at 0.2 threshold
  names_df <- clean_names("Zzzzzz xxxxxx")
  result <- match_exact(be, names_df, vtr_path)
  result <- match_fuzzy(be, result, vtr_path, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})

test_that("accepted info is precomputed for synonyms", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()

  names_df <- clean_names("Quercus pedunculata")
  result <- match_exact(be, names_df, vtr_path)

  expect_equal(result$accepted_name[1L], "Quercus robur")
  expect_equal(result$accepted_id[1L], "wfo-0000001")
  expect_true(result$is_synonym[1L])
})

test_that("accepted info is self for accepted names", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr()

  names_df <- clean_names("Quercus robur")
  result <- match_exact(be, names_df, vtr_path)

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
  vtr_path <- mock_backbone_vtr()
  names_df <- clean_names(c("Quercus robur", NA, ""))

  result <- match_exact(be, names_df, vtr_path)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

# ---- Homonym synonyms (Valid-filter + is_ambiguous) ----

test_that("pick_best_vec flags homonym synonyms as ambiguous (no Valid filter)", {
  # Same scientificName, three synonym rows, three different accepted IDs.
  # Without nomenclaturalStatus column, the Valid-filter cannot help —
  # ambiguity must still be reported.
  matches <- data.frame(
    row_idx           = c(1L, 1L, 1L),
    taxonID           = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus   = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank         = c("SPECIES", "SPECIES", "SPECIES"),
    accepted_taxon_id = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors  = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(nrow(best), 1L)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets,
               "wfo-0000005|wfo-0000019|wfo-0000022")
})

test_that("Valid-filter orders the pick but does not clear ambiguity", {
  # Of three synonym rows, only one is nomenclaturally Valid: it is the row the
  # scalar columns hold. The three still point at three different accepted taxa,
  # and validity is a statement about how a name was published, not about which
  # taxon it denotes — so the conflict stays reported (#53).
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Illegitimate", "Valid", "Illegitimate"),
    accepted_taxon_id   = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(best$taxonID, "wfo-0000020")
  expect_equal(best$accepted_taxon_id, "wfo-0000005")
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets,
               "wfo-0000005|wfo-0000019|wfo-0000022")
})

test_that("pick_best_vec keeps ambiguity flag when 2+ Valid rows disagree", {
  # Two of three synonym rows are Valid but point to different accepted IDs.
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-0000018", "wfo-0000020", "wfo-0000021"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Valid", "Illegitimate"),
    accepted_taxon_id   = c("wfo-0000019", "wfo-0000005", "wfo-0000022"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets,
               "wfo-0000005|wfo-0000019|wfo-0000022")
})

# ---- Status vocabulary beyond ACCEPTED/SYNONYM (issue #53) ----

test_that("an unreviewed name outranks a synonym of another species", {
  # WFO's `Prunus dulcis`: the almond is UNCHECKED (its own accepted concept),
  # while two same-string homonyms are synonyms of Prunus avium and
  # Prunus amygdalus. Scoring UNCHECKED with the synonyms returned sweet cherry.
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-1200023992", "wfo-0001005398",
                            "wfo-0000996162"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "UNCHECKED"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Illegitimate", NA_character_),
    is_synonym          = c(TRUE, TRUE, FALSE),
    matched_name_std    = rep("Prunus dulcis", 3L),
    accepted_name       = c("Prunus avium", "Prunus amygdalus", "Prunus dulcis"),
    accepted_taxon_id   = c("wfo-0001006607", "wfo-0001015846",
                            "wfo-0000996162"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(best$taxonID, "wfo-0000996162")
  expect_equal(best$accepted_name, "Prunus dulcis")
  # UNCHECKED is the backbone declining to place the name, not a resolution, so
  # the two records that do place it elsewhere are still reported.
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets,
               "wfo-0000996162|wfo-0001006607|wfo-0001015846")
})

test_that("status_score_vec ranks the backbone status vocabularies", {
  # Accepted, then a name the backbone keeps but has not placed, then a
  # synonym, then a misapplication.
  expect_equal(
    status_score_vec(c("ACCEPTED", "Accepted", "PROVISIONALLY ACCEPTED",
                       "UNCHECKED", "SYNONYM", "HETEROTYPIC_SYNONYM",
                       "AMBIGUOUS SYNONYM", "MISAPPLIED")),
    c(0L, 0L, 1L, 1L, 2L, 2L, 3L, 3L)
  )
  # An unrecognized status falls through to the backbone's own synonym flag.
  expect_equal(status_score_vec(c("weird", "weird"), c(TRUE, FALSE)),
               c(2L, 1L))
  # The flag clamps a contradictory status either way.
  expect_equal(status_score_vec(c("ACCEPTED", "SYNONYM"), c(TRUE, FALSE)),
               c(2L, 1L))
  # No flag column at all: the vocabulary alone decides.
  expect_equal(status_score_vec("UNCHECKED", NULL), 1L)
})

test_that("two synonyms of different species stay ambiguous under a Valid split", {
  # WFO's `Rubus laciniatus`: a Valid record sinking it into Rubus ulmifolius
  # and an Illegitimate one into Rubus nemoralis. Neither keeps the epithet, so
  # the concept tier ties and the conflict must be reported.
  matches <- data.frame(
    row_idx             = c(1L, 1L),
    taxonID             = c("wfo-1000060367", "wfo-0000984132"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Illegitimate"),
    is_synonym          = c(TRUE, TRUE),
    matched_name_std    = rep("Rubus laciniatus", 2L),
    accepted_name       = c("Rubus ulmifolius", "Rubus nemoralis"),
    accepted_taxon_id   = c("wfo-0000985000", "wfo-0001012948"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(best$taxonID, "wfo-1000060367")
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets, "wfo-0000985000|wfo-0001012948")
})

#' Build a WFO-shaped .vtr holding the issue #53 rows
#'
#' Reproduces the real WFO records for `Prunus dulcis` (an UNCHECKED almond plus
#' two homonym synonyms of other species) and `Rubus laciniatus` (two synonyms
#' of different species split only by nomenclatural validity), so the regression
#' runs offline.
#' @noRd
issue53_backbone_vtr <- function() {
  df <- data.frame(
    taxon_id = c("wfo-0000996162", "wfo-0001005398", "wfo-1200023992",
                 "wfo-0001015846", "wfo-0001006607",
                 "wfo-0000984132", "wfo-1000060367",
                 "wfo-0001012948", "wfo-0000985000"),
    canonical_name = c("Prunus dulcis", "Prunus dulcis", "Prunus dulcis",
                       "Prunus amygdalus", "Prunus avium",
                       "Rubus laciniatus", "Rubus laciniatus",
                       "Rubus nemoralis", "Rubus ulmifolius"),
    taxon_rank = rep("SPECIES", 9L),
    taxonomic_status = c("UNCHECKED", "SYNONYM", "SYNONYM",
                         "ACCEPTED", "ACCEPTED",
                         "SYNONYM", "SYNONYM",
                         "ACCEPTED", "ACCEPTED"),
    accepted_name_usage_id = c(NA, "wfo-0001015846", "wfo-0001006607",
                               NA, NA,
                               "wfo-0001012948", "wfo-0000985000",
                               NA, NA),
    family = rep("Rosaceae", 9L),
    genus = c(rep("Prunus", 5L), rep("Rubus", 4L)),
    specific_epithet = c("dulcis", "dulcis", "dulcis", "amygdalus", "avium",
                         "laciniatus", "laciniatus", "nemoralis", "ulmifolius"),
    authorship = c("(Mill.) Rchb.", "(Mill.) D.A.Webb", "Rouchy",
                   "Batsch", "L.",
                   "Willd.", "(Weston) Tollard",
                   "P.J.Mull.", "Schott"),
    infraspecific_epithet = rep(NA_character_, 9L),
    nomenclaturalStatus = c(NA, "Illegitimate", "Valid", NA, NA,
                            "Illegitimate", "Valid", NA, NA),
    stringsAsFactors = FALSE
  )
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(df, id_col = "taxon_id",
                       acc_id_col = "accepted_name_usage_id",
                       name_col = "canonical_name", family_col = "family",
                       genus_col = "genus", status_col = "taxonomic_status",
                       authorship_col = "authorship")
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

test_that("an unreviewed accepted record wins over a synonym of another species", {
  # #53: `Prunus dulcis` returned `Prunus avium` because WFO files the almond
  # as UNCHECKED, which scored level with the two homonym synonyms, and the
  # nomenclatural-validity tiebreak then picked the Valid one.
  be  <- wfo_backend()
  bb  <- issue53_backbone_vtr()
  res <- match_exact(be, clean_names("Prunus dulcis"), bb)

  expect_equal(res$taxon_id[1L], "wfo-0000996162")
  expect_equal(res$accepted_name[1L], "Prunus dulcis")
  expect_false(res$is_synonym[1L])
  # The almond's own record wins, and the two homonyms that place the name on
  # other species are reported rather than dropped.
  expect_true(res$is_ambiguous[1L])
  expect_equal(res$ambiguous_targets[1L],
               "wfo-0000996162|wfo-0001006607|wfo-0001015846")
})

test_that("two synonyms of different species are reported, not silently picked", {
  # #53: `Rubus laciniatus` returned `Rubus ulmifolius` with is_ambiguous FALSE.
  be  <- wfo_backend()
  bb  <- issue53_backbone_vtr()
  res <- match_exact(be, clean_names("Rubus laciniatus"), bb)

  expect_true(res$is_ambiguous[1L])
  expect_equal(res$ambiguous_targets[1L], "wfo-0000985000|wfo-0001012948")
})

test_that("a query author picks the record it names", {
  be <- wfo_backend()
  bb <- issue53_backbone_vtr()
  q  <- c("Prunus dulcis (Mill.) Rchb.", "Prunus dulcis (Mill.) D.A.Webb",
          "Prunus dulcis Rouchy", "Rubus laciniatus Willd.",
          "Rubus laciniatus (Weston) Tollard")
  res <- disambiguate_by_authorship(
    match_exact(be, clean_names(q), bb), bb)

  expect_equal(res$taxon_id,
               c("wfo-0000996162", "wfo-0001005398", "wfo-1200023992",
                 "wfo-0000984132", "wfo-1000060367"))
  expect_equal(res$accepted_name,
               c("Prunus dulcis", "Prunus amygdalus", "Prunus avium",
                 "Rubus nemoralis", "Rubus ulmifolius"))
  expect_false(any(res$is_ambiguous))
})


# ---- Epithet-preservation tiebreak (basionym disambiguation, issue #2) ----

test_that("pick_best_vec prefers the epithet-preserving accepted target", {
  # Three Valid 'Pinus abies' homonym synonyms pointing to three different
  # accepted taxa. Only one keeps the specific epithet ('abies' -> Picea
  # abies): that homotypic basionym wins and the group is no longer ambiguous.
  matches <- data.frame(
    row_idx             = c(1L, 1L, 1L),
    taxonID             = c("wfo-0000482549", "wfo-0000482550",
                            "wfo-0000482551"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Valid", "Valid"),
    matched_name_std    = c("Pinus abies", "Pinus abies", "Pinus abies"),
    accepted_name       = c("Picea polita", "Abies alba", "Picea abies"),
    accepted_taxon_id   = c("wfo-0000482612", "wfo-0000510976",
                            "wfo-0000482030"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_equal(best$accepted_name, "Picea abies")
  expect_equal(best$accepted_taxon_id, "wfo-0000482030")
  expect_false(best$is_ambiguous)
  expect_true(is.na(best$ambiguous_targets))
})

test_that("pick_best_vec stays ambiguous when no candidate preserves epithet", {
  # 'Picea excelsa' -> {Picea abies, Abies alba}: neither keeps 'excelsa',
  # so the pick is genuinely ambiguous (epithet rule does not apply).
  matches <- data.frame(
    row_idx             = c(1L, 1L),
    taxonID             = c("wfo-a", "wfo-b"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Valid"),
    matched_name_std    = c("Picea excelsa", "Picea excelsa"),
    accepted_name       = c("Picea abies", "Abies alba"),
    accepted_taxon_id   = c("wfo-0000482030", "wfo-0000510976"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets, "wfo-0000482030|wfo-0000510976")
})

test_that("pick_best_vec stays ambiguous when 2+ candidates preserve epithet", {
  # Two different accepted taxa both keep the epithet -> still ambiguous.
  matches <- data.frame(
    row_idx             = c(1L, 1L),
    taxonID             = c("wfo-1", "wfo-2"),
    taxonomicStatus     = c("SYNONYM", "SYNONYM"),
    taxonRank           = c("SPECIES", "SPECIES"),
    nomenclaturalStatus = c("Valid", "Valid"),
    matched_name_std    = c("Aus bus", "Aus bus"),
    accepted_name       = c("Xus bus", "Yus bus"),
    accepted_taxon_id   = c("wfo-1", "wfo-2"),
    stringsAsFactors    = FALSE
  )
  best <- pick_best_vec(matches)
  expect_true(best$is_ambiguous)
  expect_equal(best$ambiguous_targets, "wfo-1|wfo-2")
})

test_that("pick_best applies the epithet-preserving tiebreak", {
  candidates <- data.frame(
    taxonID           = c("wfo-0000482549", "wfo-0000482551"),
    taxonomicStatus   = c("SYNONYM", "SYNONYM"),
    taxonRank         = c("SPECIES", "SPECIES"),
    matched_name_std  = c("Pinus abies", "Pinus abies"),
    accepted_name     = c("Picea polita", "Picea abies"),
    accepted_taxon_id = c("wfo-0000482612", "wfo-0000482030"),
    stringsAsFactors  = FALSE
  )
  best <- pick_best(candidates)
  expect_equal(best$accepted_taxon_id, "wfo-0000482030")
  expect_false(best$is_ambiguous)
})

test_that("epithet_key extracts and normalizes the specific epithet", {
  expect_equal(epithet_key("Pinus abies"), "abies")
  expect_equal(epithet_key("Picea abies"), "abies")
  expect_equal(epithet_key("Quercus robur subsp. robur"), "robur")
  expect_true(is.na(epithet_key("Pinus")))
  expect_true(is.na(epithet_key(NA_character_)))
  # Orthographic folding matches the matcher: 'ae' -> 'i'.
  expect_equal(epithet_key("Genus caeruleus"), epithet_key("Genus ciruleus"))
})

test_that("case-tolerant ACCEPTED detection (Accepted vs ACCEPTED)", {
  # Real WFO data uses 'Accepted' / 'Synonym' (mixed case), the mock fixture
  # uses 'ACCEPTED' / 'SYNONYM'. Both must work.
  for (lab_acc in c("Accepted", "ACCEPTED")) {
    for (lab_syn in c("Synonym", "SYNONYM")) {
      candidates <- data.frame(
        taxonID = c("wfo-x", "wfo-y"),
        taxonomicStatus = c(lab_syn, lab_acc),
        taxonRank = c("SPECIES", "SPECIES"),
        stringsAsFactors = FALSE
      )
      best <- pick_best(candidates)
      expect_equal(best$taxonID, "wfo-y",
                   info = sprintf("acc=%s, syn=%s", lab_acc, lab_syn))
    }
  }
})

test_that("end-to-end: WFO mock with nom_status disambiguates Pinus abies", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr(with_nom_status = TRUE)
  names_df <- clean_names("Pinus abies")

  result <- match_exact(be, names_df, vtr_path)
  # Of three synonym rows, two are Valid (Thunb. → Picea polita,
  # L. → Pinus sylvestris). One is Illegitimate. Two Valid rows disagree →
  # is_ambiguous should be TRUE.
  expect_equal(result$match_type[1L], "exact")
  expect_true(result$is_synonym[1L])
  expect_true(result$is_ambiguous[1L])
  expect_match(result$ambiguous_targets[1L], "wfo-0000005")
  expect_match(result$ambiguous_targets[1L], "wfo-0000019")
})

test_that("vtr_path without nomenclaturalStatus still reports ambiguity", {
  be <- wfo_backend()
  vtr_path <- mock_backbone_vtr(with_nom_status = FALSE)
  names_df <- clean_names("Pinus abies")
  result <- match_exact(be, names_df, vtr_path)
  expect_equal(result$match_type[1L], "exact")
  expect_true(result$is_ambiguous[1L])
  expect_match(result$ambiguous_targets[1L], "\\|")
})

# ---- Fuzzy uniqueness: dedup_fuzzy_targets ----

test_that("dedup_fuzzy_targets keeps only closest query per target", {
  # Three distinct queries fuzzy-mapped to the same vtr_path row, the second
  # being closest. Only the second should survive.
  best <- data.frame(
    row_idx    = c(1L, 2L, 3L),
    taxonID    = c("wfo-x", "wfo-x", "wfo-x"),
    fuzzy_dist = c(0.2, 0.1, 0.3),
    stringsAsFactors = FALSE
  )
  out <- dedup_fuzzy_targets(best, id_col = "taxonID")
  expect_equal(nrow(out), 1L)
  expect_equal(out$row_idx, 2L)
})

test_that("dedup_fuzzy_targets preserves exact (distance = 0) hits", {
  # Two queries hit the same target — one with distance 0 (exact synonym
  # pointing to same accepted), one with distance 0.1 (fuzzy). The exact one
  # is genuine and must be kept; the fuzzy one over the same target should be
  # filtered as a spurious collapse.
  best <- data.frame(
    row_idx    = c(1L, 2L),
    taxonID    = c("wfo-x", "wfo-x"),
    fuzzy_dist = c(0.0, 0.1),
    stringsAsFactors = FALSE
  )
  out <- dedup_fuzzy_targets(best, id_col = "taxonID")
  expect_equal(nrow(out), 1L)
  expect_equal(out$row_idx, 1L)
})

test_that("dedup_fuzzy_targets is a no-op for distinct targets", {
  best <- data.frame(
    row_idx    = c(1L, 2L, 3L),
    taxonID    = c("wfo-a", "wfo-b", "wfo-c"),
    fuzzy_dist = c(0.1, 0.2, 0.3),
    stringsAsFactors = FALSE
  )
  expect_equal(dedup_fuzzy_targets(best, id_col = "taxonID"), best)
})

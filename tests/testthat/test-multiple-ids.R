# Names filed under several accepted IDs: the occurrence-count pick, the
# n_ids / accepted_ids columns, and the one-per-call warning. The fixture
# mirrors three GBIF cases checked against the live API on 2026-09-22:
#   Karwinskia mollis  Schltdl. ACCEPTED, 663 records; Standl. DOUBTFUL, 0
#   Houstonia pusilla  Schoepf ACCEPTED, 14,947 records; J.F.Gmel. synonym of
#                      H. caerulea, 9 records (35,385 under H. caerulea)
#   Cotoneaster roylei K.Koch DOUBTFUL, 0; Hook.fil. synonym of
#                      C. acuminatus, 0 (952 under C. acuminatus)

gbif_like_vtr <- function(with_counts = TRUE) {
  df <- data.frame(
    taxon_id = c("3875069", "11399973",
                 "5338804", "8078486", "5338866",
                 "9485683", "9337343", "3025566"),
    canonical_name = c("Karwinskia mollis", "Karwinskia mollis",
                       "Houstonia pusilla", "Houstonia pusilla",
                       "Houstonia caerulea",
                       "Cotoneaster roylei", "Cotoneaster roylei",
                       "Cotoneaster acuminatus"),
    taxon_rank = rep("SPECIES", 8L),
    taxonomic_status = c("ACCEPTED", "DOUBTFUL",
                         "ACCEPTED", "SYNONYM", "ACCEPTED",
                         "DOUBTFUL", "SYNONYM", "ACCEPTED"),
    accepted_name_usage_id = c(NA, NA, NA, "5338866", NA, NA, "3025566", NA),
    family = c("Rhamnaceae", "Rhamnaceae", rep("Rubiaceae", 3L),
               rep("Rosaceae", 3L)),
    genus = c("Karwinskia", "Karwinskia", rep("Houstonia", 3L),
              rep("Cotoneaster", 3L)),
    specific_epithet = c("mollis", "mollis", "pusilla", "pusilla", "caerulea",
                         "roylei", "roylei", "acuminatus"),
    authorship = c("Schltdl.", "Standl.", "Schoepf", "J.F.Gmel.", "L.",
                   "K.Koch", "Hook.fil.", "Lindl."),
    infraspecific_epithet = rep(NA_character_, 8L),
    stringsAsFactors = FALSE
  )
  if (with_counts) {
    df$n_occurrences <- c(663, 0, 14947, 9, 35385, 0, 0, 952)
  }
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

pick_frame <- function(...) {
  data.frame(row_idx = 1L, taxonRank = "SPECIES", ..., stringsAsFactors = FALSE)
}


# ---- the occurrence-count ordering ----

test_that("the key with occurrence records beats an empty one of the same name", {
  # Karwinskia mollis: status alone would also pick the accepted record here;
  # the empty key loses even when it sorts first on taxonID.
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "ACCEPTED"),
                  accepted_taxon_id = c("1", "2"),
                  n_occurrences = c(0, 663))
  best <- pick_best_vec(m)
  expect_equal(best$taxonID, "2")
  expect_equal(best$n_ids, 2L)
  expect_equal(best$accepted_ids, "2|1")
})

test_that("records outrank status among the name's own keys", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "DOUBTFUL"),
                  accepted_taxon_id = c("1", "2"),
                  n_occurrences = c(0, 25))
  expect_equal(pick_best_vec(m)$taxonID, "2")
})

test_that("a synonym key with data never displaces the name's own empty key", {
  # Rosa capreolata: the accepted key has 0 records, a synonym record of the
  # same name 1; its accepted ID is Rosa arvensis, whose data a download by
  # that ID would return.
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "SYNONYM"),
                  accepted_taxon_id = c("1", "9"),
                  n_occurrences = c(0, 1))
  best <- pick_best_vec(m)
  expect_equal(best$accepted_taxon_id, "1")
  expect_equal(best$accepted_ids, "1|9")
})

test_that("between two empty keys status decides", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "DOUBTFUL"),
                  accepted_taxon_id = c("9", "2"),
                  n_occurrences = c(0, 0))
  expect_equal(pick_best_vec(m)$taxonID, "2")
})

test_that("between two keys with records status decides, not the count", {
  # Houstonia pusilla: the accepted key keeps the name although the synonym
  # key of another species could carry more records.
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "ACCEPTED"),
                  accepted_taxon_id = c("9", "2"),
                  n_occurrences = c(5000, 1))
  expect_equal(pick_best_vec(m)$taxonID, "2")
})

test_that("the count breaks a tie the concept scores leave", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "ACCEPTED"),
                  accepted_taxon_id = c("1", "2"),
                  n_occurrences = c(3, 40))
  expect_equal(pick_best_vec(m)$taxonID, "2")
})

test_that("the earliest of two same-name homonyms wins before the count", {
  # Absinthium vulgare: Lam. (1779) -> Artemisia absinthium, 0 records;
  # Dulac (1867) -> Artemisia vulgaris subsp. vulgaris, 17 records.
  m <- pick_frame(taxonID = c("8159978", "3121326"),
                  taxonomicStatus = c("SYNONYM", "SYNONYM"),
                  accepted_taxon_id = c("vulg", "absin"),
                  n_occurrences = c(17, 0),
                  year = c(NA, NA),
                  name_published_in = c("Dulac. (1867). In: Fl. Hautes-Pyr. 502.",
                                        "Lam. (1779). In: Fl. Franc. 2: 45."))
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "absin")
})

test_that("the year is silent for animal names, where usage prevails", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "SYNONYM"),
                  accepted_taxon_id = c("early", "used"),
                  kingdom = c("Animalia", "Animalia"),
                  year = c("1836", "1839"),
                  n_occurrences = c(1, 3))
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "used")
  m$kingdom <- c("Fungi", "Fungi")
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "early")
})

test_that("the year is silent between homonyms of different kingdoms", {
  # Padia: Gistl 1848 (animal) and Moritzi 1854 (plant, synonym of Oryza);
  # priority does not cross codes, so the count decides.
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "SYNONYM"),
                  accepted_taxon_id = c("gerania", "oryza"),
                  kingdom = c("Animalia", "Plantae"),
                  year = c("1848", "1854"),
                  n_occurrences = c(0, 3))
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "oryza")
  # Both plants: the earlier name wins although it has no records.
  m$kingdom <- c("Plantae", "Plantae")
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "gerania")
})

test_that("a recombination is dated by its basionym", {
  # Rhus hirta (L.) Sudw. dates from Linnaeus, not from the 1892 combination,
  # so it predates the 1883 Rhus hirta Harv. ex Engl. it is compared with.
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "SYNONYM"),
                  accepted_taxon_id = c("typhina", "swintonia"),
                  kingdom = c("Plantae", "Plantae"),
                  year = c("1892", "1883"),
                  bracket_year = c("1756", NA),
                  bracket_authorship = c("L.", NA),
                  n_occurrences = c(1284, 26))
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "typhina")

})

test_that("an undated record sorts after a dated one", {
  expect_equal(publication_year(c("1805", NA, NA),
                                c(NA, "Traite Arbr. 1: 3 (1755)", "no year")),
               c(1805L, 1755L, NA))
  expect_equal(publication_year("1892", NA, "1756"), 1756L)
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "SYNONYM"),
                  accepted_taxon_id = c("a", "b"),
                  kingdom = c("Plantae", "Plantae"),
                  year = c(NA, "1900"),
                  n_occurrences = c(12, 3))
  expect_equal(pick_best_vec(m)$accepted_taxon_id, "b")
})

test_that("a missing count is no evidence of records", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "SYNONYM"),
                  accepted_taxon_id = c("1", "9"),
                  n_occurrences = c(NA, 0))
  expect_equal(pick_best_vec(m)$taxonID, "1")
})

test_that("a missing count sorts after every known count, not level with zero", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("ACCEPTED", "ACCEPTED"),
                  accepted_taxon_id = c("1", "2"),
                  n_occurrences = c(NA, 0))
  expect_equal(pick_best_vec(m)$taxonID, "2")
})

test_that("a backbone without counts picks as before", {
  m <- pick_frame(taxonID = c("1", "2"),
                  taxonomicStatus = c("SYNONYM", "ACCEPTED"),
                  accepted_taxon_id = c("9", "2"))
  best <- pick_best_vec(m)
  expect_equal(best$taxonID, "2")
  expect_equal(best$accepted_ids, "2|9")
})


# ---- end to end on a GBIF-shaped backbone ----

test_that("match_exact picks the key GBIF files the data under", {
  be  <- gbif_backend()
  bb  <- gbif_like_vtr()
  res <- match_exact(be, clean_names(c("Karwinskia mollis", "Houstonia pusilla",
                                       "Cotoneaster roylei")), bb)

  # The Standl. key has no records; the Schltdl. one has 663.
  expect_equal(res$accepted_id[1L], "3875069")
  # The accepted Schoepf name keeps the pick over the 9-record Gmelin homonym,
  # although the taxon that homonym sinks into has more records in total.
  expect_equal(res$accepted_id[2L], "5338804")
  expect_equal(res$accepted_name[2L], "Houstonia pusilla")
  # Both Cotoneaster roylei keys are empty, so status decides: the doubtful
  # record keeps the name.
  expect_equal(res$accepted_id[3L], "9485683")

  expect_equal(res$n_ids, c(2L, 2L, 2L))
  expect_equal(res$accepted_ids,
               c("3875069|11399973", "5338804|5338866", "9485683|3025566"))
})

test_that("without counts the doubtful status still loses to accepted", {
  be  <- gbif_backend()
  bb  <- gbif_like_vtr(with_counts = FALSE)
  res <- match_exact(be, clean_names("Karwinskia mollis"), bb)
  expect_equal(res$accepted_id, "3875069")
})


# ---- the warning, the summary line, taxify_ids() ----

with_gbif_like <- function(code, with_counts = TRUE) {
  vtr <- gbif_like_vtr(with_counts)
  dd <- tempfile("dd_gbif_like_")
  dir.create(file.path(dd, "gbif", "latest"), recursive = TRUE)
  file.copy(vtr, file.path(dd, "gbif", "latest", "gbif.vtr"))
  withr::local_options(list(taxify.data_dir = dd))
  set_backbone_path("gbif", vtr)
  withr::defer(set_backbone_path("gbif", NULL))
  prev <- .taxify_env[[".version_checked.gbif"]]
  .taxify_env[[".version_checked.gbif"]] <- TRUE
  withr::defer(assign(".version_checked.gbif", prev, envir = .taxify_env))
  force(code)
}

test_that("taxify() warns once per call when names have several accepted IDs", {
  with_gbif_like({
    w <- NULL
    res <- withCallingHandlers(
      taxify(c("Karwinskia mollis", "Houstonia caerulea", "Houstonia pusilla"),
             backbone = "gbif", fuzzy = FALSE, verbose = FALSE),
      taxify_multiple_ids = function(cond) {
        w <<- c(w, list(cond))
        invokeRestart("muffleWarning")
      })
    expect_length(w, 1L)
    expect_equal(w[[1L]]$rows, c(1L, 3L))
    expect_match(conditionMessage(w[[1L]]), "2 of 3 names")
    expect_match(conditionMessage(w[[1L]]), "taxify_ids")
    expect_equal(res$n_ids, c(2L, 1L, 2L))
  })
})

test_that("the warning can be switched off, and is silent without multiple IDs", {
  with_gbif_like({
    withr::local_options(list(taxify.warn_multiple_ids = FALSE))
    expect_no_warning(taxify("Karwinskia mollis", backbone = "gbif",
                             fuzzy = FALSE, verbose = FALSE))
  })
  with_gbif_like({
    expect_no_warning(taxify("Houstonia caerulea", backbone = "gbif",
                             fuzzy = FALSE, verbose = FALSE))
  })
})

test_that("verbs built on taxify() do not repeat the warning", {
  with_gbif_like({
    expect_no_warning(
      rec <- reconcile(c("Karwinskia mollis", "Cotoneaster roylei"),
                       backbone = "gbif", fuzzy = FALSE, verbose = FALSE))
    # Both resolve to themselves as accepted, so the homonym record leaves
    # the verdict unchanged; n_ids shows it exists.
    expect_equal(rec$status, c("unchanged", "unchanged"))
    expect_equal(rec$n_ids, c(2L, 2L))
  })
})

test_that("summary() counts the names with several accepted IDs", {
  with_gbif_like({
    res <- suppressWarnings(
      taxify(c("Karwinskia mollis", "Houstonia caerulea"), backbone = "gbif",
             fuzzy = FALSE, verbose = FALSE),
      classes = "taxify_multiple_ids")
    out <- capture.output(summary(res))
    expect_true(any(grepl("multiple ids\\s+1", out)))
  })
})

test_that("taxify_ids() lists each ID with its status and occurrence count", {
  with_gbif_like({
    res <- suppressWarnings(
      taxify(c("Karwinskia mollis", "Houstonia pusilla"), backbone = "gbif",
             fuzzy = FALSE, verbose = FALSE),
      classes = "taxify_multiple_ids")
    ids <- taxify_ids(res, verbose = FALSE)
    expect_equal(ids$input_name, rep(c("Karwinskia mollis", "Houstonia pusilla"),
                                     each = 2L))
    expect_equal(ids$accepted_id,
                 c("3875069", "11399973", "5338804", "5338866"))
    expect_equal(ids$accepted_name,
                 c("Karwinskia mollis", "Karwinskia mollis",
                   "Houstonia pusilla", "Houstonia caerulea"))
    expect_equal(ids$authorship, c("Schltdl.", "Standl.", "Schoepf", "L."))
    expect_equal(ids$taxonomic_status,
                 c("ACCEPTED", "DOUBTFUL", "ACCEPTED", "ACCEPTED"))
    expect_equal(ids$n_occurrences, c(663, 0, 14947, 35385))
    expect_equal(ids$is_pick, c(TRUE, FALSE, TRUE, FALSE))
    expect_equal(ids$gbif_key, ids$accepted_id)
  })
})

test_that("taxify_ids() reads gbif_key from a backbone that carries a crosswalk", {
  path <- tempfile(fileext = ".vtr")
  vectra::write_vtr(data.frame(
    taxon_id         = c("4R5YN", "SFTX6", "9ZZZZ"),
    canonical_name   = c("Quercus robur", "Quercus robur", "Newus novus"),
    authorship       = c("L.", "Asso", "Nov."),
    taxon_rank       = "SPECIES",
    taxonomic_status = "ACCEPTED",
    family           = c("Fagaceae", "Fagaceae", "Fagaceae"),
    gbif_key         = c("2878688", "7911626|8206510", NA),
    stringsAsFactors = FALSE
  ), path)
  local_mocked_bindings(backbone_path = function(...) path)
  x <- data.frame(input_name = c("Quercus robur", "Newus novus"),
                  backbone = "colxr", accepted_id = c("4R5YN", "9ZZZZ"),
                  accepted_ids = c("4R5YN|SFTX6", NA_character_),
                  stringsAsFactors = FALSE)
  ids <- taxify_ids(x, verbose = FALSE)
  expect_equal(ids$accepted_id, c("4R5YN", "SFTX6", "9ZZZZ"))
  expect_equal(ids$gbif_key, c("2878688", "7911626|8206510", NA))
})

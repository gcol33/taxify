# Unplaced records (#81): the backbone status travels with the result, an
# unplaced combination resolves through its basionym, and a homotypic synonym
# record of a name is picked over an unplaced homonym of it.

#' A WFO-shaped .vtr holding the issue #81 records
#'
#' The WFO rows the issue reports: the two *polystachya* combinations whose
#' shared basionym *Polygonum polystachyum* is a synonym of *Persicaria
#' wallichii*, *Sabulina tenuifolia* against *Minuartia hybrida*, and the two
#' *Lycopsis orientalis* homonyms. The basionym links are the relations the
#' issue describes. `Testia alpha` is an unplaced combination whose basionym is
#' itself unplaced.
#'
#' @param with_basionym Logical. `FALSE` builds the table without the
#'   `original_name_usage_id` column, as a backbone published before the column
#'   existed.
#' @noRd
issue81_backbone_vtr <- function(with_basionym = TRUE) {
  df <- data.frame(
    taxon_id = c("wfo-1200027062", "wfo-0001272128", "wfo-0000489108",
                 "wfo-0000488252",
                 "wfo-0000438413", "wfo-0000546761", "wfo-0000374756",
                 "wfo-0001327831", "wfo-0000358417", "wfo-0000533555",
                 "test-1", "test-2"),
    canonical_name = c("Koenigia polystachya", "Rubrivena polystachya",
                       "Polygonum polystachyum", "Persicaria wallichii",
                       "Sabulina tenuifolia", "Arenaria tenuifolia",
                       "Minuartia hybrida",
                       "Lycopsis orientalis", "Lycopsis orientalis",
                       "Anchusa arvensis subsp. orientalis",
                       "Testia alpha", "Probia alpha"),
    taxon_rank = c(rep("SPECIES", 9L), "SUBSPECIES", "SPECIES", "SPECIES"),
    taxonomic_status = c("UNCHECKED", "UNCHECKED", "SYNONYM", "ACCEPTED",
                         "UNCHECKED", "SYNONYM", "ACCEPTED",
                         "UNCHECKED", "SYNONYM", "ACCEPTED",
                         "UNCHECKED", "UNCHECKED"),
    accepted_name_usage_id = c(NA, NA, "wfo-0000488252", NA,
                               NA, "wfo-0000374756", NA,
                               NA, "wfo-0000533555", NA,
                               NA, NA),
    family = c(rep("Polygonaceae", 4L), rep("Caryophyllaceae", 3L),
               rep("Boraginaceae", 3L), "Testaceae", "Testaceae"),
    genus = c("Koenigia", "Rubrivena", "Polygonum", "Persicaria",
              "Sabulina", "Arenaria", "Minuartia",
              "Lycopsis", "Lycopsis", "Anchusa", "Testia", "Probia"),
    specific_epithet = c("polystachya", "polystachya", "polystachyum",
                         "wallichii", "tenuifolia", "tenuifolia", "hybrida",
                         "orientalis", "orientalis", "arvensis",
                         "alpha", "alpha"),
    authorship = c("(Wall. ex Meisn.) T.M.Schust. & Reveal",
                   "(Wall. ex Meisn.) M.Král", "Wall. ex Meisn.",
                   "Greuter & Burdet",
                   "(L.) Rchb.", "L.", "(Vill.) Schischk.",
                   "Steph.", "L.", "(L.) Nordh.",
                   "(Foo) Bar", "Foo"),
    infraspecific_epithet = c(rep(NA, 9L), "orientalis", NA, NA),
    original_name_usage_id = c("wfo-0000489108", "wfo-0000489108", NA, NA,
                               "wfo-0000546761", NA, NA,
                               NA, NA, "wfo-0000358417",
                               "test-2", NA),
    stringsAsFactors = FALSE
  )
  if (!with_basionym) df$original_name_usage_id <- NULL
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

issue81_taxify <- function(x, with_basionym = TRUE) {
  bb <- issue81_backbone_vtr(with_basionym)
  dd <- tempfile("dd_issue81_")
  dir.create(file.path(dd, "wfo", "latest"), recursive = TRUE)
  file.copy(bb, file.path(dd, "wfo", "latest", "wfo.vtr"))
  withr::local_options(list(taxify.data_dir = dd))
  set_backbone_path("wfo", bb)
  on.exit(set_backbone_path("wfo", NULL), add = TRUE)
  # The fixture keeps two Lycopsis orientalis records on purpose.
  as.data.frame(suppressWarnings(
    taxify(x, backbone = "wfo", fuzzy = FALSE, verbose = FALSE),
    classes = "taxify_multiple_ids"))
}

issue81_names <- c("Koenigia polystachya", "Rubrivena polystachya",
                   "Minuartia hybrida", "Sabulina tenuifolia",
                   "Lycopsis orientalis")


test_that("the result carries the backbone's own status", {
  res <- issue81_taxify(c(issue81_names, "Persicaria wallichii",
                          "Arenaria tenuifolia", "Notagenus nullus"))
  expect_equal(res$taxonomic_status,
               c("UNCHECKED", "UNCHECKED", "ACCEPTED", "UNCHECKED", "SYNONYM",
                 "ACCEPTED", "SYNONYM", NA))
  # Lycopsis orientalis has two accepted IDs, so the result also carries the
  # columns an empty result leaves out.
  expect_identical(setdiff(names(res), c("n_ids", "accepted_ids")),
                   names(empty_taxify_result("wfo")))
  expect_true(all(c("n_ids", "accepted_ids") %in% names(res)))
})

test_that("an unplaced combination resolves to where its basionym is placed", {
  res <- issue81_taxify(issue81_names)

  expect_equal(res$accepted_name,
               c("Persicaria wallichii", "Persicaria wallichii",
                 "Minuartia hybrida", "Minuartia hybrida",
                 "Anchusa arvensis subsp. orientalis"))
  expect_equal(res$accepted_id,
               c("wfo-0000488252", "wfo-0000488252", "wfo-0000374756",
                 "wfo-0000374756", "wfo-0000533555"))
  expect_equal(res$match_type,
               c("basionym", "basionym", "exact", "basionym", "exact"))
  expect_equal(res$is_synonym, c(TRUE, TRUE, FALSE, TRUE, TRUE))

  # The matched record is still the unplaced one, and says so.
  expect_equal(res$taxon_id[1:2], c("wfo-1200027062", "wfo-0001272128"))
  expect_equal(res$matched_name[4L], "Sabulina tenuifolia")
  expect_equal(res$authorship[4L], "(L.) Rchb.")
  expect_equal(res$accepted_authorship[4L], "(Vill.) Schischk.")
  expect_equal(res$family[4L], "Caryophyllaceae")
  expect_equal(res$genus[4L], "Minuartia")
  expect_equal(res$backbone, rep("wfo", 5L))
})

test_that("an unplaced basionym settles nothing", {
  res <- issue81_taxify("Testia alpha")
  expect_equal(res$accepted_name, "Testia alpha")
  expect_equal(res$match_type, "exact")
  expect_false(res$is_synonym)
  expect_equal(res$taxonomic_status, "UNCHECKED")
})

test_that("a backbone without basionym links leaves unplaced records as matched", {
  res <- issue81_taxify(issue81_names, with_basionym = FALSE)
  expect_equal(res$accepted_name[c(1L, 2L, 4L)],
               c("Koenigia polystachya", "Rubrivena polystachya",
                 "Sabulina tenuifolia"))
  expect_equal(res$match_type[c(1L, 2L, 4L)], rep("exact", 3L))
  expect_equal(res$taxonomic_status[c(1L, 2L, 4L)], rep("UNCHECKED", 3L))
})

test_that("a homotypic synonym record is picked over an unplaced homonym", {
  res <- issue81_taxify("Lycopsis orientalis")
  expect_equal(res$taxon_id, "wfo-0000358417")
  expect_equal(res$authorship, "L.")
  expect_equal(res$taxonomic_status, "SYNONYM")
  expect_equal(res$accepted_name, "Anchusa arvensis subsp. orientalis")
  # Steph.'s record is a different type the backbone keeps, so the conflict is
  # still reported.
  expect_equal(res$n_ids, 2L)
  expect_equal(res$accepted_ids, paste(res$accepted_id, "wfo-0001327831",
                                       sep = "|"))
  expect_equal(res$accepted_id, "wfo-0000533555")
})

test_that("an author in the query still picks the unplaced homonym", {
  res <- issue81_taxify(c("Lycopsis orientalis Steph.", "Lycopsis orientalis L."))
  expect_equal(res$taxon_id, c("wfo-0001327831", "wfo-0000358417"))
  expect_equal(res$accepted_name,
               c("Lycopsis orientalis", "Anchusa arvensis subsp. orientalis"))
  expect_equal(res$taxonomic_status, c("UNCHECKED", "SYNONYM"))
  # The author picks the record; the other target stays listed after it.
  expect_equal(res$n_ids, c(2L, 2L))
  expect_equal(sub("[|].*$", "", res$accepted_ids), res$accepted_id)
})

test_that("homotypic_placement reads the basionym author and final epithet", {
  cand <- data.frame(
    matched_name_std    = c("Lycopsis orientalis", "Pinus abies",
                            "Prunus dulcis", "Pinus abies",
                            "Foo bar", "Koenigia polystachya"),
    accepted_name       = c("Anchusa arvensis subsp. orientalis", "Picea abies",
                            "Prunus amygdalus", "Picea polita",
                            "Baz bar", "Persicaria polystachya"),
    authorship          = c("L.", "L.", "(Mill.) D.A.Webb", "Thunb.",
                            "(Qux) Quux", "(Wall. ex Meisn.) T.M.Schust."),
    accepted_authorship = c("(L.) Nordh.", "(L.) H.Karst.", "Batsch",
                            "(Siebold & Zucc.) Carrière", "(Qux) Corge",
                            "(Wall. ex Meisn.) H.Gross"),
    stringsAsFactors = FALSE
  )
  expect_equal(homotypic_placement(cand),
               c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE))
  expect_equal(homotypic_placement(cand[, 1:2]), rep(FALSE, 6L))
})

test_that("score_candidates grades a homotypic synonym between accepted and unplaced", {
  cand <- data.frame(
    taxonID             = c("a", "b", "c"),
    taxonomicStatus     = c("UNCHECKED", "SYNONYM", "ACCEPTED"),
    taxonRank           = "SPECIES",
    matched_name_std    = c("Lycopsis orientalis", "Lycopsis orientalis",
                            "Lycopsis orientalis"),
    accepted_name       = c("Lycopsis orientalis",
                            "Anchusa arvensis subsp. orientalis",
                            "Lycopsis orientalis"),
    authorship          = c("Steph.", "L.", "Nobody"),
    accepted_authorship = c("Steph.", "(L.) Nordh.", "Nobody"),
    stringsAsFactors    = FALSE
  )
  s <- score_candidates(cand)
  expect_equal(s$status_score, c(1, 0.5, 0))
  expect_equal(candidate_order(cand), c(3L, 2L, 1L))
})

# Fuzzy-matching boundary behaviour: competing candidates, wrong-but-close
# neighbours, the accept/reject flip at the threshold, and one-query-per-target
# uniqueness through the public taxify() path.
#
# Distances below are Damerau-Levenshtein edits divided by the longer of the two
# names, the normalization the engine reports in `fuzzy_dist`:
#
#   Quercus robus  -> Quercus robur       1 / 13 = 0.0769
#   Quercus rubra  -> Quercus robur       3 / 13 = 0.2308
#   Salix alpina   -> Salix alba          3 / 12 = 0.2500
#   Carex flavca   -> Carex flacca        1 / 12 = 0.0833
#   Carex flavca   -> Carex flava         1 / 12 = 0.0833
#   Carex flavaa   -> Carex flava         1 / 12 = 0.0833
#   Carex flavaa   -> Carex flacca        2 / 12 = 0.1667
#   Carex flavo    -> Carex flava         1 / 11 = 0.0909
#   Cherleria bisulcata -> Cherleria bisulca   2 / 19 = 0.1053
#   Cherleria bisulcus  -> Cherleria bisulca   2 / 18 = 0.1111
#   Cherleria bisulcum  -> Cherleria bisulca   2 / 18 = 0.1111
#   Cherleria bisulcis  -> Cherleria bisulca   2 / 18 = 0.1111

fuzzy_fixture_df <- function() {
  # Carex flacca and Carex flava are two real, distinct sedges one edit apart in
  # their epithets. flacca carries the lower taxon_id, so a pick that ranks by
  # id rather than by distance is visible.
  data.frame(
    taxon_id = c("wfo-f0001", "wfo-f0002", "wfo-f0003", "wfo-f0004",
                 "wfo-f0005"),
    canonical_name = c("Carex flacca", "Carex flava", "Salix alba",
                       "Quercus robur", "Cherleria bisulca"),
    taxon_rank = rep("SPECIES", 5L),
    taxonomic_status = rep("ACCEPTED", 5L),
    accepted_name_usage_id = rep(NA_character_, 5L),
    family = c("Cyperaceae", "Cyperaceae", "Salicaceae", "Fagaceae",
               "Caryophyllaceae"),
    genus = c("Carex", "Carex", "Salix", "Quercus", "Cherleria"),
    specific_epithet = c("flacca", "flava", "alba", "robur", "bisulca"),
    authorship = c("Schreb.", "L.", "L.", "L.", "A.J.Moore"),
    infraspecific_epithet = rep(NA_character_, 5L),
    stringsAsFactors = FALSE
  )
}


fuzzy_fixture_vtr <- function() {
  df <- fuzzy_fixture_df()
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(
    df,
    id_col         = "taxon_id",
    acc_id_col     = "accepted_name_usage_id",
    name_col       = "canonical_name",
    family_col     = "family",
    genus_col      = "genus",
    status_col     = "taxonomic_status",
    authorship_col = "authorship"
  )
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}


# Pins a hermetic data dir holding only this fixture as the wfo backbone, so a
# bare taxify() resolves to it, and short-circuits the once-per-session backbone
# version check so nothing reaches the network. Both are undone when the calling
# test_that() block exits.
setup_fuzzy_backend <- function() {
  env <- parent.frame()
  vtr_path <- fuzzy_fixture_vtr()
  dd <- tempfile("dd_fuzzy_")
  dir.create(file.path(dd, "wfo", "latest"), recursive = TRUE,
             showWarnings = FALSE)
  file.copy(vtr_path, file.path(dd, "wfo", "latest", "wfo.vtr"))
  withr::local_options(list(taxify.data_dir = dd), .local_envir = env)

  set_backbone_path("wfo", vtr_path)
  withr::defer(set_backbone_path("wfo", NULL), envir = env)

  prev_checked <- .taxify_env[[".version_checked.wfo"]]
  .taxify_env[[".version_checked.wfo"]] <- TRUE
  withr::defer(
    assign(".version_checked.wfo", prev_checked, envir = .taxify_env),
    envir = env
  )

  vtr_path
}


# ---- Two near-equidistant candidates ----

test_that("a typo equidistant from two species is flagged ambiguous", {
  setup_fuzzy_backend()

  # 'Carex flavca' is one edit from both 'Carex flava' and 'Carex flacca'.
  res <- taxify("Carex flavca", verbose = FALSE)

  expect_equal(res$match_type, "fuzzy")
  expect_equal(res$fuzzy_dist, 1 / 12, tolerance = 1e-6)
  expect_true(res$is_ambiguous)
  expect_equal(res$ambiguous_targets, "wfo-f0001|wfo-f0002")
  # Both competing accepted taxa are named, and the scalar columns hold the
  # lower-id candidate rather than dropping the row.
  expect_equal(res$accepted_name, "Carex flacca")
  expect_equal(res$taxon_id, "wfo-f0001")
})


test_that("a typo with a single in-range candidate is not flagged ambiguous", {
  setup_fuzzy_backend()

  # 'Carex flavo' is 0.0909 from 'Carex flava' and 0.25 from 'Carex flacca', so
  # only one candidate is inside the default threshold.
  res <- taxify("Carex flavo", verbose = FALSE)

  expect_equal(res$match_type, "fuzzy")
  expect_equal(res$accepted_name, "Carex flava")
  expect_equal(res$taxon_id, "wfo-f0002")
  expect_equal(res$fuzzy_dist, 1 / 11, tolerance = 1e-6)
  expect_false(res$is_ambiguous)
  expect_true(is.na(res$ambiguous_targets))
})


# ---- Negative: a typo must not land on a wrong-but-close species ----

test_that("a real species absent from the backbone does not become its close neighbour", {
  setup_fuzzy_backend()

  # Quercus rubra (red oak) is a species in its own right, three edits from the
  # Quercus robur (pedunculate oak) in the fixture.
  res <- taxify("Quercus rubra", verbose = FALSE)

  expect_equal(res$match_type, "none")
  expect_true(is.na(res$accepted_name))
  expect_true(is.na(res$matched_name))
  expect_true(is.na(res$taxon_id))
  expect_true(is.na(res$fuzzy_dist))
})


test_that("a close congener outside the threshold stays unresolved", {
  setup_fuzzy_backend()

  # Salix alpina is 0.25 from the fixture's Salix alba, the only Salix present.
  res <- taxify("Salix alpina", verbose = FALSE)

  expect_equal(res$match_type, "none")
  expect_true(is.na(res$accepted_name))
  expect_true(is.na(res$taxon_id))
})


test_that("rejected neighbours resolve once the threshold is widened past them", {
  setup_fuzzy_backend()

  # The same two queries the default threshold rejects: the rejection is the
  # threshold's doing, not an absence of candidates in the fixture.
  res <- taxify(c("Quercus rubra", "Salix alpina"), fuzzy_threshold = 0.25,
                verbose = FALSE)

  expect_equal(res$match_type, c("fuzzy", "fuzzy"))
  expect_equal(res$accepted_name, c("Quercus robur", "Salix alba"))
  expect_equal(res$fuzzy_dist, c(3 / 13, 3 / 12), tolerance = 1e-6)
})


# ---- Threshold boundary ----

test_that("the accept/reject flip sits on the reported fuzzy distance", {
  setup_fuzzy_backend()

  # 'Quercus robus' is 1/13 = 0.0769 from 'Quercus robur'.
  above <- taxify("Quercus robus", fuzzy_threshold = 0.08, verbose = FALSE)
  expect_equal(above$match_type, "fuzzy")
  expect_equal(above$accepted_name, "Quercus robur")
  expect_equal(above$fuzzy_dist, 1 / 13, tolerance = 1e-6)

  below <- taxify("Quercus robus", fuzzy_threshold = 0.07, verbose = FALSE)
  expect_equal(below$match_type, "none")
  expect_true(is.na(below$accepted_name))
})


test_that("the flip holds for a wrong-but-close neighbour at 0.2308", {
  setup_fuzzy_backend()

  # 'Quercus rubra' is 3/13 = 0.2308 from 'Quercus robur'. A threshold of 0.24
  # admits the wrong species; 0.23 keeps it out.
  admitted <- taxify("Quercus rubra", fuzzy_threshold = 0.24, verbose = FALSE)
  expect_equal(admitted$match_type, "fuzzy")
  expect_equal(admitted$accepted_name, "Quercus robur")
  expect_equal(admitted$fuzzy_dist, 3 / 13, tolerance = 1e-6)

  rejected <- taxify("Quercus rubra", fuzzy_threshold = 0.23, verbose = FALSE)
  expect_equal(rejected$match_type, "none")
  expect_true(is.na(rejected$accepted_name))
})


test_that("the flip holds for a neighbour sitting exactly on 0.25", {
  setup_fuzzy_backend()

  # 'Salix alpina' is 3/12 = 0.25 from 'Salix alba': admitted at 0.25, rejected
  # at 0.24, so the comparison is inclusive.
  admitted <- taxify("Salix alpina", fuzzy_threshold = 0.25, verbose = FALSE)
  expect_equal(admitted$match_type, "fuzzy")
  expect_equal(admitted$accepted_name, "Salix alba")
  expect_equal(admitted$fuzzy_dist, 0.25, tolerance = 1e-6)

  rejected <- taxify("Salix alpina", fuzzy_threshold = 0.24, verbose = FALSE)
  expect_equal(rejected$match_type, "none")
  expect_true(is.na(rejected$accepted_name))
})


# ---- One query per backbone row (dedup_fuzzy_targets) ----

test_that("the genus-blocked fuzzy pass keeps only the closest query per target", {
  vtr_path <- setup_fuzzy_backend()
  be <- wfo_backend()

  # Four distinct queries all within threshold of the single backbone row
  # 'Cherleria bisulca'; only 'Cherleria bisulcata' (0.1053) is closest.
  qs <- c("Cherleria bisulcata", "Cherleria bisulcus", "Cherleria bisulcum",
          "Cherleria bisulcis")
  names_df <- clean_names(qs)
  result <- match_exact(be, names_df, vtr_path)
  result <- fuzzy_match_via_join(result, names_df, vtr_path, "dl", 0.2,
                                 be$col_map)

  expect_equal(result$match_type, c("fuzzy", NA, NA, NA))
  expect_equal(result$matched_name[1L], "Cherleria bisulca")
  expect_equal(result$fuzzy_dist[1L], 2 / 19, tolerance = 1e-6)
  expect_equal(sum(result$taxon_id %in% "wfo-f0005"), 1L)
})


test_that("taxify() leaves the farther queries of a collapsing group unresolved", {
  setup_fuzzy_backend()

  qs <- c("Cherleria bisulcata", "Cherleria bisulcus", "Cherleria bisulcum",
          "Cherleria bisulcis")
  res <- taxify(qs, verbose = FALSE)

  # The closest query owns the backbone row.
  expect_equal(res$match_type[1L], "fuzzy")
  expect_equal(res$accepted_name[1L], "Cherleria bisulca")
  expect_equal(res$fuzzy_dist[1L], 2 / 19, tolerance = 1e-6)

  # The two farthest do not fabricate a match onto it.
  expect_equal(res$match_type[3:4], c("none", "none"))
  expect_true(all(is.na(res$accepted_name[3:4])))
  expect_true(all(is.na(res$taxon_id[3:4])))
})


test_that("the prefix fallback cannot re-claim a row the join pass took", {
  setup_fuzzy_backend()

  qs <- c("Cherleria bisulcata", "Cherleria bisulcus", "Cherleria bisulcum",
          "Cherleria bisulcis")
  res <- taxify(qs, verbose = FALSE)

  # Matching runs in passes and each deduplicates its own targets, so the
  # claimed rows of the earlier pass have to be carried into the later one:
  # otherwise a query the join pass dropped wins the same backbone row in the
  # prefix-blocked pass, where it is the closest of what remains.
  expect_equal(sum(res$taxon_id %in% "wfo-f0005"), 1L)
  expect_equal(res$match_type[2L], "none")
  expect_true(is.na(res$accepted_name[2L]))
  expect_true(is.na(res$taxon_id[2L]))
})


# ---- Integer (raw edit count) mode ----

test_that("an integer fuzzy_threshold is accepted and matches on raw edit count", {
  setup_fuzzy_backend()

  # 'Quercus rubra' is 3 raw edits from 'Quercus robur'. A threshold of 2L
  # (2 edits) must reject it; 3L must admit it.
  rejected <- taxify("Quercus rubra", fuzzy_threshold = 2L, verbose = FALSE)
  expect_equal(rejected$match_type, "none")
  expect_true(is.na(rejected$accepted_name))

  admitted <- taxify("Quercus rubra", fuzzy_threshold = 3L, verbose = FALSE)
  expect_equal(admitted$match_type, "fuzzy")
  expect_equal(admitted$accepted_name, "Quercus robur")
})


test_that("the closer of two fuzzy candidates wins regardless of taxon_id", {
  setup_fuzzy_backend()

  # 'Carex flavaa' is 0.0833 from 'Carex flava' (wfo-f0002) and 0.1667 from
  # 'Carex flacca' (wfo-f0001). The farther candidate holds the lower id, so
  # this resolves correctly only when distance outranks the id tiebreak.
  wide <- taxify("Carex flavaa", verbose = FALSE)
  expect_equal(wide$accepted_name, "Carex flava")
  expect_equal(wide$taxon_id, "wfo-f0002")
  expect_equal(wide$fuzzy_dist, 1 / 12, tolerance = 1e-6)
  expect_false(wide$is_ambiguous)

  # Excluding the farther candidate with a tighter threshold cannot change the
  # answer: it was never the better one.
  narrow <- taxify("Carex flavaa", fuzzy_threshold = 0.15, verbose = FALSE)
  expect_equal(narrow$accepted_name, "Carex flava")
  expect_equal(narrow$taxon_id, "wfo-f0002")
  expect_equal(narrow$fuzzy_dist, 1 / 12, tolerance = 1e-6)
  expect_false(narrow$is_ambiguous)
})

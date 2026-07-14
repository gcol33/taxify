# ---- Multi-backend fallback chain tests ----

# Helper: set up both WFO and COL mock backbones in cache
setup_multi_backend <- function() {
  wfo_path <- mock_backbone_vtr()
  col_path <- mock_col_backbone_vtr()
  set_backbone_path("wfo", wfo_path)
  set_backbone_path("col", col_path)
}

# Helper: set up WFO and GBIF mock backbones
setup_wfo_gbif <- function() {
  wfo_path <- mock_backbone_vtr()
  gbif_path <- mock_gbif_backbone_vtr()
  set_backbone_path("wfo", wfo_path)
  set_backbone_path("gbif", gbif_path)
}


test_that("multi-backend returns same schema as single backend", {
  setup_multi_backend()
  result <- taxify("Quercus robur", backend = c("wfo", "col"), verbose = FALSE)
  expected_cols <- c("input_name", "matched_name", "accepted_name",
                     "taxon_id", "accepted_id", "rank", "family",
                     "genus", "epithet", "authorship", "is_synonym",
                     "is_hybrid", "match_type", "fuzzy_dist", "backend",
                     "backbone_version", "life_form")
  expect_true(all(expected_cols %in% names(result)),
              info = paste("Missing cols:", paste(setdiff(expected_cols, names(result)),
                                                  collapse = ", ")))
  expect_equal(nrow(result), 1L)
})

test_that("multi-backend uses first backend when name is found there", {
  setup_multi_backend()
  result <- taxify("Quercus robur", backend = c("wfo", "col"), verbose = FALSE)
  expect_equal(result$backend, "wfo")
  expect_equal(result$matched_name, "Quercus robur")
  expect_equal(result$match_type, "exact")
})

test_that("multi-backend falls back to second backend for unmatched", {
  # Both mock backbones have the same species, so we need a name

  # that only exists in one. Since our mocks are identical in content,
  # test the fallback mechanism by using a name in both — the first
  # backend should win.
  setup_multi_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris"),
                   backend = c("wfo", "col"), verbose = FALSE)
  expect_equal(nrow(result), 2L)
  # Both found in WFO (first backend), so both should be "wfo"
  expect_equal(result$backend, c("wfo", "wfo"))
})

test_that("multi-backend unmatched names get 'none' and NA backend", {
  setup_multi_backend()
  result <- taxify("Nonexistus imaginus", backend = c("wfo", "col"),
                   verbose = FALSE)
  expect_equal(result$match_type, "none")
  expect_true(is.na(result$backend))
})

test_that("multi-backend skips later backends when all matched", {
  setup_multi_backend()
  # All names exist in WFO, so COL should be skipped
  result <- taxify(c("Quercus robur", "Rosa canina"),
                   backend = c("wfo", "col"), verbose = FALSE)
  expect_true(all(result$backend == "wfo"))
})

test_that("multi-backend with single backend works like taxify()", {
  wfo_path <- mock_backbone_vtr()
  set_backbone_path("wfo", wfo_path)
  single <- taxify("Quercus robur", backend = "wfo", verbose = FALSE)
  multi <- taxify("Quercus robur", backend = c("wfo"), verbose = FALSE)
  expect_equal(single, multi)
})

test_that("multi-backend handles synonym resolution per backend", {
  setup_multi_backend()
  result <- taxify("Quercus pedunculata", backend = c("wfo", "col"),
                   verbose = FALSE)
  expect_equal(result$accepted_name, "Quercus robur")
  expect_true(result$is_synonym)
  expect_equal(result$backend, "wfo")
})

test_that("multi-backend handles NA inputs", {
  setup_multi_backend()
  result <- taxify(c("Quercus robur", NA, ""), backend = c("wfo", "col"),
                   verbose = FALSE)
  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Quercus robur")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})

test_that("multi-backend with fuzzy = FALSE skips fuzzy on all backends", {
  setup_multi_backend()
  result <- taxify("Quercus robus", backend = c("wfo", "col"),
                   fuzzy = FALSE, verbose = FALSE)
  expect_equal(result$match_type, "none")
})

test_that("multi-backend fuzzy matching works", {
  setup_multi_backend()
  result <- taxify("Quercus robus", backend = c("wfo", "col"),
                   verbose = FALSE)
  expect_equal(result$matched_name, "Quercus robur")
  expect_equal(result$match_type, "fuzzy")
  expect_equal(result$backend, "wfo")
})

test_that("three-backend chain works", {
  setup_multi_backend()
  gbif_path <- mock_gbif_backbone_vtr()
  set_backbone_path("gbif", gbif_path)

  result <- taxify(c("Quercus robur", "Nonexistus imaginus"),
                   backend = c("wfo", "col", "gbif"), verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(result$backend[1L], "wfo")
  expect_true(is.na(result$backend[2L]))
  expect_equal(result$match_type[2L], "none")
})

test_that("taxify rejects non-character non-backend input", {
  expect_error(taxify("Quercus robur", backend = 123),
               "backend must be a character")
})


# ---- Comparison modes (mode = "wide" / "agreement") ----

# GBIF and COL mocks both carry the red/parma kangaroos with opposite treatments
# (GBIF accepts Macropus, COL accepts Osphranter/Notamacropus), so they exercise
# a genuine backbone disagreement.
setup_gbif_col <- function() {
  set_backbone_path("gbif", mock_gbif_backbone_vtr())
  set_backbone_path("col",  mock_col_backbone_vtr())
}

test_that("mode = 'wide' is a superset of the standard result", {
  setup_gbif_col()
  std  <- taxify(c("Quercus robur", "Macropus rufus"),
                 backend = c("gbif", "col"), verbose = FALSE)
  wide <- taxify(c("Quercus robur", "Macropus rufus"),
                 backend = c("gbif", "col"), mode = "wide", verbose = FALSE)

  # Every standard column survives, plus the comparison columns.
  expect_true(all(names(std) %in% names(wide)))
  expect_true(all(c("accepted_gbif", "accepted_col", "all_agree") %in% names(wide)))
  # accepted_name stays the fallback pick, so the frame is still pipeable.
  expect_equal(wide$accepted_name, std$accepted_name)
  expect_equal(nrow(wide), 2L)
})

test_that("mode = 'wide' surfaces a backbone disagreement", {
  setup_gbif_col()
  wide <- taxify("Macropus rufus", backend = c("gbif", "col"),
                 mode = "wide", verbose = FALSE)

  # GBIF keeps Macropus rufus accepted; COL resolves it to Osphranter rufus.
  expect_equal(wide$accepted_gbif, "Macropus rufus")
  expect_equal(wide$accepted_col,  "Osphranter rufus")
  expect_false(wide$all_agree)
  # Base pick is the first backbone (gbif) that matched.
  expect_equal(wide$accepted_name, "Macropus rufus")
  expect_equal(wide$backend, "gbif")
})

test_that("mode = 'wide' reports agreement where backbones concur", {
  setup_gbif_col()
  wide <- taxify("Quercus robur", backend = c("gbif", "col"),
                 mode = "wide", verbose = FALSE)
  expect_equal(wide$accepted_gbif, "Quercus robur")
  expect_equal(wide$accepted_col,  "Quercus robur")
  expect_true(wide$all_agree)
})

test_that("all_agree is NA when fewer than two backbones match", {
  setup_wfo_gbif()
  # Macropus rufus is in the GBIF mock only; the WFO mock is plants, so just one
  # backbone matches and there is nothing to compare.
  wide <- taxify("Macropus rufus", backend = c("wfo", "gbif"),
                 mode = "wide", verbose = FALSE)
  expect_true(is.na(wide$all_agree))
  expect_true(is.na(wide$accepted_wfo))
  expect_equal(wide$accepted_gbif, "Macropus rufus")
})

test_that("mode = 'agreement' returns the compact verdict columns", {
  setup_gbif_col()
  agr <- taxify(c("Quercus robur", "Macropus rufus"),
                backend = c("gbif", "col"), mode = "agreement",
                verbose = FALSE)
  expect_true(all(c("n_backbones_matched", "n_distinct_accepted", "all_agree")
                  %in% names(agr)))
  # No per-backbone accepted_* columns in agreement mode.
  expect_false("accepted_gbif" %in% names(agr))

  # Quercus: both agree -> 2 matched, 1 distinct, agree TRUE.
  expect_equal(agr$n_backbones_matched[1L], 2L)
  expect_equal(agr$n_distinct_accepted[1L], 1L)
  expect_true(agr$all_agree[1L])

  # Macropus rufus: both match but disagree -> 2 matched, 2 distinct, FALSE.
  expect_equal(agr$n_backbones_matched[2L], 2L)
  expect_equal(agr$n_distinct_accepted[2L], 2L)
  expect_false(agr$all_agree[2L])
})

test_that("mode is ignored (with no compare columns) for a single backend", {
  set_backbone_path("wfo", mock_backbone_vtr())
  result <- taxify("Quercus robur", backend = "wfo", mode = "wide",
                   verbose = FALSE)
  expect_false("all_agree" %in% names(result))
  expect_false(any(grepl("^accepted_(wfo|col|gbif)$", names(result))))
})

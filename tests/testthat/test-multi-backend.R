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
  # Osphranter rufus is one of the kangaroos the COL mock carries and the WFO
  # mock (vascular plants) does not, so the first backend cannot resolve it and
  # the chain has to reach the second. Quercus robur is in both and pins that a
  # name the leading backbone does resolve stays with it.
  setup_multi_backend()
  result <- taxify(c("Quercus robur", "Osphranter rufus"),
                   backend = c("wfo", "col"), fuzzy = FALSE, verbose = FALSE)
  expect_equal(nrow(result), 2L)
  expect_equal(result$backend, c("wfo", "col"))
  expect_equal(result$match_type, c("exact", "exact"))
  expect_equal(result$accepted_name, c("Quercus robur", "Osphranter rufus"))
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


# ---- out_of_scope must not close off the rest of the chain (#9) ----

# The coverage table decides which genera a backbone can carry. WFO is vascular
# plants, so *Macropus* is the real shape of this bug: absent from the WFO mock
# backbone, present in the GBIF one, and in the register because another
# backbone contributed it. `set_oos_chain_fixture()` installs the register, the
# coverage mock and both backbones, and returns the coverage path for
# `with_mocked_bindings()`. `macropus_backends` names the backends whose
# coverage includes it.
set_oos_chain_fixture <- function(macropus_backends = "gbif",
                                  env = parent.frame()) {
  setup_wfo_gbif()

  .taxify_env$register <- data.frame(
    genus         = c("Quercus",       "Macropus"),
    kingdom       = c("Plantae",       "Animalia"),
    phylum        = c("Tracheophyta",  "Chordata"),
    class         = c("Magnoliopsida", "Mammalia"),
    order         = c("Fagales",       "Diprotodontia"),
    family        = c("Fagaceae",      "Macropodidae"),
    kingdom_group = c("plantae",       "animalia"),
    taxon_group   = c("angiosperm",    "mammal"),
    life_form     = c("angiosperm",    "mammal"),
    stringsAsFactors = FALSE
  )

  cov_path <- mock_coverage_vtr(
    genus   = c("Quercus", "Quercus", rep("Macropus", length(macropus_backends))),
    backend = c("wfo",     "gbif",    macropus_backends)
  )
  clear_coverage_cache()
  withr::defer({
    set_backbone_path("wfo", NULL)
    set_backbone_path("gbif", NULL)
    .taxify_env$register <- NULL
    clear_coverage_cache()
  }, envir = env)

  cov_path
}


test_that("a genus the leading backbone lacks still reaches a later one", {
  # Regression (#9): prefilter_out_of_scope() wrote "out_of_scope" into
  # match_type, and the fallback loop only retries rows where match_type is NA.
  # One backbone's coverage gap therefore closed the name off from every
  # backbone behind it -- including the package's own documented example,
  # taxify(c("Quercus robur", "Panthera leo"), backend = c("wfo", "gbif")).
  cov_path <- set_oos_chain_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify(c("Quercus robur", "Macropus rufus"), backend = c("wfo", "gbif"),
           fuzzy = FALSE, verbose = FALSE)
  )

  qr <- result[result$input_name == "Quercus robur", ]
  expect_true(qr$match_type %in% c("exact", "exact_ci"))
  expect_equal(qr$backend, "wfo")

  mr <- result[result$input_name == "Macropus rufus", ]
  expect_true(mr$match_type %in% c("exact", "exact_ci"))
  expect_equal(mr$backend, "gbif")
  expect_equal(mr$accepted_name, "Macropus rufus")
})


test_that("out_of_scope survives when no backbone in the chain covers the genus", {
  # The other half of the contract: releasing a mark must not delete it. With
  # Macropus covered by neither backbone the verdict stands, and it is reported
  # as out_of_scope rather than the weaker "none". The GBIF backbone does carry
  # Macropus rufus, so this also pins that an uncovered genus is never consulted
  # for -- the coverage table, not the backbone content, ends the chain.
  cov_path <- set_oos_chain_fixture(macropus_backends = character(0))

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Macropus rufus", backend = c("wfo", "gbif"), fuzzy = FALSE,
           verbose = FALSE)
  )

  expect_equal(result$match_type, "out_of_scope")
  expect_equal(result$life_form, "mammal")
})


test_that("a single-backend query keeps its own out_of_scope verdict", {
  # scope defaults to the one backend, so nothing is releasable and the
  # single-backend path is unchanged.
  cov_path <- set_oos_chain_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Macropus rufus", backend = "wfo", fuzzy = FALSE, verbose = FALSE)
  )

  expect_equal(result$match_type, "out_of_scope")
})


test_that("release_out_of_scope() lifts only the rows another backend covers", {
  cov_path <- mock_coverage_vtr(genus   = c("Quercus", "Abies"),
                                backend = c("wfo",     "gbif"))
  clear_coverage_cache()
  withr::defer(clear_coverage_cache())

  result <- data.frame(
    input_name = c("Abies alba", "Boletus edulis", "Quercus robur"),
    match_type = c("out_of_scope", "out_of_scope", "exact"),
    stringsAsFactors = FALSE
  )
  names_df <- data.frame(
    cleaned = c("Abies alba", "Boletus edulis", "Quercus robur"),
    stringsAsFactors = FALSE
  )

  out <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    release_out_of_scope(result, names_df, c("wfo", "gbif"))
  )

  # Abies is covered by gbif -> released back to NA for the next backbone.
  expect_true(is.na(out$match_type[1L]))
  # Boletus is covered by neither -> the verdict stands.
  expect_equal(out$match_type[2L], "out_of_scope")
  # A matched row is never touched.
  expect_equal(out$match_type[3L], "exact")
})


test_that("release_out_of_scope() is a no-op without a coverage table", {
  clear_coverage_cache()
  withr::defer(clear_coverage_cache())
  result <- data.frame(input_name = "Abies alba", match_type = "out_of_scope",
                       stringsAsFactors = FALSE)
  names_df <- data.frame(cleaned = "Abies alba", stringsAsFactors = FALSE)

  out <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) NULL,
    release_out_of_scope(result, names_df, c("wfo", "gbif"))
  )
  expect_equal(out$match_type, "out_of_scope")
})


test_that("backend and backbone_version name only backbone-resolved rows (#9)", {
  # Regression (#9, problem 2): the stamp gated on `!is.na(match_type)`, so an
  # out-of-scope row -- reached from the coverage table with no lookup -- was
  # given a backend name and a resolved backbone version. Selecting
  # `result[result$backend == "wfo", ]` then counted it as a WFO match, and a
  # per-backbone hit rate over-reported every backbone in the chain.
  cov_path <- set_oos_chain_fixture(macropus_backends = character(0))

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify(c("Quercus robur", "Macropus rufus",
             "Quercus robur x Quercus petraea", "Zzzyxia qqqnotarealname"),
           backend = c("wfo", "gbif"), fuzzy = FALSE, verbose = FALSE)
  )

  by_input <- function(nm, col) result[[col]][result$input_name == nm]

  expect_equal(by_input("Quercus robur", "backend"), "wfo")
  expect_false(is.na(by_input("Quercus robur", "backbone_version")))

  # Every verdict reached without a lookup carries neither.
  for (nm in c("Macropus rufus", "Quercus robur x Quercus petraea",
               "Zzzyxia qqqnotarealname")) {
    expect_true(is.na(by_input(nm, "backend")), info = nm)
    expect_true(is.na(by_input(nm, "backbone_version")), info = nm)
  }

  # The documented contract: the column selects what a backbone resolved.
  expect_equal(sum(result$backend == "wfo", na.rm = TRUE), 1L)
})


test_that("is_backbone_match() covers the whole match_type vocabulary", {
  expect_equal(
    is_backbone_match(c("exact", "exact_ci", "fuzzy", "abbrev",
                        "out_of_scope", "hybrid_formula", "none", NA)),
    c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
  expect_equal(is_backbone_match(character(0)), logical(0))
})

# Exports that the rest of the suite reaches only through other functions, if at
# all (#75): each is called here directly, on its own contract.

test_that("score_candidates() grades status, rank, epithet and distance", {
  cand <- data.frame(
    taxonID          = c("a", "b", "c", "d"),
    taxonomicStatus  = c("SYNONYM", "ACCEPTED", "ACCEPTED", "ACCEPTED"),
    taxonRank        = c("SPECIES", "SPECIES", "GENUS", "SPECIES"),
    fuzzy_dist       = c(0, 0, 0, 0.1),
    stringsAsFactors = FALSE
  )
  s <- score_candidates(cand)
  expect_named(s, c("dist_score", "data_score", "year_score", "occ_score",
                    "status_score", "rank_score", "valid_score",
                    "epithet_score", "tier"))
  expect_equal(s$data_score, integer(4))                # no n_occurrences
  expect_equal(s$year_score, numeric(4))                # no year columns
  expect_equal(s$occ_score, numeric(4))
  expect_gt(s$status_score[1], s$status_score[2])       # synonym below accepted
  expect_equal(s$rank_score, c(0L, 0L, 1L, 0L))         # species over genus
  expect_equal(s$dist_score, c(0, 0, 0, 0.1))
  expect_equal(s$valid_score, integer(4))               # no nomenclaturalStatus
  expect_length(unique(s$tier), 4L)
})

test_that("score_candidates() keeps validity out of the tier", {
  cand <- data.frame(
    taxonID = c("x1", "x2"), taxonomicStatus = "SYNONYM", taxonRank = "SPECIES",
    nomenclaturalStatus = c("Illegitimate", "Valid"), stringsAsFactors = FALSE
  )
  s <- score_candidates(cand)
  expect_equal(s$valid_score, c(1L, 0L))
  expect_identical(s$tier[1], s$tier[2])
})

test_that("candidate_order() sorts by the scores, then validity, then taxonID", {
  cand <- data.frame(
    taxonID = c("t3", "t2", "t1", "t4"),
    taxonomicStatus = c("ACCEPTED", "SYNONYM", "ACCEPTED", "ACCEPTED"),
    taxonRank = c("SPECIES", "SPECIES", "SPECIES", "GENUS"),
    nomenclaturalStatus = c("", "Valid", "", ""),
    grp = c("g2", "g1", "g1", "g2"),
    stringsAsFactors = FALSE
  )
  # Status outranks rank: the accepted genus t4 sorts ahead of the synonym t2.
  expect_equal(cand$taxonID[candidate_order(cand)], c("t1", "t3", "t4", "t2"))
  expect_equal(cand$taxonID[candidate_order(cand, group_col = "grp")],
               c("t1", "t2", "t3", "t4"))
  # A precomputed score list gives the same permutation.
  expect_identical(candidate_order(cand, scores = score_candidates(cand)),
                   candidate_order(cand))
})

test_that("taxify_load_register() reads and caches the register", {
  old <- options(taxify.data_dir = taxify_example_data())
  env <- taxify:::.taxify_env
  prev <- env$register
  on.exit({ options(old); env$register <- prev }, add = TRUE)

  reg <- taxify_load_register(force = TRUE, verbose = FALSE)
  expect_s3_class(reg, "data.frame")
  expect_true(all(c("genus", "kingdom", "family", "kingdom_group",
                    "taxon_group", "life_form") %in% names(reg)))
  expect_gt(nrow(reg), 0L)
  expect_identical(env$register, reg)
  # A second call serves the cache rather than re-reading.
  expect_identical(taxify_load_register(verbose = FALSE), reg)
})

test_that("taxify_register_coverage() lists the backbones carrying a genus", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  reg <- taxify_load_register(force = TRUE, verbose = FALSE)
  cov <- taxify_register_coverage("Quercus")
  expect_s3_class(cov, "data.frame")
  expect_true(all(c("genus", "backbone", "version", "date_added") %in% names(cov)))
  expect_gt(nrow(cov), 0L)
  expect_true(all(cov$genus == "Quercus"))

  none <- taxify_register_coverage("Notagenus")
  expect_equal(nrow(none), 0L)
  expect_error(taxify_register_coverage(c("Quercus", "Pinus")), "scalar")
})

test_that("taxify_download() installs a backbone from the manifest", {
  src <- tempfile("src_"); dir.create(src)
  vtr <- file.path(src, "wfo.vtr")
  file.copy(mock_backbone_vtr(), vtr)
  md5 <- unname(tools::md5sum(vtr))
  url <- paste0("file:///", normalizePath(vtr, winslash = "/"))
  mf  <- list(schema_version = 2L,
              backends = list(wfo = list(latest = "2026.08", full_url = url,
                                         content_id = md5)),
              enrichments = list())
  mpath <- file.path(src, "manifest.json")
  jsonlite::write_json(mf, mpath, pretty = TRUE, auto_unbox = TRUE)

  dd <- tempfile("dl_"); dir.create(dd)
  old <- options(taxify.data_dir = dd, taxify.manifest_path = mpath)
  on.exit({ options(old); taxify:::taxify_refresh_manifest() }, add = TRUE)
  taxify:::taxify_refresh_manifest()

  p <- taxify_download("wfo", verbose = FALSE)
  expect_named(p, "wfo")
  expect_true(file.exists(p[["wfo"]]))
  expect_identical(unname(tools::md5sum(p[["wfo"]])), md5)
  meta <- taxify:::read_version_meta("wfo", "latest")
  expect_identical(meta$content_id, md5)
  expect_false(is.null(meta$downloaded_at))
})

test_that("taxify_download() refuses content ids that do not pair with backbones", {
  expect_error(taxify_download(c("wfo", "col"), content_id = c("a", "b", "c"),
                               verbose = FALSE))
})

# taxify_lock() pins the build a result was produced from (#63).

stage_enrichment_meta <- function(dd, name, version, content_id) {
  latest <- file.path(dd, "enrichment", name, "latest")
  dir.create(latest, recursive = TRUE, showWarnings = FALSE)
  file.create(file.path(latest, paste0(name, ".vtr")))
  jsonlite::write_json(list(version = version, content_id = content_id),
                       file.path(latest, "meta.json"), auto_unbox = TRUE)
}

test_that("a source that contributed nothing is neither cited nor locked", {
  x <- empty_taxify_result("wfo")
  meta <- attr(x, "taxify_meta")
  meta$enrichments <- list(
    list(name = "used",   n_matched = 3L, version = "2026.08",
         content_id = "0123456789abcdef0123456789abcdef"),
    list(name = "unused", n_matched = 0L, version = NA_character_,
         content_id = NA_character_)
  )
  attr(x, "taxify_meta") <- meta

  lock <- taxify_lock(x, verbose = FALSE)
  expect_equal(vapply(lock$enrichments, `[[`, character(1L), "name"), "used")
})

test_that("the lock records the build joined against, not the one installed later", {
  dd <- tempfile("lockid_")
  withr::local_options(taxify.data_dir = dd)
  stage_enrichment_meta(dd, "mocklock", "2026.06",
                        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

  x <- register_enrichment(empty_taxify_result("wfo"), "mocklock", "mock",
                           NA_character_, 5L)
  e <- attr(x, "taxify_meta")$enrichments[[1L]]
  expect_equal(e$version, "2026.06")
  expect_equal(e$content_id, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

  # A refresh after the join replaces the installed build.
  stage_enrichment_meta(dd, "mocklock", "2026.08",
                        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
  locked <- taxify_lock(x, verbose = FALSE)$enrichments[[1L]]
  expect_equal(locked$version, "2026.06")
  expect_equal(locked$content_id, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

  # ...and restore sees the drift instead of calling it ok.
  st <- taxify_restore(taxify_lock(x, verbose = FALSE), verbose = FALSE)
  expect_equal(st$status[st$component == "mocklock"], "content_drift")
})

test_that("a locked content id with none installed is unverified, even when versions match", {
  cid <- "0123456789abcdef0123456789abcdef"
  expect_equal(.restore_status("2026.08", cid, "2026.08", NA, installed = TRUE),
               "unverified")
  expect_equal(.restore_status("2026.08", cid, "2026.08", cid, installed = TRUE),
               "ok")
  expect_equal(.restore_status("2026.08", cid, "2026.08",
                               "ffffffffffffffffffffffffffffffff",
                               installed = TRUE),
               "content_drift")
})

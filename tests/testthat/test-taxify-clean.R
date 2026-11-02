local_store <- function(env = parent.frame()) {
  dd <- tempfile("taxify_clean_")
  withr::defer(unlink(dd, recursive = TRUE), envir = env)
  withr::local_options(taxify.data_dir = dd, .local_envir = env)

  put <- function(...) {
    p <- file.path(dd, ...)
    dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
    writeBin(as.raw(rep(1L, 1024)), p)
    p
  }
  cid <- strrep("a", 32)
  paths <- list(
    col_active     = put("col", "latest", "col.vtr"),
    col_archived   = put("col", cid, "col.vtr"),
    col_version    = put("col", "2024.01", "col.vtr"),
    col_stale_tmp  = put("col", "x.vtr.tmp.curltmp"),
    col_old_layout = put("col", "latest", "y.vtr.tmp"),
    col_fresh_tmp  = put("col", "z.vtr.tmp.curltmp"),
    en_active      = put("enrichment", "zanne", "latest", "zanne.vtr"),
    en_archived    = put("enrichment", "zanne", cid, "zanne.vtr"),
    foreign        = put("my_notes", "old", "keep.txt")
  )
  Sys.setFileTime(c(paths$col_stale_tmp, paths$col_old_layout),
                  Sys.time() - 7200)
  list(dd = dd, paths = paths)
}

test_that("taxify_clean() removes superseded builds and interrupted downloads", {
  s <- local_store()
  p <- s$paths

  listed <- taxify_clean(dry_run = TRUE, verbose = FALSE)
  expect_true(all(file.exists(unlist(p))))
  expect_setequal(listed$reason, c("superseded", "interrupted"))
  expect_equal(nrow(listed), 5L)

  expect_message(taxify_clean(), "Removed")
  gone <- c(p$col_archived, p$col_version, p$col_stale_tmp, p$col_old_layout,
            p$en_archived)
  kept <- c(p$col_active, p$col_fresh_tmp, p$en_active, p$foreign)
  expect_false(any(file.exists(gone)))
  expect_true(all(file.exists(kept)))
})

test_that("taxify_clean() removes named assets or the whole directory", {
  s <- local_store()
  taxify_clean(c("col", "zanne"), verbose = FALSE)
  expect_false(dir.exists(file.path(s$dd, "col")))
  expect_false(dir.exists(file.path(s$dd, "enrichment", "zanne")))
  expect_true(file.exists(s$paths$foreign))

  expect_warning(taxify_clean("nope", verbose = FALSE), "Not in the data")

  taxify_clean("all", verbose = FALSE)
  expect_false(dir.exists(s$dd))
})

age_build <- function(dir, days) {
  f <- list.files(dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  Sys.setFileTime(f, Sys.time() - days * 86400)
}

# Rewrite a fixture build as one store format and download record.
as_build <- function(vtr, magic = "TDCF", content_id = NULL, pinned = FALSE) {
  writeBin(c(charToRaw(magic), as.raw(rep(1L, 1020))), vtr)
  meta <- list(pinned = pinned)
  meta$content_id <- content_id
  jsonlite::write_json(meta, file.path(dirname(vtr), "meta.json"),
                       auto_unbox = TRUE)
  vtr
}

served_id <- function(name) {
  taxify:::resolve_manifest_entry(taxify:::local_manifest(), name)$content_id
}

test_that("loading removes outdated builds left unused, active ones included", {
  s <- local_store()
  p <- s$paths
  as_build(p$col_active, magic = "TDC1")
  as_build(p$en_archived, content_id = strrep("b", 32))
  age_build(dirname(p$col_active), 200)
  age_build(dirname(p$en_archived), 200)
  withr::local_options(taxify.max_unused_days = 90)

  expect_message(taxify:::sweep_unused_builds(), "removed")
  expect_false(dir.exists(dirname(p$col_active)))
  expect_false(dir.exists(dirname(p$en_archived)))
  expect_false(file.exists(p$col_stale_tmp))
  # Recently written builds and files taxify does not lay out stay.
  expect_true(all(file.exists(c(p$col_version, p$en_active, p$foreign,
                                p$col_fresh_tmp))))
})

test_that("a current or pinned build stays however long it is unused", {
  s <- local_store()
  p <- s$paths
  as_build(p$col_active, content_id = served_id("col"))
  as_build(p$col_version, magic = "TDC1", pinned = TRUE)
  as_build(p$en_active)
  age_build(dirname(p$col_active), 2000)
  age_build(dirname(p$col_version), 2000)
  age_build(dirname(p$en_active), 2000)
  withr::local_options(taxify.max_unused_days = 90)
  taxify:::sweep_unused_builds()
  expect_true(all(file.exists(c(p$col_active, p$col_version, p$en_active))))
})

test_that("an outdated build read in a session is not removed", {
  s <- local_store()
  p <- s$paths
  as_build(p$col_active, magic = "TDC1")
  age_build(dirname(p$col_active), 200)
  taxify:::mark_build_used(p$col_active)
  withr::local_options(taxify.max_unused_days = 90)
  taxify:::sweep_unused_builds()
  expect_true(file.exists(p$col_active))
})

test_that("taxify.max_unused_days = Inf keeps every build", {
  s <- local_store()
  as_build(s$paths$col_active, magic = "TDC1")
  age_build(dirname(s$paths$col_active), 2000)
  withr::local_options(taxify.max_unused_days = Inf)
  expect_silent(taxify:::sweep_unused_builds())
  expect_true(file.exists(s$paths$col_active))
})

test_that("a data directory left with nothing is removed", {
  dd <- tempfile("taxify_sweep_")
  withr::defer(unlink(dd, recursive = TRUE))
  withr::local_options(taxify.data_dir = dd, taxify.max_unused_days = 90)
  vtr <- file.path(dd, "gbif", "latest", "gbif.vtr")
  dir.create(dirname(vtr), recursive = TRUE)
  as_build(vtr, magic = "TDC1")
  age_build(dirname(vtr), 120)
  suppressMessages(taxify:::sweep_unused_builds())
  expect_false(dir.exists(dd))
})

test_that("taxify_clean(unused_days =) applies the same rule on demand", {
  s <- local_store()
  as_build(s$paths$col_active, magic = "TDC1")
  age_build(dirname(s$paths$col_active), 40)
  listed <- taxify_clean(unused_days = 30, dry_run = TRUE, verbose = FALSE)
  expect_true("unused" %in% listed$reason)
  expect_true(normalizePath(dirname(s$paths$col_active)) %in%
                normalizePath(listed$path))
  expect_error(taxify_clean("col", unused_days = 30), "only when assets")
})

test_that("taxify_clean() refuses the example database", {
  withr::local_options(taxify.data_dir = taxify_example_data())
  expect_error(taxify_clean(dry_run = TRUE), "read-only example database")
})

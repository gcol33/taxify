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

test_that("taxify_clean() refuses the example database", {
  withr::local_options(taxify.data_dir = taxify_example_data())
  expect_error(taxify_clean(dry_run = TRUE), "read-only example database")
})

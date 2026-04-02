# Tests for use_local_manifest() and clear_local_manifest()

# Helper: create a minimal fake versioned backend on disk
make_fake_backend <- function(base_dir, be_name, vtr_file, version) {
  be_dir <- file.path(base_dir, be_name, "latest")
  if (be_name == "register") {
    be_dir <- file.path(base_dir, "unified", "latest")
  }
  dir.create(be_dir, recursive = TRUE, showWarnings = FALSE)
  vtr_path <- file.path(be_dir, vtr_file)
  writeLines("placeholder", vtr_path)
  meta <- list(version = version, pinned = FALSE,
               downloaded_at = "2026-04-01")
  jsonlite::write_json(meta, file.path(be_dir, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  vtr_path
}


test_that("use_local_manifest() finds no backends when data_dir is empty", {
  tmp_dir <- tempfile("taxify_test_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Temporarily redirect taxify_data_dir() via mockery-free approach:
  # override .taxify_env$manifest before calling so we can verify it gets set
  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  # Patch taxify_data_dir by temporarily overriding in the test env
  with_mocked_bindings(
    taxify_data_dir = function() tmp_dir,
    {
      msg <- capture.output(use_local_manifest(), type = "message")
      # Should report "no backends installed" or similar
      expect_true(any(grepl("not installed|no backends|Local manifest",
                            msg, ignore.case = TRUE)))
      # Manifest should be set but empty (no backends)
      expect_true(!is.null(.taxify_env$manifest))
      expect_equal(length(.taxify_env$manifest), 0L)
    }
  )
})


test_that("use_local_manifest() finds installed backends and builds file:// URLs", {
  tmp_dir <- tempfile("taxify_test_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create fake wfo and col backends, skip gbif and register
  make_fake_backend(tmp_dir, "wfo", "wfo.vtr", "2024.12")
  make_fake_backend(tmp_dir, "col", "col.vtr", "2024.11")

  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  with_mocked_bindings(
    taxify_data_dir = function() tmp_dir,
    {
      use_local_manifest()

      m <- .taxify_env$manifest
      expect_true(!is.null(m))

      # wfo and col should be present
      expect_true("wfo" %in% names(m))
      expect_true("col" %in% names(m))

      # versions should match what we wrote
      expect_equal(m$wfo$latest, "2024.12")
      expect_equal(m$col$latest, "2024.11")

      # URLs should be file:// scheme
      expect_true(startsWith(m$wfo$url, "file://"))
      expect_true(startsWith(m$col$url, "file://"))

      # URLs should end with the vtr filename
      expect_true(endsWith(m$wfo$url, "wfo.vtr"))
      expect_true(endsWith(m$col$url, "col.vtr"))

      # gbif and register should NOT be present (not installed)
      expect_false("gbif" %in% names(m))
      expect_false("register" %in% names(m))
    }
  )
})


test_that("use_local_manifest() finds register under unified/latest/", {
  tmp_dir <- tempfile("taxify_test_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  make_fake_backend(tmp_dir, "register", "genus_register.vtr", "2026.04")

  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  with_mocked_bindings(
    taxify_data_dir = function() tmp_dir,
    {
      use_local_manifest()
      m <- .taxify_env$manifest
      expect_true("register" %in% names(m))
      expect_equal(m$register$latest, "2026.04")
      expect_true(startsWith(m$register$url, "file://"))
      expect_true(endsWith(m$register$url, "genus_register.vtr"))
    }
  )
})


test_that("fetch_manifest() returns injected manifest without hitting network", {
  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  fake_manifest <- list(
    wfo = list(latest = "9999.01", url = "file:///fake/wfo.vtr"),
    col = list(latest = "9999.02", url = "file:///fake/col.vtr")
  )
  .taxify_env$manifest <- fake_manifest

  # fetch_manifest() should return the cached manifest without any network call
  result <- fetch_manifest()
  expect_identical(result, fake_manifest)
  expect_equal(result$wfo$latest, "9999.01")
})


test_that("clear_local_manifest() resets manifest and version-check flags", {
  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  # Inject a manifest and set some version-checked flags
  .taxify_env$manifest <- list(wfo = list(latest = "test", url = "file:///x"))
  .taxify_env$.version_checked.wfo <- TRUE
  .taxify_env$.version_checked.col <- TRUE

  msg <- capture.output(clear_local_manifest(), type = "message")
  expect_true(any(grepl("cleared|GitHub", msg, ignore.case = TRUE)))

  # Manifest should be NULL
  expect_null(.taxify_env$manifest)

  # Version-checked flags should be gone
  expect_null(.taxify_env$.version_checked.wfo)
  expect_null(.taxify_env$.version_checked.col)
})


test_that("use_local_manifest() falls back to 'unknown' when meta.json is absent", {
  tmp_dir <- tempfile("taxify_test_")
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Create a wfo .vtr but no meta.json
  be_dir <- file.path(tmp_dir, "wfo", "latest")
  dir.create(be_dir, recursive = TRUE)
  writeLines("placeholder", file.path(be_dir, "wfo.vtr"))

  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)

  with_mocked_bindings(
    taxify_data_dir = function() tmp_dir,
    {
      use_local_manifest()
      m <- .taxify_env$manifest
      expect_true("wfo" %in% names(m))
      expect_equal(m$wfo$latest, "unknown")
    }
  )
})

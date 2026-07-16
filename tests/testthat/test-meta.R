# Backbone .meta sidecar parsing and version formatting.
#
# taxifydb build sidecars label the build date with `build_date` /
# `build_timestamp` / `source_url`; older downloads used `download_date` /
# `download_timestamp` / `url`. Both must read cleanly, and a sidecar missing
# a date must not crash version formatting (an absent date once produced a
# zero-length backbone_version that errored on assignment).

test_that("read_backbone_meta normalizes build_date-format sidecars", {
  vtr  <- tempfile(fileext = ".vtr")
  meta <- paste0(tools::file_path_sans_ext(vtr), ".meta")
  on.exit(unlink(meta), add = TRUE)

  writeLines(c("backend=worms", "version=2026.05",
               "build_date=2026-05-14",
               "build_timestamp=2026-05-14T10:00:00+0200",
               "source_url=https://example.org/worms.zip",
               "nrow=1547836"), meta)
  m <- read_backbone_meta(vtr)
  expect_equal(m$download_date, "2026-05-14")
  expect_equal(m$download_timestamp, "2026-05-14T10:00:00+0200")
  expect_equal(m$url, "https://example.org/worms.zip")
})

test_that("format_backbone_version handles build_date, download_date, neither", {
  vtr  <- tempfile(fileext = ".vtr")
  meta <- paste0(tools::file_path_sans_ext(vtr), ".meta")
  on.exit(unlink(meta), add = TRUE)

  # New build_date format.
  writeLines(c("backend=worms", "version=2026.05",
               "build_date=2026-05-14"), meta)
  expect_equal(format_backbone_version(vtr, "worms", "x"),
               "worms:2026.05 (2026-05-14)")

  # Legacy download_date format.
  writeLines(c("backend=wfo", "version=2024-12",
               "download_date=2026-05-02"), meta)
  expect_equal(format_backbone_version(vtr, "wfo", "x"),
               "wfo:2024-12 (2026-05-02)")

  # No date present: single, non-empty fallback string (no zero-length crash).
  writeLines(c("backend=col", "version=2025"), meta)
  v <- format_backbone_version(vtr, "col", "fallback")
  expect_equal(v, "col:2025")
  expect_length(v, 1L)

  # No sidecar at all: uses the supplied fallbacks.
  unlink(meta)
  expect_equal(format_backbone_version(vtr, "gbif", "current"),
               "gbif:current")
})

test_that("format_backbone_version reads meta.json when no .meta sidecar", {
  # A downloaded backbone carries meta.json (manifest version) but no `.meta`
  # build sidecar; that manifest version must drive the reported string.
  dir <- tempfile("bb_"); dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  vtr <- file.path(dir, "euromed.vtr")
  writeLines("placeholder", vtr)
  jsonlite::write_json(
    list(version = "2026.07", pinned = FALSE, downloaded_at = "2026-07-16"),
    file.path(dir, "meta.json"), pretty = TRUE, auto_unbox = TRUE)

  # The static fallback ("2020.1") must lose to the meta.json version.
  expect_equal(format_backbone_version(vtr, "euromed", "2020.1"),
               "euromed:2026.07 (2026-07-16)")
})

test_that("download_backbone clears a stale build .meta so meta.json wins", {
  # A slot previously built from source leaves a `.meta` sidecar. After a fresh
  # download replaces the .vtr, that stale sidecar must be removed, otherwise it
  # shadows the download-time meta.json and reports the old built version.
  tmp <- tempfile("taxify_dl_"); dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  # Download source ("release asset").
  src_dir <- file.path(tmp, "src"); dir.create(src_dir)
  src_vtr <- file.path(src_dir, "euromed.vtr")
  writeLines("fresh-downloaded-bytes", src_vtr)
  src_url <- paste0("file:///", normalizePath(src_vtr, winslash = "/"))

  # Pre-existing slot from an earlier build-from-source: stale .meta, no meta.json.
  data_dir <- file.path(tmp, "data")
  slot <- file.path(data_dir, "euromed", "latest")
  dir.create(slot, recursive = TRUE)
  writeLines("old-built-bytes", file.path(slot, "euromed.vtr"))
  stale_meta <- file.path(slot, "euromed.meta")
  writeLines(c("backend=euromed", "version=2020.1", "build_date=2026-06-25"),
             stale_meta)

  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)
  .taxify_env$manifest <- list(
    euromed = list(latest = "2026.07", full_url = src_url))

  with_mocked_bindings(
    taxify_data_dir = function() data_dir,
    {
      p <- download_backbone("euromed", version = "latest", verbose = FALSE)

      expect_false(file.exists(stale_meta))
      expect_true(file.exists(file.path(slot, "meta.json")))
      expect_equal(read_version_meta("euromed", "latest")$version, "2026.07")
      # Reported version now reflects the downloaded release, not the old build.
      expect_match(format_backbone_version(p, "euromed", "0"),
                   "^euromed:2026\\.07")
    }
  )
})

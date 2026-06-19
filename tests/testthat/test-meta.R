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

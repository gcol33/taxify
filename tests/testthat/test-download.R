test_that("download_backbone patches via xdelta3 when the data dir contains a space", {
  skip_if(!nzchar(Sys.which("xdelta3")))

  tmp <- tempfile("taxify dl ")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  data_dir <- file.path(tmp, "data dir")
  slot <- file.path(data_dir, "euromed", "latest")
  dir.create(slot, recursive = TRUE)
  old_vtr <- file.path(slot, "euromed.vtr")
  writeBin(as.raw(rep(1:200, 5)), old_vtr)

  src_dir <- file.path(tmp, "release assets")
  dir.create(src_dir)
  new_bytes <- as.raw(c(rep(1:100, 5), rep(50:149, 5)))
  new_vtr <- file.path(src_dir, "euromed-new.vtr")
  writeBin(new_bytes, new_vtr)
  delta <- file.path(src_dir, "euromed.xdelta")
  status <- system2("xdelta3", c("-e", "-f", "-s", shQuote(old_vtr),
                                 shQuote(new_vtr), shQuote(delta)))
  expect_equal(status, 0L)

  # The full asset differs from the patch result, so the bytes on disk show
  # which route produced them.
  full_vtr <- file.path(src_dir, "euromed-full.vtr")
  writeBin(as.raw(rep(7L, 64)), full_vtr)

  file_url <- function(p) paste0("file:///", normalizePath(p, winslash = "/"))
  orig_manifest <- .taxify_env$manifest
  on.exit({ .taxify_env$manifest <- orig_manifest }, add = TRUE)
  .taxify_env$manifest <- list(
    euromed = list(latest = "2026.09", full_url = file_url(full_vtr),
                   content_id = unname(tools::md5sum(new_vtr)),
                   delta_url = file_url(delta),
                   delta_from_content_id = unname(tools::md5sum(old_vtr))))
  old_opt <- options(taxify.keep_backbone_versions = FALSE)
  on.exit(options(old_opt), add = TRUE)

  with_mocked_bindings(
    taxify_data_dir = function() data_dir,
    {
      expect_message(
        p <- download_backbone("euromed", version = "latest", verbose = FALSE),
        "patched via xdelta3\\)\\."
      )
      expect_identical(readBin(p, "raw", length(new_bytes) + 1L), new_bytes)
      expect_identical(read_version_meta("euromed", "latest")$install_path,
                       "patched")
    }
  )
})

# The content-id refresh gate is lifted to backbones: check_version() catches a
# same-tag republish (rebuilt .vtr re-uploaded under an unchanged version) that
# a version-string comparison alone would miss. Backbones do not rehash a
# multi-GB cache (hash_missing = FALSE); they compare the id their downloaded
# meta.json already carries.

stage_backend <- function(dd, name, df, meta_extra = list(), version = "2026.07") {
  vd <- file.path(dd, name, "latest")            # versioned_dir(name, "latest")
  dir.create(vd, recursive = TRUE, showWarnings = FALSE)
  vtr <- file.path(vd, paste0(name, ".vtr"))
  vectra::write_vtr(df, vtr)
  meta <- c(list(version = version, pinned = FALSE,
                 downloaded_at = "2026-07-06"), meta_extra)
  jsonlite::write_json(meta, file.path(vd, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  list(vtr = vtr, dir = vd, md5 = unname(tools::md5sum(vtr)))
}

manifest_with <- function(name, version = "2026.07", cid = NULL, static = FALSE) {
  entry <- list(latest = version, full_url = "https://example.invalid/x.vtr")
  if (!is.null(cid)) entry$content_id <- cid
  if (static) entry$static <- TRUE
  list(schema_version = 2L,
       backends = stats::setNames(list(entry), name),
       enrichments = list())
}

df <- data.frame(canonical_name = c("Aa", "Bb"), x = c(1, 2),
                 stringsAsFactors = FALSE)

# Inject a manifest into the session cache so fetch_manifest() returns it
# without a network call.
with_manifest <- function(mf, code) {
  env <- taxify:::.taxify_env          # bind the env reference; assign in place
  old <- env$manifest
  env$manifest <- mf
  on.exit(env$manifest <- old, add = TRUE)
  force(code)
}

test_that("write_version_meta stamps the .vtr content id", {
  dd <- tempfile("bb_"); dir.create(dd)
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)
  s <- stage_backend(dd, "demo", df)
  taxify:::write_version_meta(s$dir, "demo", "2026.07")
  m <- jsonlite::read_json(file.path(s$dir, "meta.json"), simplifyVector = TRUE)
  expect_identical(m$content_id, s$md5)
})

test_that("same version + matching content id needs no refresh", {
  dd <- tempfile("bb_"); dir.create(dd)
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)
  s <- stage_backend(dd, "demo", df, meta_extra = list(content_id = "MD5"))
  s <- stage_backend(dd, "demo", df, meta_extra = list(content_id = s$md5))
  with_manifest(manifest_with("demo", cid = s$md5),
                expect_false(taxify:::check_version("demo")))
})

test_that("same version + changed content id forces a refresh (republish)", {
  dd <- tempfile("bb_"); dir.create(dd)
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)
  s <- stage_backend(dd, "demo", df, meta_extra = list(content_id = "old_md5"))
  with_manifest(manifest_with("demo", cid = "new_md5"),
                expect_true(taxify:::check_version("demo")))
})

test_that("a version bump still forces a refresh", {
  dd <- tempfile("bb_"); dir.create(dd)
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)
  s <- stage_backend(dd, "demo", df, version = "2026.06",
                     meta_extra = list(content_id = "whatever"))
  with_manifest(manifest_with("demo", version = "2026.07", cid = "whatever"),
                expect_true(taxify:::check_version("demo")))
})

test_that("legacy backbone cache (no stored id) is not rehashed, no refresh", {
  dd <- tempfile("bb_"); dir.create(dd)
  old <- options(taxify.data_dir = dd); on.exit(options(old), add = TRUE)
  s <- stage_backend(dd, "demo", df)              # meta has NO content_id
  with_manifest(manifest_with("demo", cid = "some_md5"),
                expect_false(taxify:::check_version("demo")))
})

test_that("static backbone reconciles content id offline", {
  dd <- tempfile("bb_"); dir.create(dd)
  s <- stage_backend(dd, "demo", df,
                     meta_extra = list(static = TRUE, content_id = "stale"))
  mpath <- file.path(dd, "manifest.json")
  jsonlite::write_json(manifest_with("demo", cid = "fresh", static = TRUE),
                       mpath, pretty = TRUE, auto_unbox = TRUE)
  old <- options(taxify.data_dir = dd, taxify.manifest_path = mpath)
  on.exit(options(old), add = TRUE)
  expect_true(taxify:::check_version("demo"))
})

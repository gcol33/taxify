# A same-tag republish (a rebuilt .vtr re-uploaded under an unchanged release
# tag) would otherwise leave the local cache stale forever, for a static
# enrichment because it never phones home and for a versioned one because the
# label it compares is unchanged. check_enrichment_version() reconciles both
# against the manifest's content_id (md5 of the built .vtr).

# Stage a static enrichment cache: a .vtr plus a meta.json, and a bundled
# manifest carrying (or omitting) the enrichment's content_id.
stage_static <- function(dd, name, df, meta_extra = list(), manifest_cid = NULL) {
  edir <- file.path(dd, "enrichment", name, "latest")
  dir.create(edir, recursive = TRUE, showWarnings = FALSE)
  vtr <- file.path(edir, paste0(name, ".vtr"))
  vectra::write_vtr(df, vtr)
  meta <- c(list(version = "2026.07", static = TRUE,
                 downloaded_at = "2026-07-06"), meta_extra)
  jsonlite::write_json(meta, file.path(edir, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  # A minimal bundled manifest with one enrichment entry.
  entry <- list(latest = "2026.07",
                full_url = "https://example.invalid/x.vtr")
  if (!is.null(manifest_cid)) entry$content_id <- manifest_cid
  mf <- list(schema_version = 2L, backends = list(),
             enrichments = stats::setNames(list(entry), name))
  mpath <- file.path(dd, "manifest.json")
  jsonlite::write_json(mf, mpath, pretty = TRUE, auto_unbox = TRUE)
  list(vtr = vtr, manifest = mpath, md5 = unname(tools::md5sum(vtr)))
}

df <- data.frame(canonical_name = c("Aaa", "Bbb"),
                 trait = c(1, 2), stringsAsFactors = FALSE)

test_that("content_id_of returns the file md5", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df)
  expect_identical(taxify:::content_id_of(s$vtr), s$md5)
  expect_true(is.na(taxify:::content_id_of(file.path(dd, "missing.vtr"))))
})

test_that("stored content_id matching the manifest needs no refresh", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df, manifest_cid = "PLACEHOLDER")
  # Rewrite manifest + meta with the true md5.
  s <- stage_static(dd, "demo", df, meta_extra = list(content_id = s$md5),
                    manifest_cid = s$md5)
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
})

test_that("a changed content_id forces a refresh", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df,
                    meta_extra = list(content_id = "stale000000"),
                    manifest_cid = "fresh111111")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_true(taxify:::check_enrichment_version("demo"))
})

test_that("legacy cache with matching bytes is adopted, not re-downloaded", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df)                 # meta has NO content_id
  s <- stage_static(dd, "demo", df, manifest_cid = s$md5)  # manifest = true md5
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
  # The id was written back into meta.json so later sessions skip the hash.
  meta <- jsonlite::read_json(file.path(dirname(s$vtr), "meta.json"),
                              simplifyVector = TRUE)
  expect_identical(meta$content_id, s$md5)
})

test_that("legacy cache with differing bytes triggers a refresh", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df,                 # meta has NO content_id
                    manifest_cid = "not_the_local_md5")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_true(taxify:::check_enrichment_version("demo"))
})

test_that("a bundled/staged copy (no downloaded_at) is never refreshed", {
  # The example database and test mocks are subsets whose bytes differ from the
  # released asset; the gate must leave them alone even against a mismatched id.
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df,
                    meta_extra = list(downloaded_at = NULL),  # drop the marker
                    manifest_cid = "some_other_md5")
  # stage_static seeds downloaded_at; overwrite meta.json without it.
  jsonlite::write_json(list(version = "2026.07", static = TRUE),
                       file.path(dd, "enrichment", "demo", "latest", "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
})

test_that("no content_id in the manifest preserves legacy static behaviour", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_static(dd, "demo", df, manifest_cid = NULL)  # no content_id shipped
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit(options(old), add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
})


# --- Versioned (non-static) enrichments -------------------------------------
# The version label records when a build ran, not what it read. GRIIS 2026.08
# was rebuilt after its GBIF source stopped returning `recordid` and
# republished under the tag it already carried, so a label comparison alone
# holds the pre-rebuild .vtr indefinitely.

# `:::` cannot be assigned through, so reach the environment first; it is a
# reference, so clearing a member here clears the session cache.
reset_manifest_cache <- function() {
  e <- taxify:::.taxify_env
  e$manifest <- NULL
  invisible(NULL)
}

stage_versioned <- function(dd, name, df, meta_extra = list(),
                            manifest_version = "2026.08", manifest_cid = NULL) {
  edir <- file.path(dd, "enrichment", name, "latest")
  dir.create(edir, recursive = TRUE, showWarnings = FALSE)
  vtr <- file.path(edir, paste0(name, ".vtr"))
  vectra::write_vtr(df, vtr)
  meta <- utils::modifyList(
    list(version = "2026.08", static = FALSE, downloaded_at = "2026-08-27"),
    meta_extra, keep.null = TRUE)
  meta <- meta[!vapply(meta, is.null, logical(1))]
  jsonlite::write_json(meta, file.path(edir, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  entry <- list(latest = manifest_version,
                full_url = "https://example.invalid/x.vtr")
  if (!is.null(manifest_cid)) entry$content_id <- manifest_cid
  mf <- list(schema_version = 2L, backends = list(),
             enrichments = stats::setNames(list(entry), name))
  mpath <- file.path(dd, "manifest.json")
  jsonlite::write_json(mf, mpath, pretty = TRUE, auto_unbox = TRUE)
  reset_manifest_cache()                 # fetch_manifest() caches per session
  list(vtr = vtr, manifest = mpath, md5 = unname(tools::md5sum(vtr)))
}

test_that("a same-tag republish refreshes a versioned enrichment", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_versioned(dd, "demo", df,
                       meta_extra = list(content_id = "prerebuild0"),
                       manifest_cid = "rebuilt1111")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit({options(old); reset_manifest_cache()}, add = TRUE)
  expect_true(taxify:::check_enrichment_version("demo"))
})

test_that("a matching content_id needs no refresh despite a bumped label", {
  # The mirror case: a pinned source rebuilt to the same bytes under a new
  # YYYY.MM must not force a re-download.
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_versioned(dd, "demo", df, meta_extra = list(content_id = "same00"),
                       manifest_version = "2026.09", manifest_cid = "same00")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit({options(old); reset_manifest_cache()}, add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
})

test_that("without content ids the version label still decides", {
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_versioned(dd, "demo", df, manifest_version = "2026.09")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit({options(old); reset_manifest_cache()}, add = TRUE)
  expect_true(taxify:::check_enrichment_version("demo"))

  s <- stage_versioned(dd, "demo", df, manifest_version = "2026.08")
  expect_false(taxify:::check_enrichment_version("demo"))
})

test_that("a versioned cache with no downloaded_at is left to the label", {
  # A staged mock deliberately differs from the released bytes; hashing it must
  # not force a full download behind the user's back.
  dd <- tempfile("cid_"); dir.create(dd)
  s <- stage_versioned(dd, "demo", df,
                       meta_extra = list(downloaded_at = NULL),
                       manifest_cid = "some_other_md5")
  old <- options(taxify.data_dir = dd, taxify.manifest_path = s$manifest)
  on.exit({options(old); reset_manifest_cache()}, add = TRUE)
  expect_false(taxify:::check_enrichment_version("demo"))
})

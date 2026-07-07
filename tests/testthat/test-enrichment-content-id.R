# Static enrichments never phone home, but a same-tag republish (a rebuilt .vtr
# re-uploaded under an unchanged release tag) would otherwise leave the local
# cache stale forever. check_enrichment_version() reconciles a static cache
# against the bundled manifest's content_id (md5 of the built .vtr) offline.

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

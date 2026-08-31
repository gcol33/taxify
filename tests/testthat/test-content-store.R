# The content-addressed store: resolving a recorded content_id back to bytes,
# and keeping the build a refresh replaces instead of overwriting the only copy
# on disk (taxify#54).

df <- data.frame(canonical_name = c("Aaa", "Bbb"),
                 trait = c(1, 2), stringsAsFactors = FALSE)
df2 <- data.frame(canonical_name = c("Aaa", "Bbb", "Ccc"),
                  trait = c(1, 2, 3), stringsAsFactors = FALSE)

# Write a .vtr somewhere outside the data dir and return its path + md5, so a
# test can serve it over a file:// manifest URL.
stage_asset <- function(dir, name, data) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  p <- file.path(dir, paste0(name, ".vtr"))
  vectra::write_vtr(data, p)
  list(path = p, md5 = unname(tools::md5sum(p)))
}

file_url <- function(path) {
  paste0("file:///", normalizePath(path, winslash = "/", mustWork = TRUE))
}

# A bundled manifest serving one enrichment from a local file, optionally with
# an immutable content_url beside the rolling one.
write_manifest <- function(dir, name, version, url, content_id,
                           content_url = NULL, kind = "enrichments") {
  entry <- list(latest = version, full_url = url, content_id = content_id,
                static = FALSE)
  if (!is.null(content_url)) entry$content_url <- content_url
  mf <- list(schema_version = 2L, backends = list(), enrichments = list())
  mf[[kind]] <- stats::setNames(list(entry), name)
  path <- file.path(dir, "manifest.json")
  jsonlite::write_json(mf, path, pretty = TRUE, auto_unbox = TRUE)
  path
}

# Every test drives downloads through a bundled file:// manifest, so nothing
# here touches the network.
local_store <- function(env = parent.frame()) {
  dd <- tempfile("store_"); dir.create(dd)
  old <- options(taxify.data_dir = dd)
  withr::defer({
    options(old)
    taxify:::taxify_refresh_manifest()
  }, envir = env)
  dd
}


# ---- URL resolution -------------------------------------------------------

test_that("is_content_key separates a content id from a version label", {
  expect_true(taxify:::is_content_key(strrep("a", 32L)))
  expect_true(taxify:::is_content_key("3e0017815cf679f4e7e28309f57700e5"))
  expect_false(taxify:::is_content_key("2026.08"))
  expect_false(taxify:::is_content_key("latest"))
  expect_false(taxify:::is_content_key(strrep("A", 32L)))  # md5 is lowercase
  expect_false(taxify:::is_content_key(NA_character_))
  expect_false(taxify:::is_content_key(NULL))
})

test_that("the manifest's content_url is used when it names the build asked for", {
  cid <- strrep("b", 32L)
  entry <- list(
    full_url = "https://example.invalid/releases/enrichment-2026.08/demo.vtr",
    content_id = cid,
    content_url = paste0("https://example.invalid/releases/enrichment-2026.08/",
                         "demo-", cid, ".vtr")
  )
  expect_identical(taxify:::content_asset_url(entry, "demo", cid),
                   entry$content_url)
})

test_that("an older build's URL is derived from the release tag", {
  # The manifest records content_url for the CURRENT build only; an id from a
  # lockfile names an earlier one, whose immutable copy sits in the same tag.
  cur <- strrep("b", 32L)
  old <- strrep("c", 32L)
  entry <- list(
    full_url = "https://example.invalid/releases/enrichment-2026.08/demo.vtr",
    content_id = cur,
    content_url = paste0("https://example.invalid/releases/enrichment-2026.08/",
                         "demo-", cur, ".vtr")
  )
  expect_identical(
    taxify:::content_asset_url(entry, "demo", old),
    paste0("https://example.invalid/releases/enrichment-2026.08/demo-", old,
           ".vtr")
  )
})

test_that("a manifest with no content_url still yields the convention URL", {
  cid <- strrep("d", 32L)
  entry <- list(
    full_url = "https://example.invalid/releases/enrichment-2026.08/demo.vtr")
  expect_identical(
    taxify:::content_asset_url(entry, "demo", cid),
    paste0("https://example.invalid/releases/enrichment-2026.08/demo-", cid,
           ".vtr"))
  expect_null(taxify:::content_asset_url(list(), "demo", cid))
  expect_null(taxify:::content_asset_url(NULL, "demo", cid))
})


# ---- Retrieval by content id ----------------------------------------------

test_that("a content-pinned download installs and activates that exact build", {
  dd <- local_store()
  src <- tempfile("src_"); a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5,
                       content_url = file_url(a$path))
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  p <- taxify_download_enrichment("demo", content_id = a$md5, verbose = FALSE)
  expect_true(file.exists(p))
  expect_identical(unname(tools::md5sum(p)), a$md5)
  # Activated: it is the build taxify would now read.
  expect_identical(normalizePath(p),
                   normalizePath(taxify:::enrichment_vtr_path("demo")))

  meta <- jsonlite::read_json(file.path(dirname(p), "meta.json"),
                              simplifyVector = TRUE)
  expect_identical(meta$content_id, a$md5)
  expect_true(isTRUE(meta$pinned))
  expect_identical(meta$version, "2026.08")
})

test_that("an earlier build is fetched from the immutable copy in its tag", {
  # The NeoPlants case: the lockfile pins a build the release has since re-cut,
  # nothing of it is on disk, and the manifest describes only the current build.
  # The immutable copy sits in the same tag under <name>-<content_id>.vtr.
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  b <- stage_asset(tempfile("cur_"), "demo", df2)
  # Publish the earlier build under the convention name, beside the rolling one.
  immutable <- file.path(src, paste0("demo-", a$md5, ".vtr"))
  file.rename(a$path, immutable)
  file.copy(b$path, file.path(src, "demo.vtr"))

  mp <- write_manifest(src, "demo", "2026.08",
                       file_url(file.path(src, "demo.vtr")), b$md5)
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  p <- taxify_download_enrichment("demo", content_id = a$md5, verbose = FALSE)
  expect_identical(unname(tools::md5sum(p)), a$md5)
  expect_identical(normalizePath(p),
                   normalizePath(taxify:::enrichment_vtr_path("demo")))
  # The manifest's own version label describes the current build, not this one,
  # so it is not stamped onto the build fetched.
  meta <- jsonlite::read_json(file.path(dirname(p), "meta.json"),
                              simplifyVector = TRUE)
  expect_null(meta$version)
  expect_identical(meta$content_id, a$md5)
})

test_that("bytes that do not hash to the requested id are refused", {
  dd <- local_store()
  src <- tempfile("src_"); a <- stage_asset(src, "demo", df)
  wrong <- strrep("e", 32L)
  # The manifest serves the file, but under an id it does not have.
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), wrong,
                       content_url = file_url(a$path))
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  expect_error(
    taxify_download_enrichment("demo", content_id = wrong, verbose = FALSE),
    "not the build asked for"
  )
  # Nothing was installed under the id it failed to match.
  expect_false(dir.exists(taxify:::enrichment_dir("demo", wrong)))
})

test_that("a malformed content_id is rejected before any download", {
  dd <- local_store()
  expect_error(
    taxify_download_enrichment("demo", content_id = "2026.08", verbose = FALSE),
    "32-character md5"
  )
})

test_that("content_id is recycled over names, or must match one for one", {
  expect_identical(taxify:::recycle_content_ids(NULL, c("a", "b"), "enrichment"),
                   NULL)
  expect_identical(
    taxify:::recycle_content_ids("x", c("a", "b"), "enrichment"),
    c("x", "x"))
  expect_identical(
    taxify:::recycle_content_ids(c("x", "y"), c("a", "b"), "enrichment"),
    c("x", "y"))
  expect_error(
    taxify:::recycle_content_ids(c("x", "y"), c("a", "b", "c"), "enrichment"),
    "one per enrichment")
})


# ---- Local store: a refetch adds a directory ------------------------------

test_that("refreshing an enrichment keeps the build it replaces", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5)
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  first <- taxify:::download_enrichment("demo", verbose = FALSE)
  expect_identical(unname(tools::md5sum(first)), a$md5)

  # A re-cut under the same tag: same version label, different bytes.
  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.08", file_url(b$path), b$md5)
  taxify:::taxify_refresh_manifest()
  second <- taxify:::download_enrichment("demo", verbose = FALSE)

  expect_identical(unname(tools::md5sum(second)), b$md5)
  # The build it replaced is still on disk, under its own content id.
  kept <- taxify:::local_content_path("demo", a$md5, "enrichment")
  expect_false(is.null(kept))
  expect_identical(unname(tools::md5sum(kept)), a$md5)
  expect_identical(basename(dirname(kept)), a$md5)
})

test_that("archiving can be switched off", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5)
  old <- options(taxify.manifest_path = mp,
                 taxify.keep_enrichment_versions = FALSE)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  taxify:::download_enrichment("demo", verbose = FALSE)
  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.08", file_url(b$path), b$md5)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  expect_null(taxify:::local_content_path("demo", a$md5, "enrichment"))
})

test_that("a build already on disk is activated without a download", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5)
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.08", file_url(b$path), b$md5)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  # Point the manifest at a URL that does not exist: reactivating the archived
  # build must not need it.
  mp <- write_manifest(src, "demo", "2026.08",
                       "https://example.invalid/gone.vtr", b$md5)
  taxify:::taxify_refresh_manifest()

  p <- taxify_download_enrichment("demo", content_id = a$md5, verbose = FALSE)
  expect_identical(unname(tools::md5sum(p)), a$md5)
  expect_identical(normalizePath(p),
                   normalizePath(taxify:::enrichment_vtr_path("demo")))
  # The swap kept the other build: both are still resolvable.
  expect_false(is.null(taxify:::local_content_path("demo", b$md5, "enrichment")))
})

test_that("a pinned build is not refreshed away", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5,
                       content_url = file_url(a$path))
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()

  taxify_download_enrichment("demo", content_id = a$md5, verbose = FALSE)

  # The release moves on; the pin holds.
  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.09", file_url(b$path), b$md5)
  taxify:::taxify_refresh_manifest()
  expect_false(taxify:::check_enrichment_version("demo"))
})

test_that("taxify_store lists every build on disk", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5)
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.08", file_url(b$path), b$md5)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  st <- taxify_store()
  expect_equal(nrow(st), 2L)
  expect_true(all(st$component == "demo"))
  expect_true(all(st$type == "enrichment"))
  expect_identical(sort(st$content_id), sort(c(a$md5, b$md5)))
  expect_equal(sum(st$active), 1L)
  expect_identical(st$content_id[st$active], b$md5)
  expect_identical(taxify_store("nothing_here")$component, character(0L))
})


# ---- Restore --------------------------------------------------------------

test_that("taxify_restore(install = TRUE) puts the locked build back", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5,
                       content_url = file_url(a$path))
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  lock <- list(
    taxify_version = "0.0.0", created = "2026-08-31", r_version = "R",
    backbones = list(),
    enrichments = list(list(name = "demo", version = "2026.08",
                            content_id = a$md5, installed = TRUE))
  )
  expect_identical(taxify_restore(lock, verbose = FALSE)$status, "ok")

  # A re-cut replaces the active build; the pin now reports drift.
  b <- stage_asset(src, "demo", df2)
  mp <- write_manifest(src, "demo", "2026.08", file_url(b$path), b$md5,
                       content_url = file_url(b$path))
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)
  expect_identical(taxify_restore(lock, verbose = FALSE)$status, "content_drift")

  # And one call puts the locked build back.
  out <- taxify_restore(lock, install = TRUE, verbose = FALSE)
  expect_identical(out$status, "ok")
  expect_true(out$restored)
  expect_identical(unname(tools::md5sum(taxify:::enrichment_vtr_path("demo"))),
                   a$md5)
  # The build it displaced was kept, so the restore is reversible.
  expect_false(is.null(taxify:::local_content_path("demo", b$md5, "enrichment")))
})

test_that("an unrecoverable build leaves its row reporting drift", {
  dd <- local_store()
  src <- tempfile("src_")
  a <- stage_asset(src, "demo", df)
  mp <- write_manifest(src, "demo", "2026.08", file_url(a$path), a$md5)
  old <- options(taxify.manifest_path = mp)
  on.exit(options(old), add = TRUE)
  taxify:::taxify_refresh_manifest()
  taxify:::download_enrichment("demo", verbose = FALSE)

  # A build overwritten before immutable copies were published: its id resolves
  # to a URL that is not there.
  lock <- list(
    backbones = list(),
    enrichments = list(list(name = "demo", version = "2026.08",
                            content_id = strrep("f", 32L), installed = TRUE))
  )
  out <- suppressWarnings(taxify_restore(lock, install = TRUE, verbose = FALSE))
  expect_identical(out$status, "content_drift")
  expect_false(out$restored)
  # The installed build is untouched.
  expect_identical(unname(tools::md5sum(taxify:::enrichment_vtr_path("demo"))),
                   a$md5)
})

test_that("restore reports rows it cannot pin without touching them", {
  dd <- local_store()
  lock <- list(backbones = list(),
               enrichments = list(list(name = "demo", version = "2026.08")))
  out <- taxify_restore(lock, install = TRUE, verbose = FALSE)
  expect_identical(out$status, "missing")
  expect_false(out$restored)
})

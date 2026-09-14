# taxify_pin() holds an installed build in place, and taxify_restore(install =
# TRUE) pins every build matching its lockfile, including one it did not need to
# fetch. The version checks behind taxify(), install_backbones() and the
# enrichment doors all leave a pinned build alone. Temp data dirs only.

pin_df <- data.frame(canonical_name = c("Aaa", "Bbb"), trait = c(1, 2),
                     stringsAsFactors = FALSE)

# A data dir holding a backbone and/or an enrichment build, each with a
# meta.json that the manifest served by `serve_stale()` has moved past.
pin_fixture <- function(backbones = "euromed", enrichments = "demo",
                        meta_extra = list(), env = parent.frame()) {
  dd <- withr::local_tempdir(.local_envir = env)
  withr::local_options(list(taxify.data_dir = dd, taxify.offline = FALSE),
                       .local_envir = env)
  stage <- function(dir, name) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    vtr <- file.path(dir, paste0(name, ".vtr"))
    vectra::write_vtr(pin_df, vtr)
    meta <- utils::modifyList(list(version = "2026.08", pinned = FALSE,
                                   content_id = unname(tools::md5sum(vtr)),
                                   downloaded_at = "2026-08-01"), meta_extra)
    jsonlite::write_json(meta, file.path(dir, "meta.json"),
                         pretty = TRUE, auto_unbox = TRUE)
    unname(tools::md5sum(vtr))
  }
  cids <- c(
    vapply(backbones, function(b) stage(file.path(dd, b, "latest"), b), ""),
    vapply(enrichments, function(e) stage(file.path(dd, "enrichment", e, "latest"), e), "")
  )

  env_ <- taxify:::.taxify_env
  keys <- c(paste0(".version_checked.", backbones),
            paste0(".enrichment_version_checked.", enrichments), "manifest")
  saved <- lapply(keys, function(k) env_[[k]])
  withr::defer({
    for (i in seq_along(keys)) env_[[keys[[i]]]] <- saved[[i]]
    for (b in backbones) taxify:::set_backbone_path(b, NULL)
    for (e in enrichments) taxify:::set_backbone_path(paste0("enrichment_", e), NULL)
  }, envir = env)
  for (k in keys) env_[[k]] <- NULL

  list(dd = dd, cids = cids)
}

serve_stale <- function(backbones = "euromed", enrichments = "demo") {
  entry <- list(latest = "2026.09", full_url = "file:///nowhere/x.vtr",
                content_id = strrep("e", 32L))
  env_ <- taxify:::.taxify_env
  env_$manifest <- list(
    schema_version = 2L,
    backends = stats::setNames(rep(list(entry), length(backbones)), backbones),
    enrichments = stats::setNames(rep(list(entry), length(enrichments)),
                                  enrichments))
}

meta_of <- function(dir) {
  jsonlite::read_json(file.path(dir, "meta.json"), simplifyVector = TRUE)
}


test_that("taxify_pin() pins a backbone and an enrichment and reports their ids", {
  fx <- pin_fixture()

  msgs <- capture_messages(out <- taxify_pin(c("euromed", "demo")))
  expect_match(msgs[[1]], sprintf("Pinned backbone 'euromed' to build %s",
                                  substr(fx$cids[["euromed"]], 1L, 10L)))
  expect_match(msgs[[2]], "Pinned enrichment 'demo' to build")
  expect_identical(out$component, c("euromed", "demo"))
  expect_identical(out$type, c("backbone", "enrichment"))
  expect_identical(out$content_id, unname(fx$cids))
  expect_true(all(out$pinned))
  expect_true(isTRUE(meta_of(file.path(fx$dd, "euromed", "latest"))$pinned))
  expect_true(isTRUE(meta_of(file.path(fx$dd, "enrichment", "demo", "latest"))$pinned))

  out <- taxify_pin("euromed", pin = FALSE, verbose = FALSE)
  expect_false(out$pinned)
  expect_false(isTRUE(meta_of(file.path(fx$dd, "euromed", "latest"))$pinned))
})

test_that("a pin records the content id of a build whose meta carries none", {
  fx <- pin_fixture(enrichments = character(0))
  meta_path <- file.path(fx$dd, "euromed", "latest", "meta.json")
  jsonlite::write_json(list(version = "2026.08"), meta_path, auto_unbox = TRUE)

  out <- taxify_pin("euromed", verbose = FALSE)
  expect_identical(out$content_id, unname(fx$cids[["euromed"]]))
  expect_identical(meta_of(dirname(meta_path))$content_id,
                   unname(fx$cids[["euromed"]]))
})

test_that("taxify_pin() refuses a name that is not installed and writes nothing", {
  fx <- pin_fixture()
  before <- meta_of(file.path(fx$dd, "euromed", "latest"))

  expect_error(taxify_pin(c("euromed", "nope"), verbose = FALSE),
               "'nope' is not installed .* nothing to pin")
  expect_identical(meta_of(file.path(fx$dd, "euromed", "latest")), before)
  expect_error(taxify_pin("demo", kind = "backbone", verbose = FALSE),
               "No backbone 'demo' is installed")
})

test_that("a name installed as both kinds needs kind =", {
  fx <- pin_fixture(backbones = "wcvp", enrichments = "wcvp")
  expect_error(taxify_pin("wcvp", verbose = FALSE), "say which with kind")
  out <- taxify_pin("wcvp", kind = "enrichment", verbose = FALSE)
  expect_identical(out$type, "enrichment")
  expect_false(isTRUE(meta_of(file.path(fx$dd, "wcvp", "latest"))$pinned))
})

test_that("taxify_pin() refuses the read-only example database", {
  withr::local_options(list(taxify.data_dir = taxify_example_data()))
  expect_error(taxify_pin("wfo", verbose = FALSE), "read-only")
})

test_that("every version check leaves a pinned build in place", {
  fx <- pin_fixture()
  serve_stale()

  expect_identical(taxify:::backbone_version_state("euromed"), "stale")
  expect_true(taxify:::check_enrichment_version("demo"))

  taxify_pin(c("euromed", "demo"), verbose = FALSE)
  expect_identical(taxify:::backbone_version_state("euromed"), "pinned")
  expect_false(taxify:::check_enrichment_version("demo"))

  downloads <- character(0)
  with_mocked_bindings(
    download_backbone = function(name, ...) { downloads <<- c(downloads, name); NULL },
    download_enrichment = function(name, ...) { downloads <<- c(downloads, name); NULL },
    ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
      taxify:::versioned_vtr_path(backend$name, "latest")
    },
    {
      expect_identical(taxify:::refresh_backbone("euromed", verbose = FALSE),
                       "pinned")
      expect_message(install_backbones("euromed", verbose = FALSE),
                     "pinned to build .*taxify_pin\\(\"euromed\", pin = FALSE\\)")
      expect_identical(
        taxify:::ensure_enrichment("demo", verbose = FALSE),
        file.path(fx$dd, "enrichment", "demo", "latest", "demo.vtr"))
    }
  )
  expect_length(downloads, 0L)

  taxify_pin(c("euromed", "demo"), pin = FALSE, verbose = FALSE)
  expect_identical(taxify:::backbone_version_state("euromed"), "stale")
  expect_true(taxify:::check_enrichment_version("demo"))
})

test_that("taxify_restore(install = TRUE) pins builds that already match the lock", {
  fx <- pin_fixture()
  lock <- list(
    backbones = list(list(name = "euromed", version = "2026.08",
                          content_id = fx$cids[["euromed"]], installed = TRUE)),
    enrichments = list(list(name = "demo", version = "2026.08",
                            content_id = fx$cids[["demo"]], installed = TRUE),
                       list(name = "absent", version = "2026.08",
                            content_id = strrep("a", 32L), installed = TRUE)))

  checked <- taxify_restore(lock, verbose = FALSE)
  expect_null(checked$pinned)
  expect_false(isTRUE(meta_of(file.path(fx$dd, "euromed", "latest"))$pinned))

  withr::local_options(list(taxify.offline = TRUE))
  out <- suppressWarnings(taxify_restore(lock, install = TRUE, verbose = FALSE))
  expect_identical(out$status, c("ok", "ok", "missing"))
  expect_identical(out$restored, c(FALSE, FALSE, FALSE))
  expect_identical(out$pinned, c(TRUE, TRUE, FALSE))
  expect_true(isTRUE(meta_of(file.path(fx$dd, "euromed", "latest"))$pinned))
  expect_true(isTRUE(meta_of(file.path(fx$dd, "enrichment", "demo", "latest"))$pinned))
})

# install_backbones() refreshes an installed backbone by the same comparison
# taxify() runs once per session (#82), and download_backbone() patches only
# the build a delta was cut against, verifies what it installs against the
# manifest content id, and records how the bytes were obtained (#83). Every
# asset is served from a file:// manifest in a temporary data directory.

md5_of <- function(p) unname(tools::md5sum(p))
file_url <- function(p) paste0("file:///", normalizePath(p, winslash = "/"))

# A temporary data directory holding one downloaded build of `name`, plus a
# release directory with the bytes the manifest will serve. Restores the
# manifest cache, the session flags and the options on exit.
refresh_fixture <- function(name = "euromed", meta_extra = list(),
                            env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  data_dir <- file.path(root, "data")
  slot <- file.path(data_dir, name, "latest")
  dir.create(slot, recursive = TRUE)
  old_vtr <- file.path(slot, paste0(name, ".vtr"))
  writeBin(as.raw(rep(1:200, 5)), old_vtr)
  meta <- utils::modifyList(
    list(version = "2026.08", pinned = FALSE, content_id = md5_of(old_vtr),
         downloaded_at = "2026-08-01"),
    meta_extra)
  jsonlite::write_json(meta, file.path(slot, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)

  rel <- file.path(root, "release")
  dir.create(rel)
  new_vtr <- file.path(rel, paste0(name, ".vtr"))
  writeBin(as.raw(c(rep(1:100, 5), rep(50:149, 5))), new_vtr)

  env_ <- taxify:::.taxify_env
  flag <- paste0(".version_checked.", name)
  old_manifest <- env_$manifest
  old_flag <- env_[[flag]]
  withr::defer({
    env_$manifest <- old_manifest
    env_[[flag]] <- old_flag
    taxify:::set_backbone_path(name, NULL)
  }, envir = env)
  withr::local_options(list(taxify.data_dir = data_dir, taxify.offline = FALSE,
                            taxify.keep_backbone_versions = FALSE),
                       .local_envir = env)
  taxify:::set_backbone_path(name, NULL)
  env_[[flag]] <- NULL

  list(name = name, data_dir = data_dir, slot = slot, old_vtr = old_vtr,
       new_vtr = new_vtr, rel = rel)
}

serve <- function(fx, entry = list()) {
  base <- list(latest = "2026.09", full_url = file_url(fx$new_vtr),
               content_id = md5_of(fx$new_vtr))
  env_ <- taxify:::.taxify_env
  env_$manifest <- list(
    schema_version = 2L,
    backends = stats::setNames(list(utils::modifyList(base, entry)), fx$name),
    enrichments = list())
}

slot_meta <- function(fx) {
  jsonlite::read_json(file.path(fx$slot, "meta.json"), simplifyVector = TRUE)
}

installed_stub <- function(backend, version = "latest", verbose = TRUE) {
  taxify:::versioned_vtr_path(backend$name, "latest")
}


# ---- install_backbones() (#82) ----

test_that("install_backbones() replaces a build the manifest has moved past", {
  fx <- refresh_fixture()
  serve(fx)

  with_mocked_bindings(
    ensure_backbone = installed_stub,
    expect_message(out <- install_backbones(fx$name, verbose = FALSE),
                   "EUROMED backbone ready .*full download")
  )

  expect_identical(out, fx$name)
  expect_identical(md5_of(fx$old_vtr), md5_of(fx$new_vtr))
  m <- slot_meta(fx)
  expect_identical(m$content_id, md5_of(fx$new_vtr))
  expect_identical(m$version, "2026.09")
  expect_identical(m$install_path, "full")
})

test_that("install_backbones() leaves a current build alone", {
  fx <- refresh_fixture()
  serve(fx, list(content_id = md5_of(fx$old_vtr), latest = "2026.08"))
  before <- md5_of(fx$old_vtr)

  called <- FALSE
  with_mocked_bindings(
    ensure_backbone = installed_stub,
    download_backbone = function(...) { called <<- TRUE; NULL },
    expect_silent(install_backbones(fx$name, verbose = FALSE))
  )

  expect_false(called)
  expect_identical(md5_of(fx$old_vtr), before)
})

test_that("install_backbones() keeps a pinned build and says so", {
  fx <- refresh_fixture(meta_extra = list(pinned = TRUE))
  serve(fx)
  before <- md5_of(fx$old_vtr)

  called <- FALSE
  with_mocked_bindings(
    ensure_backbone = installed_stub,
    download_backbone = function(...) { called <<- TRUE; NULL },
    expect_message(out <- install_backbones(fx$name, verbose = FALSE),
                   sprintf("pinned to build %s", substr(before, 1L, 10L)))
  )

  expect_false(called)
  expect_identical(out, fx$name)
  expect_identical(md5_of(fx$old_vtr), before)
  expect_true(isTRUE(slot_meta(fx)$pinned))
})

test_that("install_backbones() and taxify()'s session check share one comparison", {
  fx <- refresh_fixture()
  serve(fx)

  states <- character(0)
  with_mocked_bindings(
    ensure_backbone = installed_stub,
    backbone_version_state = function(bb) { states <<- c(states, bb); "current" },
    {
      install_backbones(fx$name, verbose = FALSE)
      env_ <- taxify:::.taxify_env
      env_[[paste0(".version_checked.", fx$name)]] <- NULL
      taxify:::ensure_backbones_current(fx$name, verbose = FALSE)
    }
  )
  expect_identical(states, c(fx$name, fx$name))
})


# ---- download_backbone() patch gate and verification (#83) ----

test_that("a patch cut against another build is not fetched", {
  fx <- refresh_fixture()
  delta <- file.path(fx$rel, "euromed.xdelta")
  writeLines("not a patch", delta)
  serve(fx, list(delta_url = file_url(delta),
                 delta_from_content_id = strrep("f", 32L)))

  fetched <- character(0)
  real_fetch <- taxify:::fetch_asset_file
  with_mocked_bindings(
    has_xdelta3 = function() TRUE,
    fetch_asset_file = function(url, tmp_path, label, verbose = TRUE) {
      fetched <<- c(fetched, url)
      real_fetch(url, tmp_path, label, verbose = verbose)
    },
    expect_message(
      download_backbone(fx$name, version = "latest", verbose = FALSE),
      "full download\\); patch not used: it applies to build ffffffffff"
    )
  )

  expect_identical(fetched, file_url(fx$new_vtr))
  expect_identical(slot_meta(fx)$install_path, "full")
  expect_identical(md5_of(fx$old_vtr), md5_of(fx$new_vtr))
})

test_that("a delta that records no base build is not applied", {
  fx <- refresh_fixture()
  delta <- file.path(fx$rel, "euromed.xdelta")
  writeLines("not a patch", delta)
  serve(fx, list(delta_url = file_url(delta), delta_from = "2026.08"))

  with_mocked_bindings(
    has_xdelta3 = function() TRUE,
    expect_message(
      download_backbone(fx$name, version = "latest", verbose = FALSE),
      "does not record which build it applies to"
    )
  )
  expect_identical(slot_meta(fx)$install_path, "full")
})

test_that("a patched file that does not hash to the manifest id is replaced by the full asset", {
  fx <- refresh_fixture()
  serve(fx)

  with_mocked_bindings(
    try_backbone_patch = function(backbone_name, entry, vtr_path, dir, tmp_path,
                                  store_root, verbose = TRUE) {
      writeBin(as.raw(rep(9L, 32)), tmp_path)
      list(patched = TRUE, note = NULL)
    },
    expect_message(
      download_backbone(fx$name, version = "latest", verbose = FALSE),
      "full download\\); patch not used: the patched file hashed to"
    )
  )
  expect_identical(md5_of(fx$old_vtr), md5_of(fx$new_vtr))
  expect_identical(slot_meta(fx)$install_path, "full")
})

test_that("a download that does not hash to the manifest id stops and installs nothing", {
  fx <- refresh_fixture()
  before <- md5_of(fx$old_vtr)
  meta_before <- slot_meta(fx)
  serve(fx, list(content_id = strrep("0", 32L)))

  expect_error(
    download_backbone(fx$name, version = "latest", verbose = FALSE),
    "hashes to .*not the content id the manifest records"
  )
  expect_identical(md5_of(fx$old_vtr), before)
  expect_identical(slot_meta(fx), meta_before)
  store_root <- dirname(fx$slot)
  expect_length(list.files(store_root, pattern = "\\.tmp$"), 0L)
})

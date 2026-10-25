# A backbone not on disk is installed only by an installing verb, after a yes
# in an interactive session, or with taxify.auto_download. Every test serves
# the asset from a file:// manifest, which offline mode still resolves.

local_release <- function(env = parent.frame()) {
  tmp <- tempfile("taxify_consent_")
  dir.create(tmp)
  withr::defer(unlink(tmp, recursive = TRUE), envir = env)
  asset <- file.path(tmp, "euromed-asset.vtr")
  writeBin(as.raw(rep(3L, 64)), asset)
  url <- paste0("file:///", normalizePath(asset, winslash = "/"))

  orig_manifest <- .taxify_env$manifest
  withr::defer(.taxify_env$manifest <- orig_manifest, envir = env)
  .taxify_env$manifest <- list(
    euromed = list(latest = "2026.09", full_url = url,
                   content_id = unname(tools::md5sum(asset))))

  data_dir <- file.path(tmp, "data")
  withr::local_options(taxify.data_dir = data_dir,
                       taxify.auto_download = NULL, .local_envir = env)
  withr::local_envvar(TAXIFY_AUTO_DOWNLOAD = "", .local_envir = env)
  data_dir
}

test_that("an implicit install is declined in a non-interactive session", {
  data_dir <- local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)

  err <- expect_error(
    download_backbone("euromed", verbose = FALSE),
    class = "taxify_download_declined"
  )
  expect_match(conditionMessage(err), 'install_backbones("euromed")',
               fixed = TRUE)
  expect_false(file.exists(file.path(data_dir, "euromed", "latest",
                                     "euromed.vtr")))
})

test_that("a declined install does not fall back to a build from source", {
  local_release()
  local_mocked_bindings(
    confirm_download = function(question) FALSE,
    taxify_build = function(...) stop("built from source")
  )
  expect_error(ensure_backbone(resolve_backend("euromed"), verbose = FALSE),
               class = "taxify_download_declined")
})

test_that("an installing verb, a yes, or the option allows the install", {
  local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)
  p <- with_download_consent(download_backbone("euromed", verbose = FALSE))
  expect_true(file.exists(p))

  local_release()
  local_mocked_bindings(confirm_download = function(question) TRUE)
  expect_true(file.exists(download_backbone("euromed", verbose = FALSE)))

  local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)
  withr::local_options(taxify.auto_download = TRUE)
  expect_true(file.exists(download_backbone("euromed", verbose = FALSE)))

  local_release()
  withr::local_envvar(TAXIFY_AUTO_DOWNLOAD = "true")
  expect_true(file.exists(download_backbone("euromed", verbose = FALSE)))
})

test_that("taxify_download() and install_backbones() are consent", {
  local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)
  p <- taxify_download("euromed", verbose = FALSE)
  expect_true(file.exists(p[["euromed"]]))

  local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)
  expect_identical(install_backbones("euromed", verbose = FALSE), "euromed")
})

test_that("refreshing an installed backbone is not gated", {
  data_dir <- local_release()
  slot <- file.path(data_dir, "euromed", "latest")
  dir.create(slot, recursive = TRUE)
  writeBin(as.raw(rep(9L, 64)), file.path(slot, "euromed.vtr"))
  local_mocked_bindings(confirm_download = function(question) FALSE)

  p <- download_backbone("euromed", verbose = FALSE)
  expect_identical(readBin(p, "raw", 65L), as.raw(rep(3L, 64)))
})

test_that("a first taxify() call on an empty data directory asks first", {
  data_dir <- local_release()
  local_mocked_bindings(confirm_download = function(question) FALSE)
  err <- expect_error(resolve_default_backend(verbose = FALSE),
                      class = "taxify_download_declined")
  expect_match(conditionMessage(err), "install_backbones(c(", fixed = TRUE)
  expect_false(dir.exists(data_dir))
})

test_that("a download clears the temp files an interrupted one left", {
  data_dir <- local_release()
  root <- file.path(data_dir, "euromed")
  dir.create(file.path(root, "latest"), recursive = TRUE)
  stale <- c(file.path(root, "old.vtr.tmp.curltmp"),
             file.path(root, "latest", "older.vtr.tmp"))
  fresh <- file.path(root, "inflight.vtr.tmp.curltmp")
  for (f in c(stale, fresh)) writeBin(as.raw(1:8), f)
  Sys.setFileTime(stale, Sys.time() - 7200)

  with_download_consent(download_backbone("euromed", verbose = FALSE))
  expect_false(any(file.exists(stale)))
  expect_true(file.exists(fresh))
})

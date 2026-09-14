# vectra accepts a .vtri index whose stamp (row count, row-group count, column
# position) matches the store, whatever the store's content, so an index left
# beside a replaced store of the same shape prunes by the old keys and drops
# matching rows (gcol33/vectra#13). Installing or activating a build must never
# leave another build's indexes beside it.

index_fixture_df <- function(prefix) {
  data.frame(canonical_name = sprintf("%s species%03d", prefix, 1:100),
             val = 1:100, stringsAsFactors = FALSE)
}

index_files_of <- function(vtr) {
  basename(taxify:::vtr_index_files(vtr))
}

n_hits <- function(vtr, name) {
  nrow(vectra::collect(vectra::filter(vectra::tbl(vtr), canonical_name == name)))
}

test_that("a stale index really does drop rows, so the guard is load-bearing", {
  dir <- withr::local_tempdir()
  vtr <- file.path(dir, "demo.vtr")
  vectra::write_vtr(index_fixture_df("Old"), vtr)
  vectra::create_index(vtr, "canonical_name")
  vectra::write_vtr(index_fixture_df("New"), vtr)
  skip_if(n_hits(vtr, "New species042") == 1L,
          "this vectra rejects an index built for other content")
  expect_identical(n_hits(vtr, "New species042"), 0L)
})

test_that("install_vtr_file() drops the replaced store's indexes only", {
  dir <- withr::local_tempdir()
  vtr <- file.path(dir, "demo.vtr")
  vectra::write_vtr(index_fixture_df("Old"), vtr)
  vectra::create_index(vtr, "canonical_name")
  vectra::create_index(vtr, "val")
  other <- file.path(dir, "demo_name_lookup.vtr")
  vectra::write_vtr(index_fixture_df("Old"), other)
  vectra::create_index(other, "canonical_name")

  tmp <- file.path(dir, "incoming.tmp")
  vectra::write_vtr(index_fixture_df("New"), tmp)
  taxify:::install_vtr_file(tmp, vtr)

  expect_length(index_files_of(vtr), 0L)
  expect_false(file.exists(tmp))
  expect_identical(n_hits(vtr, "New species042"), 1L)
  expect_length(index_files_of(other), 1L)
})

test_that("download_backbone() does not keep the indexes of the build it replaces", {
  root <- withr::local_tempdir()
  data_dir <- file.path(root, "data")
  slot <- file.path(data_dir, "euromed", "latest")
  dir.create(slot, recursive = TRUE)
  vtr <- file.path(slot, "euromed.vtr")
  vectra::write_vtr(index_fixture_df("Old"), vtr)
  vectra::create_index(vtr, "canonical_name")

  new_vtr <- file.path(root, "euromed.vtr")
  vectra::write_vtr(index_fixture_df("New"), new_vtr)

  env <- taxify:::.taxify_env
  old_manifest <- env$manifest
  withr::defer(env$manifest <- old_manifest)
  env$manifest <- list(schema_version = 2L, enrichments = list(),
    backends = list(euromed = list(
      latest = "2026.09",
      full_url = paste0("file:///", normalizePath(new_vtr, winslash = "/")),
      content_id = unname(tools::md5sum(new_vtr)))))
  withr::local_options(list(taxify.data_dir = data_dir,
                            taxify.keep_backbone_versions = FALSE))

  suppressMessages(download_backbone("euromed", version = "latest",
                                     verbose = FALSE))
  expect_length(index_files_of(vtr), 0L)
  expect_identical(n_hits(vtr, "New species042"), 1L)
})

# Two builds of one backbone with the same shape, each carrying its own index.
store_fixture <- function(env = parent.frame()) {
  data_dir <- withr::local_tempdir(.local_envir = env)
  withr::local_options(list(taxify.data_dir = data_dir), .local_envir = env)
  act <- file.path(data_dir, "euromed", "latest")
  dir.create(act, recursive = TRUE)
  a_vtr <- file.path(act, "euromed.vtr")
  vectra::write_vtr(index_fixture_df("Aaa"), a_vtr)
  vectra::create_index(a_vtr, "canonical_name")
  a_cid <- unname(tools::md5sum(a_vtr))
  jsonlite::write_json(list(version = "2026.08", content_id = a_cid),
                       file.path(act, "meta.json"), auto_unbox = TRUE)

  tmp <- file.path(data_dir, "b.vtr")
  vectra::write_vtr(index_fixture_df("Bbb"), tmp)
  b_cid <- unname(tools::md5sum(tmp))
  b_dir <- file.path(data_dir, "euromed", b_cid)
  dir.create(b_dir)
  b_vtr <- file.path(b_dir, "euromed.vtr")
  file.rename(tmp, b_vtr)
  vectra::create_index(b_vtr, "canonical_name")
  jsonlite::write_json(list(version = "2026.09", content_id = b_cid),
                       file.path(b_dir, "meta.json"), auto_unbox = TRUE)

  list(data_dir = data_dir, act_vtr = a_vtr, a_cid = a_cid, b_cid = b_cid)
}

test_that("activating a build keeps each build's indexes with its own store", {
  fx <- store_fixture()

  suppressMessages(taxify:::activate_content_build("euromed", fx$b_cid,
                                                   "backbone", verbose = FALSE))
  expect_identical(n_hits(fx$act_vtr, "Bbb species042"), 1L)
  expect_length(index_files_of(fx$act_vtr), 1L)
  a_arch <- file.path(fx$data_dir, "euromed", fx$a_cid, "euromed.vtr")
  expect_identical(n_hits(a_arch, "Aaa species042"), 1L)

  suppressMessages(taxify:::activate_content_build("euromed", fx$a_cid,
                                                   "backbone", verbose = FALSE))
  expect_identical(n_hits(fx$act_vtr, "Aaa species042"), 1L)
  expect_length(index_files_of(fx$act_vtr), 1L)
})

test_that("activation drops an active index that archiving left in the slot", {
  fx <- store_fixture()
  # An archive already holding a build of the active id, at a different size,
  # makes archive_active_build() leave the active files where they are.
  arc <- file.path(fx$data_dir, "euromed", fx$a_cid)
  dir.create(arc)
  writeLines("not the same build", file.path(arc, "euromed.vtr"))
  vectra::create_index(fx$act_vtr, "val")

  suppressMessages(taxify:::activate_content_build("euromed", fx$b_cid,
                                                   "backbone", verbose = FALSE))
  expect_identical(index_files_of(fx$act_vtr), "euromed.vtr.canonical_name.vtri")
  expect_identical(n_hits(fx$act_vtr, "Bbb species042"), 1L)
})

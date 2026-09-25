# The session path cache is scoped by data directory: a path cached under one
# data dir answers only there, and is found again when that dir is restored.

test_that("a cached path belongs to the data directory it was set under", {
  dd1 <- withr::local_tempdir()
  dd2 <- withr::local_tempdir()
  withr::local_options(list(taxify.data_dir = dd1))

  set_backbone_path("wfo", "first/wfo.vtr")
  expect_equal(get_backbone_path("wfo"), "first/wfo.vtr")

  options(taxify.data_dir = dd2)
  expect_null(get_backbone_path("wfo"))
  set_backbone_path("wfo", "second/wfo.vtr")
  expect_equal(get_backbone_path("wfo"), "second/wfo.vtr")

  options(taxify.data_dir = dd1)
  expect_equal(get_backbone_path("wfo"), "first/wfo.vtr")

  set_backbone_path("wfo", NULL)
  expect_null(get_backbone_path("wfo"))
  options(taxify.data_dir = dd2)
  set_backbone_path("wfo", NULL)
  expect_null(get_backbone_path("wfo"))
})


test_that("a mock pinned under another data dir does not shadow the example database", {
  mock <- mock_backbone_vtr()
  dd <- withr::local_tempdir()
  withr::local_options(list(taxify.data_dir = dd, taxify.offline = TRUE))
  set_backbone_path("wfo", mock)

  options(taxify.data_dir = taxify_example_data())
  r <- taxify("Robinia pseudoacacia", backbone = "wfo", verbose = FALSE)
  expect_equal(r$accepted_name, "Robinia pseudoacacia")

  options(taxify.data_dir = dd)
  set_backbone_path("wfo", NULL)
})

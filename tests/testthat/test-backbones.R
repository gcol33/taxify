test_that("backbone registry lists all 17 supported backbones", {
  reg <- taxify:::.backbone_registry()
  expect_equal(nrow(reg), 17L)
  expect_setequal(
    reg$name,
    c("wfo", "col", "gbif", "itis", "ncbi", "ott", "worms", "euromed",
      "fungorum", "algaebase", "fishbase", "sealifebase", "reptiledb",
      "lcvp", "wcvp", "mdd", "avilist")
  )
  expect_false(any(is.na(reg$scope)))
  expect_false(any(is.na(reg$source)))
})

test_that("every registry name resolves to a matching backbone (no drift)", {
  for (nm in taxify:::backbone_names()) {
    be <- taxify:::resolve_backend(nm)
    expect_s3_class(be, "taxify_backend")
    expect_identical(be$name, nm)
  }
})

test_that("resolve_backend error lists the registry backbones", {
  err <- tryCatch(taxify:::resolve_backend("nope"), error = function(e) conditionMessage(e))
  for (nm in taxify:::backbone_names()) {
    expect_true(grepl(nm, err, fixed = TRUE))
  }
})

test_that("list_backbones returns one row per backbone with scope and installed flag", {
  bb <- list_backbones(verbose = FALSE)
  expect_equal(nrow(bb), 17L)
  expect_true(all(c("name", "scope", "n_names", "size_mb", "version",
                    "installed", "source") %in% names(bb)))
  expect_type(bb$installed, "logical")
  expect_false(any(is.na(bb$installed)))
  expect_setequal(bb$name, taxify:::backbone_names())
})

test_that("taxify_databases stacks backbones and enrichments under a type column", {
  db <- taxify_databases(verbose = FALSE)
  expect_true(all(c("type", "name", "scope", "n_rows", "version",
                    "installed", "source") %in% names(db)))
  expect_setequal(unique(db$type), c("backbone", "enrichment"))
  expect_equal(sum(db$type == "backbone"), 17L)
})

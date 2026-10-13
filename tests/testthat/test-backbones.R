test_that("backbone registry lists 19 taxon and 2 syntaxon backbones", {
  reg <- taxify:::.backbone_registry()
  expect_equal(nrow(reg), 21L)
  expect_setequal(
    reg$name[reg$code == "taxon"],
    c("wfo", "col", "colxr", "gbif", "itis", "ncbi", "ott", "worms", "euromed",
      "fungorum", "algaebase", "fishbase", "sealifebase", "reptiledb",
      "lcvp", "wcvp", "mdd", "avilist", "lpsn")
  )
  expect_setequal(reg$name[reg$code == "syntaxon"], c("evc", "vegcz"))
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
  expect_equal(nrow(bb), 21L)
  expect_true(all(c("name", "title", "scope", "n_names", "size_mb", "version",
                    "source_date", "installed", "code", "source") %in%
                    names(bb)))
  expect_type(bb$installed, "logical")
  expect_false(any(is.na(bb$installed)))
  expect_setequal(bb$name, taxify:::backbone_names())
  expect_false(any(is.na(bb$title) | !nzchar(bb$title)))
})

test_that("taxify_databases stacks backbones and enrichments under a type column", {
  db <- taxify_databases(verbose = FALSE)
  expect_true(all(c("type", "name", "scope", "n_rows", "version",
                    "source_date", "installed", "source") %in% names(db)))
  expect_setequal(unique(db$type), c("backbone", "enrichment"))
  expect_equal(sum(db$type == "backbone"), 21L)
})

test_that("backbone_fixed_kingdom names the kingdom of single-kingdom backbones", {
  expect_equal(backbone_fixed_kingdom(c("wfo", "fungorum", "gbif", "nope")),
               c("plantae", "fungi", NA, NA))
  # Every non-NA value is in the coarse vocabulary the enrichment build checks
  # a source's declared kingdoms against.
  fixed <- backbone_fixed_kingdom(backbone_names())
  fixed <- fixed[!is.na(fixed)]
  expect_equal(normalize_kingdom_group(fixed), fixed)
})

test_that("normalize_kingdom_group folds backbone spellings to the coarse set", {
  expect_equal(
    normalize_kingdom_group(c("Animalia", "Viridiplantae", "Metazoa", "plants",
                              "Chromista", "unknown", "", NA)),
    c("animalia", "plantae", "animalia", "plantae", "chromista", NA, NA, NA))
})

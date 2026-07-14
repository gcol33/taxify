# Default backend: taxify(backend = NULL) matches against every installed
# backbone in priority order (first-match fallback pick), and a fresh setup
# installs COL + GBIF + ITIS. The ordering/resolution logic is pure; the
# integration checks run against the bundled example database (no network).

backbone_ready <- function(be) {
  file.exists(file.path(taxify_example_data(), be, "latest", paste0(be, ".vtr")))
}

test_that(".backbone_priority() is total, COL first, GBIF before ITIS", {
  pr <- taxify:::.backbone_priority()
  expect_setequal(pr, taxify:::backbone_names())   # covers every backbone once
  expect_identical(pr[1], "col")
  expect_lt(match("gbif", pr), match("itis", pr))  # COL > GBIF > ITIS
  # domain authorities outrank the broad aggregators
  expect_lt(match("worms", pr), match("gbif", pr))
})

test_that("order_by_priority() sorts to priority and puts unknown names last", {
  expect_identical(taxify:::order_by_priority(c("itis", "col", "gbif")),
                   c("col", "gbif", "itis"))
  expect_identical(taxify:::order_by_priority(c("gbif", "zzz", "col")),
                   c("col", "gbif", "zzz"))
})

test_that(".default_backbone_set() is COL, GBIF, ITIS in priority order", {
  expect_identical(taxify:::.default_backbone_set(), c("col", "gbif", "itis"))
})

test_that("options() override the priority order and the first-run set", {
  old <- options(taxify.backbone_priority = c("gbif", "col"),
                 taxify.default_backbones = c("wfo", "col"))
  on.exit(options(old), add = TRUE)

  pr <- taxify:::.backbone_priority()
  expect_identical(pr[1:2], c("gbif", "col"))       # option leads
  expect_setequal(pr, taxify:::backbone_names())     # still total
  # first-run set follows the overridden priority (col now before wfo)
  expect_identical(taxify:::.default_backbone_set(), c("col", "wfo"))
})

test_that("resolve_default_backend() returns installed backbones, priority-ordered", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("col") && backbone_ready("wfo"),
              "example backbones missing")

  inst <- taxify:::installed_backbones()
  skip_if(length(inst) == 0L, "no example backbones installed")

  res <- taxify:::resolve_default_backend(verbose = FALSE)
  expect_setequal(res, inst)                         # every installed backbone
  expect_identical(res, taxify:::order_by_priority(inst))
  expect_lt(match("col", res), match("wfo", res))    # col outranks wfo
})

test_that("taxify(backend = NULL) equals naming the resolved installed set", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("col"), "col example backbone missing")

  def <- taxify("Quercus robur", verbose = FALSE)
  expect_s3_class(def, "data.frame")
  expect_equal(nrow(def), 1L)
  expect_true("backend" %in% names(def))
  expect_true(def$backend %in% taxify:::installed_backbones())

  expl <- taxify("Quercus robur",
                 backend = taxify:::resolve_default_backend(verbose = FALSE),
                 verbose = FALSE)
  expect_identical(def$accepted_name, expl$accepted_name)
  expect_identical(def$backend, expl$backend)
})

test_that("install_backbones() rejects unknown backbone names", {
  expect_error(install_backbones("not_a_backbone", verbose = FALSE),
               "Unknown backbone")
})

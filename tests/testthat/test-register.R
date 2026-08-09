# Runtime side of the genus register: resolving the published .vtr pair, the
# in-memory lookups it backs, and the out-of-scope enrichment that reads the
# backbone-coverage table. The build pipeline itself lives in taxifydb, and its
# extractors, kingdom inference and life-form assignment are tested there.


# ---- lookup_genus() tests using a mock register ----

#' Build a minimal mock register and inject it into .taxify_env
setup_mock_register <- function() {
  reg <- data.frame(
    genus         = c("Quercus",     "Boletus",       "Aspergillus"),
    kingdom       = c("Plantae",     "Fungi",         "Fungi"),
    phylum        = c("Tracheophyta","Basidiomycota",  "Ascomycota"),
    class         = c("Magnoliopsida", NA_character_,  NA_character_),
    order         = c("Fagales",     "Boletales",     "Eurotiales"),
    family        = c("Fagaceae",    "Boletaceae",    "Aspergillaceae"),
    kingdom_group = c("plantae",     "fungi",         "fungi"),
    taxon_group   = c("angiosperm",  "fungus",        "fungus"),
    life_form     = c("angiosperm",  "fungus",        "fungus"),
    stringsAsFactors = FALSE
  )
  .taxify_env$register <- reg
  reg
}

teardown_mock_register <- function() {
  .taxify_env$register <- NULL
}


test_that("lookup_genus() returns the correct row", {
  setup_mock_register()
  on.exit(teardown_mock_register())

  hit <- lookup_genus("Quercus")
  expect_false(is.null(hit))
  expect_equal(nrow(hit), 1L)
  expect_equal(hit$genus,         "Quercus")
  expect_equal(hit$life_form,     "angiosperm")
  expect_equal(hit$taxon_group,   "angiosperm")
  expect_equal(hit$kingdom_group, "plantae")
  expect_equal(hit$family,        "Fagaceae")
})


test_that("lookup_genus() returns NULL for unknown genus", {
  setup_mock_register()
  on.exit(teardown_mock_register())

  expect_null(lookup_genus("Nonexistia"))
  expect_null(lookup_genus(""))
})


test_that("lookup_genus() errors on non-scalar input", {
  expect_error(lookup_genus(c("Quercus", "Pinus")), "scalar")
  expect_error(lookup_genus(1L), "character scalar")
})


# ---- out_of_scope enrichment tests ----

test_that("taxify() sets match_type = 'out_of_scope' and life_form for genus-in-register", {
  # Set up mock WFO backbone (Quercus and Pinus are plants, Boletus is not in WFO)
  vtr_path <- mock_backbone_vtr()
  be <- wfo_backend()

  # Inject mock backbone path into cache
  set_backbone_path("wfo", vtr_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  # Set up a register that includes Boletus (a fungus genus not in WFO backbone)
  .taxify_env$register <- data.frame(
    genus         = c("Quercus",    "Pinus",      "Boletus"),
    kingdom       = c("Plantae",    "Plantae",    "Fungi"),
    phylum        = c("Tracheophyta","Tracheophyta","Basidiomycota"),
    class         = c("Magnoliopsida","Pinopsida", NA_character_),
    order         = c("Fagales",    "Pinales",    "Boletales"),
    family        = c("Fagaceae",   "Pinaceae",   "Boletaceae"),
    kingdom_group = c("plantae",    "plantae",    "fungi"),
    taxon_group   = c("angiosperm", "gymnosperm", "fungus"),
    life_form     = c("angiosperm", "gymnosperm", "fungus"),
    stringsAsFactors = FALSE
  )

  # Coverage: WFO covers the plant genera but not Boletus, so Boletus is
  # out_of_scope. Mock the coverage file so the test does not depend on a real
  # coverage .vtr being present in the user data dir.
  cov_path <- mock_coverage_vtr(genus = c("Quercus", "Pinus"), backbone = "wfo")
  clear_coverage_cache()
  on.exit(clear_coverage_cache(), add = TRUE)

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify(
      c("Quercus robur", "Boletus edulis", "Xxxx yyyyy"),
      backbone = "wfo",
      fuzzy = FALSE,
      verbose = FALSE
    )
  )

  # Quercus robur is in WFO — matched
  qr_row <- result[result$input_name == "Quercus robur", ]
  expect_true(qr_row$match_type %in% c("exact", "exact_ci"))

  # Boletus edulis: genus Boletus is in register but not WFO backbone
  be_row <- result[result$input_name == "Boletus edulis", ]
  expect_equal(be_row$match_type, "out_of_scope")
  expect_equal(be_row$life_form, "fungus")

  # Xxxx yyyyy: genus not in register either — stays "none"
  xx_row <- result[result$input_name == "Xxxx yyyyy", ]
  expect_equal(xx_row$match_type, "none")
  expect_true(is.na(xx_row$life_form))
})


test_that("taxify() does not enrich when register is unavailable", {
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL  # restore to allow real register on next load
  }, add = TRUE)

  # Ensure register is NOT loaded (empty sentinel — prevents file load)
  .taxify_env$register <- data.frame()

  result <- taxify(
    c("Quercus robur", "Boletus edulis"),
    backbone = "wfo",
    fuzzy = FALSE,
    verbose = FALSE
  )

  # No out_of_scope — register not available
  expect_false(any(result$match_type == "out_of_scope", na.rm = TRUE))
})


test_that("out_of_scope enrichment does not affect matched names", {
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  .taxify_env$register <- data.frame(
    genus         = c("Quercus",    "Pinus"),
    kingdom       = c("Plantae",    "Plantae"),
    phylum        = c("Tracheophyta","Tracheophyta"),
    class         = c("Magnoliopsida","Pinopsida"),
    order         = c("Fagales",    "Pinales"),
    family        = c("Fagaceae",   "Pinaceae"),
    kingdom_group = c("plantae",    "plantae"),
    taxon_group   = c("angiosperm", "gymnosperm"),
    life_form     = c("angiosperm", "gymnosperm"),
    stringsAsFactors = FALSE
  )

  result <- taxify(
    c("Quercus robur", "Pinus sylvestris"),
    backbone = "wfo",
    fuzzy = FALSE,
    verbose = FALSE
  )

  # Both should be matched, not out_of_scope
  expect_true(all(result$match_type %in% c("exact", "exact_ci", "fuzzy")))
  # life_form and taxon_group are populated for matched rows when register available
  expect_equal(result$life_form[result$input_name == "Quercus robur"],
               "angiosperm")
  expect_equal(result$life_form[result$input_name == "Pinus sylvestris"],
               "gymnosperm")
  expect_equal(result$taxon_group[result$input_name == "Quercus robur"],
               "angiosperm")
  expect_equal(result$taxon_group[result$input_name == "Pinus sylvestris"],
               "gymnosperm")
})


test_that("taxify() returns a data.frame when the register exists but coverage does not", {
  # Regression: prefilter_out_of_scope() must not collapse `result` to NULL when
  # the coverage .vtr is absent (a clean install, before any download). Returning
  # NULL there turned `result` into a list via `$<-` and crashed as_taxify_result()
  # with "incorrect number of dimensions" on every machine without a cached
  # coverage file.
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
  }, add = TRUE)

  .taxify_env$register <- data.frame(
    genus = c("Quercus", "Pinus"), kingdom = c("Plantae", "Plantae"),
    family = c("Fagaceae", "Pinaceae"), kingdom_group = c("plantae", "plantae"),
    taxon_group = c("angiosperm", "gymnosperm"),
    life_form = c("angiosperm", "gymnosperm"), stringsAsFactors = FALSE
  )

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) NULL,
    taxify(c("Quercus robur", "Pinus sylvestris"), backbone = "wfo",
           fuzzy = FALSE, verbose = FALSE)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$match_type %in% c("exact", "exact_ci", "fuzzy")))
})


test_that("a backbone absent from the coverage table disables the filter", {
  # The published coverage is built over a fixed backbone set, so a backbone
  # added to the registry before the register is rebuilt has no rows in it at
  # all. Reading that as "covers no genera" makes every genus not-covered, and
  # the out-of-scope prefilter then marks every unmatched name and skips the
  # abbreviated-genus and fuzzy stages for all of them. COL XR shipped in
  # exactly that state.
  cov_path <- mock_coverage_vtr(genus = c("Quercus", "Pinus"), backbone = "col")
  clear_coverage_cache()
  on.exit(clear_coverage_cache(), add = TRUE)

  with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    {
      # Absent backbone: unanswerable, so no answer -- and say so, once.
      expect_warning(expect_null(covered_genera_for("colxr")), "colxr")
      expect_silent(expect_null(covered_genera_for("colxr")))

      # A set is only as answerable as its least-covered member: falling back to
      # col's genera alone would exclude every genus only colxr carries.
      expect_null(suppressWarnings(covered_genera_for(c("col", "colxr"))))

      # A covered backbone is unaffected.
      expect_setequal(covered_genera_for("col"), c("Quercus", "Pinus"))
    }
  )
})


test_that("taxify() still fuzzy-matches against a backbone missing from coverage", {
  # The consequence of the above, at the level a user sees it: with coverage
  # that knows nothing about the queried backbone, a register genus must not be
  # written off as out_of_scope before fuzzy matching has run.
  vtr_path <- mock_backbone_vtr()
  set_backbone_path("wfo", vtr_path)
  on.exit({
    set_backbone_path("wfo", NULL)
    .taxify_env$register <- NULL
    clear_coverage_cache()
  }, add = TRUE)

  .taxify_env$register <- data.frame(
    genus = "Quercus", kingdom = "Plantae", family = "Fagaceae",
    kingdom_group = "plantae", taxon_group = "angiosperm",
    life_form = "angiosperm", stringsAsFactors = FALSE
  )

  # Coverage exists but names only `col`; the query runs against `wfo`.
  cov_path <- mock_coverage_vtr(genus = "Quercus", backbone = "col")
  clear_coverage_cache()

  result <- suppressWarnings(with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Quercuss robur", backbone = "wfo", fuzzy = TRUE, verbose = FALSE)
  ))

  expect_equal(nrow(result), 1L)
  expect_false(identical(result$match_type[1], "out_of_scope"))
  expect_equal(result$match_type[1], "fuzzy")
})


# ---- asset resolution ----

test_that("ensure_register_asset() returns an existing file without downloading", {
  dd <- file.path(tempfile("taxify_reg_"), "")
  reg_dir <- file.path(dd, "genus_register", "latest")
  dir.create(reg_dir, recursive = TRUE)
  p <- file.path(reg_dir, "genus_register.vtr")
  writeLines("placeholder", p)
  on.exit(unlink(dd, recursive = TRUE), add = TRUE)

  withr::with_options(list(taxify.data_dir = dd), {
    called <- FALSE
    out <- with_mocked_bindings(
      download_backbone = function(...) { called <<- TRUE; NULL },
      ensure_register(verbose = FALSE)
    )
    expect_equal(normalizePath(out), normalizePath(p))
    expect_false(called)
  })
})


test_that("ensure_register_asset() returns NULL when nothing resolves", {
  dd <- tempfile("taxify_reg_empty_")
  dir.create(dd, recursive = TRUE)
  on.exit(unlink(dd, recursive = TRUE), add = TRUE)

  withr::with_options(list(taxify.data_dir = dd), {
    out <- with_mocked_bindings(
      download_backbone = function(...) stop("no network"),
      ensure_register(verbose = FALSE)
    )
    expect_null(out)
  })
})


test_that("the register and coverage paths follow the standard versioned layout", {
  dd <- tempfile("taxify_reg_paths_")
  withr::with_options(list(taxify.data_dir = dd), {
    expect_equal(basename(register_vtr_path()), "genus_register.vtr")
    expect_equal(basename(dirname(register_vtr_path())), "latest")
    expect_equal(basename(dirname(dirname(register_vtr_path()))), "genus_register")
    expect_equal(basename(coverage_vtr_path()), "backend_coverage.vtr")
    expect_equal(basename(dirname(dirname(coverage_vtr_path()))), "backend_coverage")
  })
})


test_that("both register assets have a manifest entry", {
  m <- local_manifest()
  expect_true("genus_register" %in% names(m$backends))
  expect_true("backend_coverage" %in% names(m$backends))
  for (nm in c("genus_register", "backend_coverage")) {
    expect_true(endsWith(m$backends[[nm]]$full_url, paste0(nm, ".vtr")))
    expect_true(nzchar(m$backends[[nm]]$latest))
  }
})


test_that("taxify_build_register() delegates to taxifydb", {
  skip_if(requireNamespace("taxifydb", quietly = TRUE),
          "taxifydb is installed, so the missing-dependency error cannot fire")
  expect_error(taxify_build_register(verbose = FALSE), "taxifydb")
})

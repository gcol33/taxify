# enrich_simple() silent-failure guards (#12) and self-describing downloaded
# metadata (#16). install_mock_enrichment() (helper-mock-enrichment.R) stages a
# .vtr into the session cache, so these run offline with no manifest or network.

# ---- #12 Problem 1: an explicit join_col the .vtr lacks is a wiring bug ----

test_that("enrich_simple() stops on an explicit join_col the .vtr lacks (#12)", {
  # A species-keyed .vtr (canonical_name = binomials, no genus column) joined on
  # genus would silently match "Amanita" against "Amanita muscaria" and attach
  # an all-NA column; it must stop instead.
  install_mock_enrichment("mockspeciesjoin", data.frame(
    canonical_name = c("Amanita muscaria", "Amanita phalloides"),
    trophic        = c("symbiotroph", "symbiotroph"),
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Amanita muscaria", genus = "Amanita",
                  qualifier = NA_character_, stringsAsFactors = FALSE)
  expect_error(
    taxify:::enrich_simple(x, "mockspeciesjoin",
                           col_map = c(trophic = "trophic"),
                           source_label = "mock", join_col = "genus",
                           verbose = FALSE),
    "no 'genus' column"
  )
})

test_that("enrich_simple() default accepted_name path joins on canonical_name (#12)", {
  # The default join_col (accepted_name) must still resolve against a .vtr keyed
  # on canonical_name -- the normal species-level path.
  install_mock_enrichment("mockspeciesok", data.frame(
    canonical_name = "Quercus robur", trait_x = 42, stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Quercus robur", qualifier = NA_character_,
                  stringsAsFactors = FALSE)
  r <- taxify:::enrich_simple(x, "mockspeciesok",
                              col_map = c(trait_x = "trait_x"),
                              source_label = "mock", verbose = FALSE)
  expect_equal(r$trait_x, 42)
})

test_that("enrich_simple() joins a genus-keyed .vtr with a genus column (#12)", {
  # The legitimate genus-keyed path: the .vtr carries a genus-rank key column,
  # so an explicit join_col = "genus" resolves and does not trip the guard.
  install_mock_enrichment("mockgenuskeyed", data.frame(
    canonical_name = "Abies", genus = "Abies", myco = "EcM",
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Abies alba", genus = "Abies",
                  qualifier = NA_character_, stringsAsFactors = FALSE)
  r <- taxify:::enrich_simple(x, "mockgenuskeyed", col_map = c(myco = "myco"),
                              source_label = "mock", join_col = "genus",
                              verbose = FALSE)
  expect_equal(r$myco, "EcM")
})

# ---- #12 Problem 2: a mapped column absent from the schema is named ----

test_that("enrich_simple() warns when a mapped column is absent from the .vtr (#12)", {
  install_mock_enrichment("mockmissingcol", data.frame(
    canonical_name = "Quercus robur", present_trait = 1,
    stringsAsFactors = FALSE))
  x <- data.frame(accepted_name = "Quercus robur", qualifier = NA_character_,
                  stringsAsFactors = FALSE)
  expect_warning(
    taxify:::enrich_simple(
      x, "mockmissingcol",
      col_map = c(present = "present_trait", missing = "absent_trait"),
      source_label = "mock", verbose = FALSE),
    "absent_trait"
  )
})

# ---- #16 Part 1: an installed enrichment's meta.json is self-describing ----

test_that("build_enrichment_meta() carries the manifest entry's describing fields (#16)", {
  dd <- tempfile("emeta_"); dir.create(dd)
  on.exit(unlink(dd, recursive = TRUE), add = TRUE)
  vtr <- file.path(dd, "demo.vtr")
  vectra::write_vtr(data.frame(canonical_name = "Aaa", country_code = "AT",
                               status = "invasive", stringsAsFactors = FALSE), vtr)
  entry <- list(latest = "2026.07", static = TRUE,
                group_col = "country_code",
                available_groups = list("AT", "DE"),
                license = "CC BY 4.0",
                citation = list(key = "x2020", title = "Demo"))
  meta <- taxify:::build_enrichment_meta(entry, "2026.07", FALSE, vtr)
  expect_equal(meta$group_col, "country_code")
  expect_equal(as.character(unlist(meta$available_groups)), c("AT", "DE"))
  expect_equal(meta$license, "CC BY 4.0")
  expect_equal(meta$citation$key, "x2020")
  expect_equal(meta$version, "2026.07")
  expect_false(isTRUE(meta$pinned))
  expect_identical(meta$content_id, unname(tools::md5sum(vtr)))
})

test_that("a written enrichment meta.json reads back its describing fields (#16)", {
  dd <- tempfile("emeta_"); dir.create(dd)
  on.exit(unlink(dd, recursive = TRUE), add = TRUE)
  edir <- file.path(dd, "enrichment", "demo", "latest")
  dir.create(edir, recursive = TRUE)
  vtr <- file.path(edir, "demo.vtr")
  vectra::write_vtr(data.frame(canonical_name = "Aaa", tdwg_code = "GER",
                               native = TRUE, stringsAsFactors = FALSE), vtr)
  entry <- list(latest = "2026.07", static = TRUE, group_col = "tdwg_code",
                available_groups = list("GER", "FRA"), license = "CC BY 4.0",
                citation = list(key = "y2021"))
  meta <- taxify:::build_enrichment_meta(entry, "2026.07", FALSE, vtr)
  jsonlite::write_json(meta, file.path(edir, "meta.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  back <- taxify:::read_enrichment_meta(vtr)
  expect_equal(back$group_col, "tdwg_code")
  expect_setequal(as.character(unlist(back$available_groups)), c("GER", "FRA"))
  expect_equal(back$license, "CC BY 4.0")
})

# ---- #16 Part 2: the example database is never written into ----

test_that("ensure_enrichment() refuses to download into the example database (#16)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  # globtherm is in the manifest but not bundled in the example database.
  target <- "globtherm"
  bundled <- file.exists(file.path(taxify_example_data(), "enrichment", target,
                                   "latest", paste0(target, ".vtr")))
  skip_if(bundled, "target unexpectedly bundled in the example database")

  edir <- file.path(taxify_example_data(), "enrichment")
  before <- list.files(edir, recursive = TRUE)
  expect_error(taxify:::ensure_enrichment(target, verbose = FALSE),
               "not bundled with the example database")
  after <- list.files(edir, recursive = TRUE)
  expect_identical(before, after)
})

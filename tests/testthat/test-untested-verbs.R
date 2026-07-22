# Direct coverage for the group-filtered enrichment doors and for
# install_backbones(). The grouped doors take a language/region/country
# argument, so the test-doors.R loop (which calls fn(x, verbose = FALSE)) skips
# them; each is exercised here against the bundled example database, which
# carries distinct values per (species, group) so a broken group filter or a
# broken species join shows up as a wrong value rather than a wrong shape.

use_example_db <- function(env = parent.frame()) {
  old <- options(taxify.data_dir = taxify_example_data())
  withr::defer({
    options(old)
    taxify_clear_cache()
  }, envir = env)
  taxify_clear_cache()
}

grouped_probe <- function() {
  taxify(c("Quercus robur", "Robinia pseudoacacia", "Ailanthus altissima"),
         verbose = FALSE)
}

enrichment_ready <- function(key) {
  file.exists(file.path(taxify_example_data(), "enrichment", key, "latest",
                        paste0(key, ".vtr")))
}


# ---- add_common_names() ----

test_that("add_common_names() attaches the vernacular name for the queried language", {
  use_example_db()
  skip_if_not(enrichment_ready("common_names"), "common_names fixture missing")
  out <- add_common_names(grouped_probe(), lang = "en", verbose = FALSE)

  expect_true("common_name" %in% names(out))
  expect_equal(out$common_name,
               c("example_common_name", NA_character_, NA_character_))
})

test_that("add_common_names() suffixes one column per language when several are asked", {
  use_example_db()
  skip_if_not(enrichment_ready("common_names"), "common_names fixture missing")
  out <- add_common_names(grouped_probe(), lang = c("en", "de"), verbose = FALSE)

  expect_true(all(c("common_name_en", "common_name_de") %in% names(out)))
  expect_false("common_name" %in% names(out))
  expect_equal(out$common_name_en[1L], "example_common_name")
  expect_equal(out$common_name_de[1L], "example_common_name")
  expect_true(is.na(out$common_name_en[2L]))
})

test_that("add_common_names() returns NA for a language the source does not carry", {
  use_example_db()
  skip_if_not(enrichment_ready("common_names"), "common_names fixture missing")
  out <- add_common_names(grouped_probe(), lang = "fr", verbose = FALSE)

  expect_true("common_name" %in% names(out))
  expect_true(all(is.na(out$common_name)))
})

test_that("add_common_names() records how many rows it enriched", {
  use_example_db()
  skip_if_not(enrichment_ready("common_names"), "common_names fixture missing")
  out <- add_common_names(grouped_probe(), lang = "en", verbose = FALSE)

  en <- attr(out, "taxify_meta")$enrichments
  last <- en[[length(en)]]
  expect_equal(last$name, "common_names")
  expect_equal(last$source, "vernacular names")
  expect_equal(last$n_matched, 1L)
  expect_equal(last$n_total, 3L)
})

test_that("add_common_names() requires a taxify() result", {
  expect_error(add_common_names(data.frame(species = "Quercus robur")),
               "accepted_name")
})


# ---- add_wcvp(region =) ----

test_that("add_wcvp() attaches the native status for one TDWG region", {
  use_example_db()
  skip_if_not(enrichment_ready("wcvp"), "wcvp fixture missing")
  out <- add_wcvp(grouped_probe(), region = "EUR", verbose = FALSE)

  expect_true("native_status" %in% names(out))
  expect_equal(out$native_status,
               c("example_native_status", NA_character_, NA_character_))
})

test_that("add_wcvp() suffixes one column per region when several are asked", {
  use_example_db()
  skip_if_not(enrichment_ready("wcvp"), "wcvp fixture missing")
  out <- add_wcvp(grouped_probe(), region = c("EUR", "NAM"), verbose = FALSE)

  expect_true(all(c("native_status_EUR", "native_status_NAM") %in% names(out)))
  expect_false("native_status" %in% names(out))
  expect_equal(out$native_status_EUR[1L], "example_native_status")
  expect_equal(out$native_status_NAM[1L], "example_native_status")
  expect_true(all(is.na(out$native_status_EUR[2:3])))
})

test_that("add_wcvp() returns NA for a region outside the source", {
  use_example_db()
  skip_if_not(enrichment_ready("wcvp"), "wcvp fixture missing")
  out <- add_wcvp(grouped_probe(), region = "ZZZ", verbose = FALSE)

  expect_true("native_status" %in% names(out))
  expect_true(all(is.na(out$native_status)))
})

test_that("add_wcvp() requires a region", {
  expect_error(add_wcvp(data.frame(accepted_name = "Quercus robur")),
               "'region' is required")
})


# ---- add_glonaf() ----

test_that("add_glonaf() flags only the species GloNAF records for the region", {
  use_example_db()
  skip_if_not(enrichment_ready("glonaf"), "glonaf fixture missing")
  out <- add_glonaf(grouped_probe(), region = "EUR", verbose = FALSE)

  expect_true("naturalized" %in% names(out))
  expect_equal(out$naturalized,
               c(NA_character_, "example_naturalized", NA_character_))
})

test_that("add_glonaf() suffixes one column per region when several are asked", {
  use_example_db()
  skip_if_not(enrichment_ready("glonaf"), "glonaf fixture missing")
  out <- add_glonaf(grouped_probe(), region = c("EUR", "NAM"), verbose = FALSE)

  expect_true(all(c("naturalized_EUR", "naturalized_NAM") %in% names(out)))
  expect_equal(out$naturalized_EUR[2L], "example_naturalized")
  expect_equal(out$naturalized_NAM[2L], "example_naturalized")
  expect_true(is.na(out$naturalized_EUR[1L]))
})

test_that("add_glonaf() records how many rows it enriched", {
  use_example_db()
  skip_if_not(enrichment_ready("glonaf"), "glonaf fixture missing")
  out <- add_glonaf(grouped_probe(), region = "EUR", verbose = FALSE)

  en <- attr(out, "taxify_meta")$enrichments
  last <- en[[length(en)]]
  expect_equal(last$name, "glonaf")
  expect_equal(last$n_matched, 1L)
})

test_that("add_glonaf() requires a region", {
  expect_error(add_glonaf(data.frame(accepted_name = "Robinia pseudoacacia")),
               "'region' is required")
})


# ---- add_alien_first_records() ----

test_that("add_alien_first_records() attaches the year and its provenance columns", {
  use_example_db()
  skip_if_not(enrichment_ready("alien_first_records"),
              "alien_first_records fixture missing")
  out <- add_alien_first_records(grouped_probe(), country = "AT",
                                 verbose = FALSE)

  expect_true(all(c("alien_first_record", "alien_first_record_source",
                    "alien_first_record_reference") %in% names(out)))
  expect_equal(out$alien_first_record, c(NA, 11, 13))
  expect_equal(out$alien_first_record_source,
               c(NA_character_, rep("example_alien_first_record_source", 2L)))
  expect_equal(out$alien_first_record_reference[2L],
               "example_alien_first_record_reference")
})

test_that("add_alien_first_records() keeps each country's year in its own column", {
  use_example_db()
  skip_if_not(enrichment_ready("alien_first_records"),
              "alien_first_records fixture missing")
  out <- add_alien_first_records(grouped_probe(), country = c("AT", "DE"),
                                 verbose = FALSE)

  expect_true(all(c("alien_first_record_AT", "alien_first_record_DE")
                  %in% names(out)))
  expect_equal(out$alien_first_record_AT, c(NA, 11, 13))
  expect_equal(out$alien_first_record_DE, c(NA, 12, 14))
})

test_that("add_alien_first_records() honours cols=", {
  use_example_db()
  skip_if_not(enrichment_ready("alien_first_records"),
              "alien_first_records fixture missing")
  out <- add_alien_first_records(grouped_probe(), country = "AT",
                                 cols = "alien_first_record", verbose = FALSE)

  expect_true("alien_first_record" %in% names(out))
  expect_false("alien_first_record_source" %in% names(out))
  expect_equal(out$alien_first_record, c(NA, 11, 13))
})

test_that("add_alien_first_records() returns NA for a country outside the source", {
  use_example_db()
  skip_if_not(enrichment_ready("alien_first_records"),
              "alien_first_records fixture missing")
  out <- add_alien_first_records(grouped_probe(), country = "ZZ",
                                 verbose = FALSE)

  expect_true(all(is.na(out$alien_first_record)))
})

test_that("add_alien_first_records() requires a country", {
  expect_error(
    add_alien_first_records(data.frame(accepted_name = "Robinia pseudoacacia")),
    "'country' is required")
})


# ---- install_backbones() ----

test_that("install_backbones() short-circuits on backbones already on disk", {
  # No download path is reachable here: every name is already a .vtr in the
  # example database, so ensure_backbone() resolves from the versioned layout.
  use_example_db()
  skip_if_not(all(c("col", "gbif", "wfo") %in% taxify:::installed_backbones()),
              "example backbones missing")

  out <- install_backbones(c("wfo", "gbif", "col"), verbose = FALSE)
  expect_identical(out, c("col", "wfo", "gbif"))
  expect_true(all(out %in% taxify:::installed_backbones()))
})

test_that("install_backbones() deduplicates and returns priority order", {
  calls <- character(0)
  out <- with_mocked_bindings(
    ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
      calls <<- c(calls, backend$name)
      "mock.vtr"
    },
    install_backbones(c("ott", "col", "ott", "ncbi"), verbose = FALSE)
  )
  expect_identical(out, c("col", "ncbi", "ott"))
  expect_identical(calls, c("col", "ncbi", "ott"))
})

test_that("install_backbones(NULL) installs the first-run set COL, GBIF, ITIS", {
  calls <- character(0)
  out <- with_mocked_bindings(
    ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
      calls <<- c(calls, backend$name)
      "mock.vtr"
    },
    install_backbones(verbose = FALSE)
  )
  expect_identical(calls, c("col", "gbif", "itis"))
  expect_identical(out, c("col", "gbif", "itis"))
})

test_that("install_backbones() follows the taxify.default_backbones option", {
  old <- options(taxify.default_backbones = c("worms", "col"))
  on.exit(options(old), add = TRUE)

  calls <- character(0)
  with_mocked_bindings(
    ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
      calls <<- c(calls, backend$name)
      "mock.vtr"
    },
    install_backbones(verbose = FALSE)
  )
  expect_identical(calls, c("col", "worms"))
})

test_that("install_backbones() warns on a failed backbone and drops it from the result", {
  out <- NULL
  expect_warning(
    out <- with_mocked_bindings(
      ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
        if (backend$name == "ncbi") stop("no route to host")
        "mock.vtr"
      },
      install_backbones(c("col", "ncbi"), verbose = FALSE)
    ),
    "Could not install backbone 'ncbi'"
  )
  expect_identical(out, "col")
})

test_that("install_backbones() rejects unknown names before touching the network", {
  called <- FALSE
  expect_error(
    with_mocked_bindings(
      ensure_backbone = function(backend, version = "latest", verbose = TRUE) {
        called <<- TRUE
        "mock.vtr"
      },
      install_backbones(c("col", "not_a_backbone"), verbose = FALSE)
    ),
    "Unknown backbone\\(s\\): not_a_backbone"
  )
  expect_false(called)
})

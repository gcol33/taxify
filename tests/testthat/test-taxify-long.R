# taxify_long() reshapes wide, group-suffixed enrichment columns back to long
# format. Most cases run on a constructed wide frame (no enrichment needed);
# one exercises the auto-detection from enrichment metadata.

test_that("taxify_long() reshapes explicit suffixed columns to long", {
  x <- data.frame(
    input_name = c("a", "b"),
    status_AT  = c("invasive", NA),
    status_DE  = c(NA, "invasive"),
    stringsAsFactors = FALSE
  )
  long <- taxify_long(x, cols = "status", group_col = "country")
  expect_equal(nrow(long), 4L)                     # 2 species x 2 groups
  expect_setequal(long$country, c("AT", "DE"))
  expect_true("status" %in% names(long))
  expect_false(any(grepl("_AT$|_DE$", names(long))))
  # The value lands with its group: species a is invasive in AT, not DE.
  a_at <- long$status[long$input_name == "a" & long$country == "AT"]
  a_de <- long$status[long$input_name == "a" & long$country == "DE"]
  expect_equal(a_at, "invasive")
  expect_true(is.na(a_de))
})

test_that("taxify_long() does not turn a companion column into a group row", {
  # Grouped country columns alongside a companion <base>_source column: the
  # companion must never be captured as a bogus group value (e.g. country =
  # "source"). Real group codes come from the enrichment's group vocabulary.
  x <- data.frame(
    input_name             = c("a", "b"),
    invasive_status_AT     = c("invasive", NA),
    invasive_status_DE     = c(NA, "invasive"),
    invasive_status_source = c("GRIIS", "GRIIS"),
    stringsAsFactors = FALSE
  )
  long <- taxify_long(x, cols = "invasive_status", group_col = "country")

  # The country values are a subset of the real groups; "source" is not one.
  expect_true(all(long$country %in% c("AT", "DE")))
  expect_false("source" %in% long$country)
  expect_equal(nrow(long), 4L)                     # 2 species x 2 real groups
  # The companion column is preserved (carried through, not reshaped).
  expect_true("invasive_status_source" %in% names(long))
})

test_that("taxify_long(drop_na = TRUE) drops all-NA value rows", {
  x <- data.frame(
    input_name = c("a", "b"),
    status_AT  = c("invasive", NA),
    status_DE  = c(NA, "invasive"),
    stringsAsFactors = FALSE
  )
  long <- taxify_long(x, cols = "status", group_col = "country", drop_na = TRUE)
  expect_equal(nrow(long), 2L)
  expect_false(anyNA(long$status))
})

test_that("taxify_long() longest-base matching disambiguates shared prefixes", {
  # alien_first_record and alien_first_record_source share a prefix; the longer
  # base must claim its suffix first.
  x <- data.frame(
    input_name                    = "a",
    alien_first_record_AT         = 1901L,
    alien_first_record_source_AT  = "GAVIA",
    stringsAsFactors = FALSE
  )
  long <- taxify_long(
    x,
    cols = c("alien_first_record", "alien_first_record_source"),
    group_col = "country"
  )
  expect_equal(nrow(long), 1L)
  expect_equal(long$alien_first_record, 1901L)
  expect_equal(long$alien_first_record_source, "GAVIA")
})

test_that("taxify_long() passes through single-group data unchanged", {
  x <- data.frame(input_name = c("a", "b"), status = c("x", "y"),
                  stringsAsFactors = FALSE)
  long <- taxify_long(x, cols = "status", group_col = "country")
  expect_equal(nrow(long), 2L)
  expect_true(all(is.na(long$country)))
  expect_equal(long$status, c("x", "y"))
})

test_that("taxify_long() errors without cols and without reshape metadata", {
  x <- data.frame(a = 1)
  expect_error(taxify_long(x), "auto-detect")
})

test_that("taxify_long() auto-detects from grouped-enrichment metadata", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  griis_ok <- file.exists(file.path(taxify_example_data(), "enrichment",
                                    "griis", "latest", "griis.vtr"))
  skip_if_not(griis_ok, "griis example enrichment missing")

  r <- taxify("Robinia pseudoacacia", verbose = FALSE) |>
    add_griis(country = c("AT", "DE"), verbose = FALSE)
  long <- taxify_long(r)
  # One row per (species, country) it was expanded into.
  expect_true(nrow(long) >= 2L)
  expect_true(any(c("country", "country_code") %in% names(long)))
})

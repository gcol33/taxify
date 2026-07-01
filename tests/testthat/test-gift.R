# GIFT is a bundled enrichment: taxifydb fetches GIFT's redistributable subset
# (CC BY 4.0) once at build time and writes a .vtr, which add_gift() joins
# offline by accepted name. These tests run against whatever gift .vtr is
# available (example db or a local build) and skip if none is present.

test_that("add_gift() errors on input without accepted_name", {
  expect_error(add_gift(data.frame(x = 1)), "accepted_name")
})

# Is the gift enrichment available in the current data dir (example db or a
# local/downloaded build)? If not, the join tests below skip.
gift_ready <- function() {
  cols <- tryCatch(taxify:::.gift_available_cols(verbose = FALSE),
                   error = function(e) NULL)
  !is.null(cols)
}

test_that("add_gift() attaches curated GIFT trait columns by accepted name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(gift_ready(), "gift enrichment not available")

  x <- data.frame(
    query         = c("Abies alba", "Quercus robur"),
    accepted_name = c("Abies alba", "Quercus robur"),
    matched_name  = c("Abies alba", "Quercus robur"),
    stringsAsFactors = FALSE
  )
  r <- add_gift(x, verbose = FALSE)

  # Default columns are attached, row count and order preserved.
  expect_true("gift_plant_height_max" %in% names(r))
  expect_equal(nrow(r), 2L)
  expect_equal(r$accepted_name, x$accepted_name)
  # Numeric traits stay numeric (na_types derived from the .vtr schema).
  expect_type(r$gift_plant_height_max, "double")
})

test_that("gift_traits() lists columns and add_gift() honours cols=", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(gift_ready(), "gift enrichment not available")

  cat_df <- gift_traits()
  expect_true(all(c("column", "type") %in% names(cat_df)))
  expect_true(all(grepl("^gift_", cat_df$column)))

  x <- data.frame(
    query = "Abies alba", accepted_name = "Abies alba",
    matched_name = "Abies alba", stringsAsFactors = FALSE
  )
  # Selecting by column name (without gift_ prefix) yields only those columns.
  r <- add_gift(x, cols = "plant_height_max", verbose = FALSE)
  gcols <- grep("^gift_", names(r), value = TRUE)
  expect_setequal(gcols, "gift_plant_height_max")

  expect_error(add_gift(x, cols = "not_a_real_trait", verbose = FALSE),
               "unknown trait")
})

test_that("add_gift() attaches NA for species absent from GIFT", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(gift_ready(), "gift enrichment not available")

  x <- data.frame(
    query = "Zzznotaspecies fakename", accepted_name = "Zzznotaspecies fakename",
    matched_name = "Zzznotaspecies fakename", stringsAsFactors = FALSE
  )
  r <- add_gift(x, cols = "plant_height_max", verbose = FALSE)
  expect_true("gift_plant_height_max" %in% names(r))
  expect_true(is.na(r$gift_plant_height_max))
})

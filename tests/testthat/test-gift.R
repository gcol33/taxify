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
  cols <- tryCatch(
    taxify:::.enrichment_available_cols("gift", prefix = "gift_", verbose = FALSE),
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
               "unknown column")
})

test_that("enrichment_cols() is the generic browse and cols= works on any door", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  skip_if_not(gift_ready(), "gift enrichment not available")

  # generic browse == gift_traits()
  expect_equal(enrichment_cols("gift"), gift_traits())

  # add_gift(cols = "all") attaches every bundled column, more than the default.
  x <- data.frame(query = "Abies alba", accepted_name = "Abies alba",
                  matched_name = "Abies alba", stringsAsFactors = FALSE)
  # cols = "all" attaches exactly the browse catalogue (>= the default subset;
  # the example db ships only the default columns, the full cache has 109).
  d <- add_gift(x, verbose = FALSE)
  a <- add_gift(x, cols = "all", verbose = FALSE)
  n_def <- length(grep("^gift_", names(d)))
  n_all <- length(grep("^gift_", names(a)))
  expect_gte(n_all, n_def)
  expect_equal(n_all, nrow(enrichment_cols("gift")))

  # The same cols= selector now works on a different door (FloraWeb).
  fw_ready <- file.exists(file.path(taxify_example_data(), "enrichment",
                                    "floraweb", "latest", "floraweb.vtr"))
  skip_if_not(fw_ready, "floraweb enrichment not available")
  full <- add_floraweb(x, verbose = FALSE)
  sub  <- add_floraweb(x, cols = c("ell_light_de", "ell_nitrogen_de"), verbose = FALSE)
  n_full <- length(grep("_de$", names(full)))
  n_sub  <- length(grep("_de$", names(sub)))
  expect_equal(n_sub, 2L)
  expect_lt(n_sub, n_full)
  expect_true(all(c("ell_light_de", "ell_nitrogen_de") %in% names(sub)))
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

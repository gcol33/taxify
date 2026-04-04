# Tests for add_data() — custom data enrichment via backbone matching

setup_mock_backend <- function() {
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, bb_path)
  be
}

# ---- Basic join ----

test_that("add_data joins a data.frame by accepted_id", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris"), verbose = FALSE)

  traits <- data.frame(
    species = c("Quercus robur", "Pinus sylvestris"),
    height  = c(30, 25),
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species", verbose = FALSE)
  expect_true("height" %in% names(enriched))
  expect_equal(enriched$height, c(30, 25))
})


test_that("add_data resolves synonyms to same accepted_id", {
  setup_mock_backend()
  # taxify result uses accepted name
  result <- taxify("Quercus robur", verbose = FALSE)

  # External data uses the synonym
  traits <- data.frame(
    species = "Quercus pedunculata",
    dbh     = 1.2,
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species", verbose = FALSE)
  expect_equal(enriched$dbh, 1.2)
})


test_that("add_data returns NA for unmatched rows", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Nonexistus imaginus"), verbose = FALSE)

  traits <- data.frame(
    species = "Quercus robur",
    height  = 30,
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species", verbose = FALSE)
  expect_equal(enriched$height[1L], 30)
  expect_true(is.na(enriched$height[2L]))
})


# ---- Column selection ----

test_that("add_data respects cols argument", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(
    species = "Quercus robur",
    height  = 30,
    dbh     = 1.2,
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species",
                       cols = "height", verbose = FALSE)
  expect_true("height" %in% names(enriched))
  expect_false("dbh" %in% names(enriched))
})


# ---- Column collision ----

test_that("add_data prefixes colliding columns", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  # "family" already exists in taxify output
  traits <- data.frame(
    species = "Quercus robur",
    family  = "custom_family",
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species", verbose = FALSE)
  expect_true("data_family" %in% names(enriched))
  # Original family column untouched
  expect_equal(enriched$family, "Fagaceae")
  expect_equal(enriched$data_family, "custom_family")
})


# ---- Duplicate handling ----

test_that("add_data warns on exact duplicate rows", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(
    species = c("Quercus robur", "Quercus robur"),
    height  = c(30, 30),
    stringsAsFactors = FALSE
  )

  expect_warning(
    enriched <- add_data(result, traits, species_col = "species",
                         verbose = FALSE),
    "duplicate"
  )
  expect_equal(enriched$height, 30)
})


test_that("add_data errors on conflicting duplicate rows", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(
    species = c("Quercus robur", "Quercus robur"),
    height  = c(30, 35),
    stringsAsFactors = FALSE
  )

  expect_error(
    add_data(result, traits, species_col = "species", verbose = FALSE),
    "different trait values"
  )
})


test_that("add_data errors when synonyms create conflicting duplicates", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  # Two names that resolve to the same accepted_id with different values
  traits <- data.frame(
    species = c("Quercus robur", "Quercus pedunculata"),
    height  = c(30, 35),
    stringsAsFactors = FALSE
  )

  expect_error(
    add_data(result, traits, species_col = "species", verbose = FALSE),
    "different trait values"
  )
})


# ---- Auto-detection ----

test_that("add_data auto-detects species column", {
  setup_mock_backend()
  result <- taxify(c("Quercus robur", "Pinus sylvestris"), verbose = FALSE)

  traits <- data.frame(
    site_id   = c("A", "B"),
    taxon     = c("Quercus robur", "Pinus sylvestris"),
    height    = c(30, 25),
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, verbose = FALSE)
  expect_true("height" %in% names(enriched))
  expect_equal(enriched$height, c(30, 25))
})


test_that("auto-detect fails with informative error when no column matches", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(
    code  = "QR001",
    value = 42,
    stringsAsFactors = FALSE
  )

  expect_error(
    add_data(result, traits, verbose = FALSE),
    "auto-detect|species_col"
  )
})


# ---- File readers ----

test_that("add_data reads a CSV file via vectra", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  tmp_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp_csv), add = TRUE)

  write.csv(
    data.frame(species = "Quercus robur", height = 30,
               stringsAsFactors = FALSE),
    tmp_csv, row.names = FALSE
  )

  enriched <- add_data(result, tmp_csv, species_col = "species",
                       verbose = FALSE)
  expect_equal(enriched$height, 30)
})

test_that("add_data reads a .vtr file", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  tmp_vtr <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_vtr), add = TRUE)

  vectra::write_vtr(
    data.frame(species = "Quercus robur", height = 30,
               stringsAsFactors = FALSE),
    tmp_vtr
  )

  enriched <- add_data(result, tmp_vtr, species_col = "species",
                       verbose = FALSE)
  expect_equal(enriched$height, 30)
})

test_that("add_data reads a SQLite file", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  tmp_db <- tempfile(fileext = ".sqlite")
  on.exit(unlink(tmp_db), add = TRUE)

  traits_df <- data.frame(species = "Quercus robur", height = 30,
                          stringsAsFactors = FALSE)
  con <- DBI::dbConnect(RSQLite::SQLite(), tmp_db)
  DBI::dbWriteTable(con, "traits", traits_df)
  DBI::dbDisconnect(con)

  enriched <- add_data(result, tmp_db, species_col = "species",
                       table = "traits", verbose = FALSE)
  expect_equal(enriched$height, 30)
})

test_that("add_data errors on SQLite without table argument", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  tmp_db <- tempfile(fileext = ".sqlite")
  on.exit(unlink(tmp_db), add = TRUE)
  file.create(tmp_db)

  expect_error(
    add_data(result, tmp_db, species_col = "species", verbose = FALSE),
    "table argument is required"
  )
})

test_that("add_data errors on unsupported file format", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  tmp <- tempfile(fileext = ".parquet")
  on.exit(unlink(tmp), add = TRUE)
  file.create(tmp)

  expect_error(
    add_data(result, tmp, verbose = FALSE),
    "Unsupported file format"
  )
})


# ---- Enrichment metadata ----

test_that("add_data registers in taxify_meta enrichments", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(
    species = "Quercus robur",
    height  = 30,
    stringsAsFactors = FALSE
  )

  enriched <- add_data(result, traits, species_col = "species",
                       verbose = FALSE)
  meta <- attr(enriched, "taxify_meta")
  expect_true(length(meta$enrichments) > 0L)
  expect_equal(meta$enrichments[[length(meta$enrichments)]]$n_matched, 1L)
})


# ---- Input validation ----

test_that("add_data errors on missing species_col", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(species = "Quercus robur", height = 30,
                       stringsAsFactors = FALSE)

  expect_error(
    add_data(result, traits, species_col = "nonexistent", verbose = FALSE),
    "not found in data"
  )
})


test_that("add_data errors on missing cols", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  traits <- data.frame(species = "Quercus robur", height = 30,
                       stringsAsFactors = FALSE)

  expect_error(
    add_data(result, traits, species_col = "species",
             cols = "nonexistent", verbose = FALSE),
    "not found in data"
  )
})


test_that("add_data errors on non-taxify input", {
  expect_error(
    add_data(data.frame(x = 1), data.frame(y = 2), verbose = FALSE),
    "accepted_id"
  )
})


test_that("add_data errors on empty data", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  expect_error(
    add_data(result, data.frame(species = character(0)),
             species_col = "species", verbose = FALSE),
    "0 rows"
  )
})

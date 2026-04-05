# Tests for cite() and citation helpers

# Helper: build a minimal taxify_result with meta attribute
mock_taxify_result <- function(backends = "wfo", version = "2024.12",
                               enrichments = list()) {
  df <- data.frame(
    input_name     = "Quercus robur",
    matched_name   = "Quercus robur",
    accepted_name  = "Quercus robur",
    match_type     = "exact",
    stringsAsFactors = FALSE
  )
  meta <- list(
    backend     = backends,
    version     = version,
    n_input     = 1L,
    match_tally = list(exact = 1L, case_insensitive = 0L, fuzzy = 0L,
                       out_of_scope = 0L, unmatched = 0L),
    enrichments = enrichments
  )
  attr(df, "taxify_meta") <- meta
  class(df) <- c("taxify_result", "data.frame")
  df
}

mock_enrichment <- function(name = "eive", source = "EIVE", version = "1.0",
                            license = "CC BY 4.0") {
  list(
    name      = name,
    source    = source,
    version   = version,
    license   = license,
    n_matched = 1L,
    n_total   = 1L
  )
}


# ---- cite() ----

test_that("cite() prints citations for backend-only result", {
  result <- mock_taxify_result()
  out <- capture.output(cite(result))
  # Should contain taxify and WFO
  expect_true(any(grepl("taxify", out, ignore.case = TRUE)))
  expect_true(any(grepl("WFO|wfo|World Flora", out)))
})

test_that("cite() prints enrichment citations", {
  result <- mock_taxify_result(enrichments = list(mock_enrichment()))
  out <- capture.output(cite(result))
  expect_true(any(grepl("EIVE|eive", out)))
})

test_that("cite() returns x invisibly", {
  result <- mock_taxify_result()
  ret <- withVisible(capture.output(val <- cite(result)))
  expect_identical(val, result)
})

test_that("cite() writes BibTeX file", {
  result <- mock_taxify_result(
    enrichments = list(mock_enrichment())
  )
  bib_file <- tempfile(fileext = ".bib")
  on.exit(unlink(bib_file), add = TRUE)

  capture.output(cite(result, file = bib_file))

  expect_true(file.exists(bib_file))
  lines <- readLines(bib_file)
  # Should have at least one @article or @misc entry
  expect_true(any(grepl("^@(article|misc)\\{", lines)))
  # Should have author field
  expect_true(any(grepl("author\\s*=", lines)))
})

test_that("cite() errors on non-taxify input", {
  expect_error(cite(data.frame(x = 1)), "taxify_meta")
})

test_that("cite() handles multi-backend result", {
  result <- mock_taxify_result(backends = c("wfo", "col"))
  out <- capture.output(cite(result))
  expect_true(any(grepl("WFO|wfo|World Flora", out)))
  expect_true(any(grepl("COL|col", out)))
})


# ---- cite_footer() ----

test_that("cite_footer returns compact source string", {
  meta <- attr(mock_taxify_result(), "taxify_meta")
  footer <- cite_footer(meta)
  expect_true(grepl("WFO", footer))
  expect_true(grepl("2024.12", footer))
})

test_that("cite_footer includes enrichments", {
  meta <- attr(mock_taxify_result(
    enrichments = list(mock_enrichment())
  ), "taxify_meta")
  footer <- cite_footer(meta)
  expect_true(grepl("EIVE", footer))
})


# ---- print.taxify_result footer ----

test_that("print.taxify_result shows citation footer", {
  result <- mock_taxify_result()
  out <- capture.output(print(result))
  expect_true(any(grepl("Sources:.*cite\\(\\)", out)))
})


# ---- format_bibtex_entry ----

test_that("format_bibtex_entry produces valid article entry", {
  cit <- list(
    key     = "dengler2023eive",
    type    = "article",
    authors = "Dengler J et al.",
    year    = "2023",
    title   = "EIVE 1.0",
    journal = "Vegetation Classification and Survey",
    volume  = "4",
    pages   = "7-29",
    doi     = "10.3897/VCS.98324"
  )
  bib <- format_bibtex_entry(cit)
  expect_true(grepl("^@article\\{dengler2023eive,", bib))
  expect_true(grepl("author = \\{Dengler", bib))
  expect_true(grepl("doi = \\{10.3897", bib))
})

test_that("format_bibtex_entry produces valid misc entry", {
  cit <- list(
    key     = "wfo2024",
    type    = "misc",
    authors = "WFO",
    year    = "2024",
    title   = "World Flora Online",
    url     = "http://www.worldfloraonline.org"
  )
  bib <- format_bibtex_entry(cit)
  expect_true(grepl("^@misc\\{wfo2024,", bib))
  expect_true(grepl("url = \\{http", bib))
})

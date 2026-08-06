# A backbone's release version is the tag that packaged it, which is not the
# date of the upstream data. The GBIF backbone is the case that forced the
# distinction: GBIF froze it on 2023-08-28 and has said it will not be updated
# again, so a 2026 release tag there carries a treatment three years older than
# the tag reads. `source_date` records the upstream date so neither the
# discovery verbs nor a citation overstate how current the data is.

test_that("list_backbones() reports source_date separately from version", {
  lb <- list_backbones(verbose = FALSE)
  expect_true("source_date" %in% names(lb))
  expect_type(lb$source_date, "character")
  expect_identical(nrow(lb), length(taxify:::backbone_names()))
})


test_that("taxify_databases() carries source_date through", {
  td <- taxify_databases(verbose = FALSE)
  expect_true("source_date" %in% names(td))
})


test_that("a manifest source_date reaches the citation note", {
  cit <- taxify:::extract_manifest_citation(
    list(backends = list(demo = list(
      source_date = "2023-08-28",
      citation = list(key = "demo", type = "misc", title = "Demo Backbone")
    ))),
    "backends", "demo"
  )
  expect_equal(cit$note, "Data version 2023-08-28")
  expect_match(taxify:::format_bibtex_entry(cit), "note = \\{Data version 2023-08-28\\}")
})


test_that("an entry without source_date keeps its citation unchanged", {
  cit <- taxify:::extract_manifest_citation(
    list(backends = list(demo = list(
      citation = list(key = "demo", type = "misc", title = "Demo Backbone")
    ))),
    "backends", "demo"
  )
  expect_null(cit$note)
})


test_that("an existing citation note is kept alongside the data version", {
  cit <- taxify:::extract_manifest_citation(
    list(backends = list(demo = list(
      source_date = "2023-08-28",
      citation = list(key = "demo", type = "misc", title = "Demo",
                      note = "Accessed via ChecklistBank")
    ))),
    "backends", "demo"
  )
  expect_equal(cit$note, "Accessed via ChecklistBank; Data version 2023-08-28")
})


test_that("the bundled manifest dates the frozen GBIF backbone", {
  mf <- jsonlite::read_json(system.file("manifest.json", package = "taxify"))
  expect_equal(mf$backends$gbif$source_date, "2023-08-28")
})

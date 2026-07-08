# Tests for the LCVP and WCVP vascular-plant backbones: runtime dispatch,
# offline matching against the bundled example database, and the shared
# plant-genus register extractor.

test_that("lcvp and wcvp resolve to their backend objects", {
  lc <- taxify:::resolve_backend("lcvp")
  wc <- taxify:::resolve_backend("wcvp")

  expect_s3_class(lc, "taxify_lcvp")
  expect_s3_class(wc, "taxify_wcvp")
  expect_equal(lc$name, "lcvp")
  expect_equal(wc$name, "wcvp")
  expect_equal(lc$genus_col, "genus")
  expect_equal(wc$genus_col, "genus")
})

test_that("resolve_backend error lists the new backends", {
  expect_error(taxify:::resolve_backend("nonsense"), "lcvp")
  expect_error(taxify:::resolve_backend("nonsense"), "wcvp")
})

test_that("lcvp matches an accepted plant name and resolves a synonym", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Quercus robur", backend = "lcvp", verbose = FALSE)
  expect_equal(res$accepted_name, "Quercus robur")
  expect_equal(res$match_type, "exact")
  expect_equal(res$family, "Fagaceae")
  expect_equal(res$backend, "lcvp")

  syn <- taxify("Quercus pedunculata", backend = "lcvp", verbose = FALSE)
  expect_equal(syn$accepted_name, "Quercus robur")
  expect_true(syn$is_synonym)
})

test_that("wcvp matches an accepted plant name and resolves a synonym", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  res <- taxify("Fagus sylvatica", backend = "wcvp", verbose = FALSE)
  expect_equal(res$accepted_name, "Fagus sylvatica")
  expect_equal(res$match_type, "exact")
  expect_equal(res$backend, "wcvp")

  syn <- taxify("Quercus pedunculata", backend = "wcvp", verbose = FALSE)
  expect_equal(syn$accepted_name, "Quercus robur")
  expect_true(syn$is_synonym)
})

test_that("lcvp and wcvp are reported among installed backbones", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  inst <- installed_backbones()
  expect_true("lcvp" %in% inst)
  expect_true("wcvp" %in% inst)
})

test_that(".extract_plant_genera stamps Plantae and unions genus + species rows", {
  df <- data.frame(
    canonical_name   = c("Betula", "Quercus robur", "Betula pendula",
                         "Quercus badsyn"),
    taxon_rank       = c("GENUS", "SPECIES", "SPECIES", "SPECIES"),
    taxonomic_status = c("ACCEPTED", "ACCEPTED", "ACCEPTED", "SYNONYM"),
    genus            = c("Betula", "Quercus", "Betula", "Quercus"),
    family           = c("Betulaceae", "Fagaceae", "Betulaceae", "Fagaceae"),
    order            = c("Fagales", "Fagales", "Fagales", "Fagales"),
    stringsAsFactors = FALSE
  )
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(df, tmp)

  res <- taxify:::.extract_plant_genera(tmp)

  # Betula (genus-rank + species) and Quercus (accepted species only); the
  # SYNONYM Quercus row does not add a separate genus.
  expect_setequal(res$genus, c("Betula", "Quercus"))
  expect_true(all(res$kingdom == "Plantae"))
  expect_true(all(is.na(res$phylum)))
  expect_true(all(is.na(res$class)))
  # Genus-rank row sorts first, so Betula keeps its genus-rank family/order.
  expect_equal(res$family[res$genus == "Betula"], "Betulaceae")
  expect_equal(res$order[res$genus == "Quercus"], "Fagales")
})

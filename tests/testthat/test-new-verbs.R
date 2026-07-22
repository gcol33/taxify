# comm2sci(), id2name(), downstream(), class2tree(), lowest_common(), and the
# taxify(kingdom=) filter, run against the bundled example database. The wfo
# backbone carries three Quercus species (family Fagaceae, no ranks above
# family); reptiledb carries Naja naja with the full higher classification and a
# kingdom column; the common_names example maps "example_common_name" ->
# Quercus robur (en + de).

backbone_ready <- function(be) {
  file.exists(file.path(taxify_example_data(), be, "latest", paste0(be, ".vtr")))
}
enrichment_ready <- function(name) {
  file.exists(file.path(taxify_example_data(), "enrichment", name, "latest",
                        paste0(name, ".vtr")))
}


# ---- comm2sci() ----

test_that("comm2sci() resolves a common name to its scientific name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")

  r <- comm2sci("example_common_name", verbose = FALSE)
  expect_s3_class(r, "data.frame")
  expect_true("Quercus robur" %in% r$scientific_name)
  expect_setequal(names(r),
                  c("query", "common_name", "scientific_name", "lang"))
  # Both language rows (en + de) are present with no lang filter.
  expect_setequal(r$lang, c("en", "de"))
})

test_that("comm2sci() honours the lang filter", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")

  r <- comm2sci("example_common_name", lang = "en", verbose = FALSE)
  expect_equal(nrow(r), 1L)
  expect_equal(r$lang, "en")
})

test_that("comm2sci() is case-insensitive and empty on no match", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")

  a <- comm2sci("EXAMPLE_COMMON_NAME", verbose = FALSE)
  expect_true("Quercus robur" %in% a$scientific_name)
  expect_equal(nrow(comm2sci("no such creature", verbose = FALSE)), 0L)
})

test_that("comm2sci(resolve = TRUE) returns an enrichable taxify_result", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("common_names"), "common_names example missing")
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  r <- comm2sci("example_common_name", resolve = TRUE, backend = "wfo",
                verbose = FALSE)
  expect_s3_class(r, "taxify_result")
  expect_true("query_common" %in% names(r))
  expect_true("accepted_name" %in% names(r))
  expect_true("Quercus robur" %in% r$accepted_name)
})


# ---- id2name() ----

test_that("id2name() round-trips a taxon_id back to its name", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("col"), "col example backbone missing")

  r  <- taxify("Quercus robur", backend = "col", verbose = FALSE)
  id <- id2name(r$taxon_id, backend = "col", verbose = FALSE)
  expect_equal(id$name, "Quercus robur")
  expect_equal(id$accepted_name, "Quercus robur")
  expect_equal(id$genus, "Quercus")
  expect_equal(id$backend, "col")
})

test_that("id2name() keeps unknown IDs as NA rows in input order", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("col"), "col example backbone missing")

  r  <- taxify("Quercus robur", backend = "col", verbose = FALSE)
  id <- id2name(c("nope-999", r$taxon_id), backend = "col", verbose = FALSE)
  expect_equal(nrow(id), 2L)
  expect_true(is.na(id$name[1]))
  expect_equal(id$name[2], "Quercus robur")
})


# ---- downstream() ----

test_that("downstream() lists all species under a genus", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  d <- downstream("Quercus", backend = "wfo", verbose = FALSE)
  expect_true(all(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica")
                  %in% d$name))
  expect_true(all(toupper(d$rank) == "SPECIES"))
  expect_equal(unique(d$parent), "Quercus")
  # The parent node itself is never returned as its own descendant.
  expect_false("Quercus" %in% d$name)
})

test_that("downstream() returns empty for an unknown taxon", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  expect_equal(nrow(downstream("Notagenus", backend = "wfo", verbose = FALSE)),
               0L)
})


# ---- class2tree() / lowest_common() ----

test_that("lowest_common() finds the shared genus of two congeners", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  lc <- lowest_common(c("Quercus robur", "Quercus petraea"), backend = "wfo",
                      verbose = FALSE)
  expect_equal(lc$rank, "genus")
  expect_equal(lc$name, "Quercus")
  expect_equal(lc$n_taxa, 2L)
})

test_that("lowest_common() ignores an empty-string rank value (#15)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  r <- taxify(c("Quercus robur", "Quercus petraea"), backend = "wfo",
              verbose = FALSE)
  # Some backbones store "" (not NA) for an unresolved rank; a blank must not be
  # reported as the shared ancestor. With genus blanked, the MRCA falls through
  # to the next real shared rank (family), never to "".
  r$genus <- c("", "")
  lc <- lowest_common(r, verbose = FALSE)
  expect_false(identical(lc$name, ""))
  expect_false(identical(lc$rank, "genus"))
})

test_that("class2tree() builds a Newick tree over resolved names", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  tr <- class2tree(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica"),
                   backend = "wfo", verbose = FALSE)
  expect_s3_class(tr, "taxify_tree")
  expect_equal(length(tr$tip_labels), 3L)
  expect_match(tr$newick, "Quercus_robur")
  expect_match(tr$newick, ";$")
})

test_that("class2tree() collapses inputs sharing one accepted name to one tip", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  # Amphibolurus vitticeps is a synonym of Pogona vitticeps: two inputs, one
  # accepted name, so the tree carries one tip where there were two inputs.
  tr <- class2tree(c("Pogona vitticeps", "Amphibolurus vitticeps"),
                   backend = "reptiledb", verbose = FALSE)
  expect_s3_class(tr, "taxify_tree")
  expect_equal(length(tr$tip_labels), 1L)
  expect_equal(anyDuplicated(tr$tip_labels), 0L)

  # tip_labels tracks the tree: its length equals the count print() reports.
  printed   <- utils::capture.output(print(tr))
  n_printed <- as.integer(sub("^<taxify_tree> ([0-9]+) tip.*$", "\\1", printed[1]))
  expect_equal(n_printed, length(tr$tip_labels))

  # ...and equals the phylo tip count when ape is installed.
  skip_if_not_installed("ape")
  expect_equal(length(tr$tip_labels), ape::Ntip(tr$phylo))
})


# ---- taxify(kingdom = ) ----

test_that("kingdom = keeps an in-kingdom match and drops an out-of-kingdom one", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  keep <- taxify("Naja naja", backend = "reptiledb", kingdom = "animals",
                 verbose = FALSE)
  expect_equal(keep$match_type, "exact")
  expect_equal(keep$accepted_name, "Naja naja")

  drop <- taxify("Naja naja", backend = "reptiledb", kingdom = "plants",
                 verbose = FALSE)
  expect_equal(drop$match_type, "none")
  expect_true(is.na(drop$accepted_name))
})

test_that("kingdom = errors on an unrecognisable kingdom", {
  expect_error(resolve_kingdom_filter("notakingdom"), "recognised kingdom")
  expect_null(resolve_kingdom_filter(NULL))
  expect_equal(resolve_kingdom_filter("Animalia"), "animalia")
  expect_equal(resolve_kingdom_filter("plants"), "plantae")
})

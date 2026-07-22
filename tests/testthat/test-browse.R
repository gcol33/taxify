# Backbone-browsing verbs: synonyms(), children(), add_classification(),
# taxify_candidates(). Run against the bundled example database, where the
# reptiledb backbone carries a synonym (Amphibolurus vitticeps -> Pogona
# vitticeps) and the full higher classification, and the wfo backbone carries
# three Quercus species in family Fagaceae.

backbone_ready <- function(be) {
  file.exists(file.path(taxify_example_data(), be, "latest", paste0(be, ".vtr")))
}

test_that("synonyms() lists synonyms that resolve to an accepted taxon", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  s <- synonyms("Pogona vitticeps", backend = "reptiledb", verbose = FALSE)
  expect_s3_class(s, "data.frame")
  expect_true("Amphibolurus vitticeps" %in% s$synonym)
  # Every returned synonym resolves to the queried accepted name.
  expect_true(all(s$accepted_name == "Pogona vitticeps"))
  expect_setequal(
    names(s),
    c("input_name", "accepted_name", "synonym", "authorship", "rank",
      "taxon_id", "backend")
  )
})

test_that("synonyms() returns an empty frame when there are no synonyms", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  # The example wfo backbone is accepted-only.
  s <- synonyms("Quercus robur", backend = "wfo", verbose = FALSE)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), 0L)
})

test_that("children() lists the accepted species of a genus", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  ch <- children("Quercus", backend = "wfo", verbose = FALSE)
  expect_true(all(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica")
                  %in% ch$name))
  expect_true(all(ch$genus == "Quercus"))
  expect_true(all(ch$parent_rank == "genus"))
  # Case-insensitive rank filter: taxon_rank is stored uppercase.
  expect_true(all(toupper(ch$rank) == "SPECIES"))
})

test_that("children() auto-detects a family parent", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  ch <- children("Fagaceae", backend = "wfo", rank = "any", verbose = FALSE)
  expect_true(nrow(ch) >= 3L)
  expect_true(all(ch$parent_rank == "family"))
  expect_true(all(ch$family == "Fagaceae"))
})

test_that("children() input is case-insensitive and returns empty on no match", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  expect_equal(nrow(children("quercus", backend = "wfo", verbose = FALSE)),
               nrow(children("Quercus", backend = "wfo", verbose = FALSE)))
  expect_equal(nrow(children("Notagenus", backend = "wfo", verbose = FALSE)), 0L)
})

test_that("backend = NULL resolves to the top-priority installed backbone (#24)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(backbone_ready("col"), "col example backbone missing")

  # The browse verbs default backend = NULL. That must resolve to the highest-
  # priority installed backbone (COL here), never a hardcoded WFO a fresh
  # install would have to download.
  expect_identical(resolve_single_backend(NULL, verbose = FALSE), "col")
  # A named backend passes through untouched.
  expect_identical(resolve_single_backend("wfo", verbose = FALSE), "wfo")
})

test_that("add_classification() fills the higher ranks the backbone stores", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  r <- taxify("Naja naja", backend = "reptiledb", verbose = FALSE) |>
    add_classification(verbose = FALSE)
  expect_equal(r$kingdom, "Animalia")
  expect_equal(r$phylum, "Chordata")
  expect_equal(r$class, "Reptilia")
  expect_equal(r$order, "Serpentes")
})

test_that("add_classification() leaves ranks NA for a backbone without them", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  r <- taxify("Quercus robur", verbose = FALSE) |>
    add_classification(verbose = FALSE)
  expect_true(all(c("kingdom", "phylum", "class", "order") %in% names(r)))
  expect_true(is.na(r$phylum))
})

test_that("taxify_candidates() expands an ambiguous match into candidates", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("reptiledb"), "reptiledb example backbone missing")

  r <- taxify("Naja naja", backend = "reptiledb", verbose = FALSE)
  r$is_ambiguous <- TRUE
  r$ambiguous_targets <- paste(r$accepted_id, "reptiledb-ex-001", sep = "|")
  cand <- taxify_candidates(r, verbose = FALSE)
  expect_true(all(c("Naja naja", "Pogona vitticeps") %in% cand$candidate))
  expect_true(all(cand$input_name == "Naja naja"))
})

test_that("taxify_candidates() returns an empty frame when nothing is ambiguous", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  r <- taxify("Quercus robur", verbose = FALSE)
  expect_equal(nrow(taxify_candidates(r, verbose = FALSE)), 0L)
})


# ---- enrichment_groups() ----

enrichment_ready <- function(name) {
  file.exists(file.path(taxify_example_data(), "enrichment", name, "latest",
                        paste0(name, ".vtr")))
}

test_that("enrichment_groups() lists the group values of a grouped enrichment", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("griis"), "griis example enrichment missing")

  g <- enrichment_groups("griis", verbose = FALSE)
  expect_type(g, "character")
  # The bundled GRIIS example carries Austria and Germany.
  expect_setequal(g, c("AT", "DE"))
  # Sorted, unique, no NA.
  expect_false(anyNA(g))
  expect_equal(g, sort(g))
})

test_that("enrichment_groups() errors on a flat (non-grouped) enrichment", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  skip_if_not(enrichment_ready("zanne"), "zanne example enrichment missing")

  expect_error(enrichment_groups("zanne", verbose = FALSE),
               "not a grouped enrichment")
})

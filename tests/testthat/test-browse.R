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

  ch <- children("Quercus", verbose = FALSE)
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

  ch <- children("Fagaceae", rank = "any", verbose = FALSE)
  expect_true(nrow(ch) >= 3L)
  expect_true(all(ch$parent_rank == "family"))
  expect_true(all(ch$family == "Fagaceae"))
})

test_that("children() input is case-insensitive and returns empty on no match", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()  # drop any backbone paths cached by earlier test files
  skip_if_not(backbone_ready("wfo"), "wfo example backbone missing")

  expect_equal(nrow(children("quercus", verbose = FALSE)),
               nrow(children("Quercus", verbose = FALSE)))
  expect_equal(nrow(children("Notagenus", verbose = FALSE)), 0L)
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

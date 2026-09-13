# Input handling in the secondary verbs: duplicate rows (#66) and the four
# input shapes of #68.

# ---- #66: indistinguishable duplicate rows ----

test_that("comm2sci(output = \"result\") has one row per (query, name)", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  # The example vernacular is stored in two languages for one species.
  lookup <- comm2sci("example_common_name", verbose = FALSE)
  expect_gt(length(unique(lookup$lang)), 1L)

  r <- comm2sci("example_common_name", output = "result", backbone = "wfo",
                verbose = FALSE)
  expect_equal(nrow(r), 1L)
  expect_equal(anyDuplicated(r[c("query_common", "accepted_name")]), 0L)
})

test_that("synonyms() reports a repeated input name once", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  once  <- synonyms("Pogona vitticeps", backbone = "reptiledb", verbose = FALSE)
  twice <- synonyms(c("Pogona vitticeps", "Pogona vitticeps"),
                    backbone = "reptiledb", verbose = FALSE)
  expect_gt(nrow(once), 0L)
  expect_identical(twice, once)
})


# ---- #68 ----

test_that("lookup_genus(NA) is NULL, like any genus not in the register", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  expect_null(lookup_genus(NA_character_))
  expect_null(lookup_genus("Notagenus"))
  expect_equal(nrow(lookup_genus("Quercus")), 1L)
})

test_that("numeric ids are written out in full, never in scientific notation", {
  expect_identical(id_as_text(c(100000, 1e6, 11000000, NA)),
                   c("100000", "1000000", "11000000", NA))
  expect_identical(id_as_text(123456789012), "123456789012")
  expect_identical(id_as_text(c(100000L, NA)), c("100000", NA))
  expect_identical(id_as_text("col-ex-001"), "col-ex-001")
  expect_error(id_as_text(1.5), "whole numbers")
  expect_error(id2name(1.5, backbone = "col", verbose = FALSE), "whole numbers")
})

test_that("id2name() finds a round numeric id stored as text", {
  path <- tempfile(fileext = ".vtr")
  on.exit(unlink(path), add = TRUE)
  vectra::write_vtr(data.frame(
    taxon_id = c("100000", "11000000"),
    canonical_name = c("Aus bus", "Cus dus"),
    authorship = c("L.", "L."), taxon_rank = c("SPECIES", "SPECIES"),
    family = c("Aidae", "Cidae"), genus = c("Aus", "Cus"),
    is_synonym = c(FALSE, FALSE), accepted_taxon_id = c(NA, NA),
    stringsAsFactors = FALSE), path)

  out <- with_mocked_bindings(
    resolve_single_backend = function(backbone, verbose = TRUE) "gbif",
    backbone_path = function(backbone, verbose = TRUE) path,
    id2name(c(1e5, 1.1e7), verbose = FALSE)
  )
  expect_identical(out$id, c("100000", "11000000"))
  expect_identical(out$name, c("Aus bus", "Cus dus"))
})

test_that("class2tree() tip labels agree with its phylo", {
  skip_if_not_installed("ape")
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  tr <- class2tree(c("Quercus robur", "Quercus petraea"), backbone = "wfo",
                   verbose = FALSE)
  expect_setequal(tr$phylo$tip.label, tr$tip_labels)
  expect_true("Quercus robur" %in% tr$phylo$tip.label)
  expect_match(tr$newick, "Quercus_robur")
})

test_that("newick_labels() gives every name its own label", {
  lab <- newick_labels(c("Aus bus", "Aus_bus", "Cus (dus)"))
  expect_equal(anyDuplicated(unname(lab)), 0L)
  expect_false(any(grepl("[ (),;:'\"]", lab)))
  expect_identical(names(lab), c("Aus bus", "Aus_bus", "Cus (dus)"))
})

test_that("taxify_long() returns single-group input with a companion column", {
  x <- data.frame(name = c("a", "b"), trait = c(1, 2),
                  trait_sources = c("s1", "s2"), stringsAsFactors = FALSE)
  out <- taxify_long(x, cols = "trait", group_col = "country")
  expect_identical(out[names(x)], x)
  expect_true(all(is.na(out$country)))
})

test_that("taxify_long() matches a base name literally", {
  # "a.b" must not read "aXb_AT" as one of its suffixed columns.
  x <- data.frame(a.b = 1, aXb_AT = 2, check.names = FALSE)
  out <- taxify_long(x, cols = "a.b", group_col = "country")
  expect_identical(out[names(x)], x)
  expect_true(is.na(out$country))
})

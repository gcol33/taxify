# Descendant selection excludes the parent and respects kingdom constraints.

# A backbone where Morus is both a plant genus (mulberries) and a bird genus
# (gannets), each with its own genus row.
morus_backbone <- function() {
  df <- data.frame(
    taxon_id       = c("m1", "m2", "m3", "m4", "m5", "m6"),
    canonical_name = c("Morus", "Morus alba", "Morus nigra",
                       "Morus", "Morus bassanus", "Morus capensis"),
    authorship     = c("L.", "L.", "L.", "Brisson", "(L.)", "(Lichtenstein)"),
    taxon_rank     = c("GENUS", "SPECIES", "SPECIES",
                       "GENUS", "SPECIES", "SPECIES"),
    kingdom        = c("Plantae", "Plantae", "Plantae",
                       "Animalia", "Animalia", "Animalia"),
    family         = c("Moraceae", "Moraceae", "Moraceae",
                       "Sulidae", "Sulidae", "Sulidae"),
    genus          = rep("Morus", 6L),
    is_synonym     = rep(FALSE, 6L),
    stringsAsFactors = FALSE
  )
  path <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, path)
  path
}

with_morus <- function(code) {
  path <- morus_backbone()
  on.exit(unlink(path), add = TRUE)
  with_mocked_bindings(
    resolve_single_backend = function(backbone, verbose = TRUE) "col",
    backbone_path = function(backbone, verbose = TRUE) path,
    code
  )
}

test_that("kingdom = splits a genus name used in two kingdoms", {
  with_morus({
    plants <- downstream("Morus", kingdom = "plantae", verbose = FALSE)
    expect_setequal(plants$name, c("Morus alba", "Morus nigra"))
    expect_true(all(plants$kingdom_group == "plantae"))

    birds <- downstream("Morus", kingdom = "animals", verbose = FALSE)
    expect_setequal(birds$name, c("Morus bassanus", "Morus capensis"))
    expect_true(all(birds$family == "Sulidae"))
  })
})

test_that("a result mixing kingdoms warns and labels each row", {
  with_morus({
    expect_warning(both <- downstream("Morus", verbose = FALSE),
                   "more than one kingdom.*animalia, plantae")
    expect_equal(nrow(both), 4L)
    expect_setequal(both$kingdom_group, c("animalia", "plantae"))
    expect_warning(downstream("Morus", verbose = FALSE), "kingdom =")
  })
})

test_that("downto = \"any\" never returns the parent", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  ch <- downstream("Quercus", backbone = "wfo", downto = "any", verbose = FALSE)
  expect_false("Quercus" %in% ch$name)
  expect_identical(downstream("Quercus", backbone = "wfo", downto = NULL,
                            verbose = FALSE), ch)

  with_morus(expect_false("Morus" %in%
    downstream("Morus", downto = "any", kingdom = "plantae", verbose = FALSE)$name))
})

test_that("downstream reaches species below genus and family parents", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()
  genus <- downstream("Quercus", backbone = "wfo", verbose = FALSE)
  family <- downstream("Fagaceae", backbone = "wfo", verbose = FALSE)
  expect_gt(nrow(genus), 0L)
  expect_true(all(genus$name %in% family$name))
  expect_true(all(genus$parent_rank == "genus"))
  expect_true(all(family$parent_rank == "family"))
})


test_that("a kingdom the backbone's scope excludes returns no children", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)
  taxify_clear_cache()

  # WFO is plants only, so its Quercus has no animal children.
  expect_equal(nrow(downstream("Quercus", backbone = "wfo", kingdom = "animalia",
                             verbose = FALSE)), 0L)
  expect_error(downstream("Quercus", backbone = "wfo", kingdom = "rocks",
                        verbose = FALSE), "recognised kingdom")
})

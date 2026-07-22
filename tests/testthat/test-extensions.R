# Tests for pipe extensions: add_hybrid_info, add_wfo_info; native qualifier cols

setup_mock_backend <- function() {
  vtr_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, vtr_path)
  be
}

# -- add_hybrid_info --

test_that("add_hybrid_info adds columns for formula hybrid", {
  setup_mock_backend()
  result <- taxify("Quercus pyrenaica x Q. petraea", verbose = FALSE) |>
    add_hybrid_info()

  expect_true("hybrid_parent_1" %in% names(result))
  expect_true("hybrid_parent_2" %in% names(result))
  expect_true("hybrid_type" %in% names(result))
  expect_equal(result$hybrid_type, "formula")
  expect_equal(result$hybrid_parent_1, "Quercus pyrenaica")
  expect_equal(result$hybrid_parent_2, "Quercus petraea")
})

test_that("add_hybrid_info adds NA for non-hybrids", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE) |>
    add_hybrid_info()
  expect_true(is.na(result$hybrid_type))
  expect_true(is.na(result$hybrid_parent_1))
  expect_true(is.na(result$hybrid_parent_2))
})

test_that("add_hybrid_info handles nothogenus", {
  setup_mock_backend()
  result <- taxify("\u00d7 Festulolium", verbose = FALSE) |>
    add_hybrid_info()
  expect_equal(result$hybrid_type, "nothogenus")
  expect_true(is.na(result$hybrid_parent_1))
})

test_that("add_hybrid_info resolves formula parents to accepted names", {
  setup_mock_backend()
  # same-genus shorthand: second parent is a bare epithet
  result <- taxify("Salix alba x fragilis", verbose = FALSE) |>
    add_hybrid_info()
  expect_equal(result$hybrid_type, "formula")
  expect_equal(result$hybrid_parent_1, "Salix alba")
  expect_equal(result$hybrid_parent_2, "Salix fragilis")
  expect_equal(result$hybrid_parent_1_accepted, "Salix alba")
  expect_equal(result$hybrid_parent_2_accepted, "Salix fragilis")
})

# -- add_wfo_info --

test_that("add_wfo_info adds extra WFO columns", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE) |>
    add_wfo_info()

  expect_true("infraspecificEpithet" %in% names(result))
  # The mock backbone has infraspecificEpithet = NA for Quercus robur
  expect_true(is.na(result$infraspecificEpithet[1L]))
})

test_that("add_wfo_info preserves original columns", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)
  enriched <- add_wfo_info(result)
  # All original columns should still be there
  expect_true(all(names(result) %in% names(enriched)))
})

# -- add_gbif_info / add_col_info --
#
# The info doors read their backbone through the path cache (get_backbone_path),
# not by calling taxify(), so a mock injected with set_backbone_path is honoured
# deterministically. A minimal taxify-like frame (mock taxon_ids + backbone) drives
# the join directly, isolating the door from taxify()'s own session state. The
# cache is saved and restored so the mock never leaks into later files.

use_mock_cache <- function(name, path) {
  old <- get_backbone_path(name)
  withr::defer(set_backbone_path(name, old), envir = parent.frame())
  set_backbone_path(name, path)
}

test_that("add_gbif_info attaches GBIF columns and fills from the backbone", {
  use_mock_cache("gbif", mock_gbif_backbone_vtr())
  x <- data.frame(
    input_name = "Quercus robur", matched_name = "Quercus robur",
    accepted_name = "Quercus robur", taxon_id = "2878688",
    accepted_id = "2878688", backbone = "gbif", stringsAsFactors = FALSE
  )
  result <- add_gbif_info(x)

  expect_true(all(c("notho_type", "nom_status", "bracket_authorship",
                    "bracket_year", "gbif_year", "name_published_in",
                    "origin", "infra_specific_epithet") %in% names(result)))
  expect_equal(result$origin[1L], "SOURCE")
  expect_equal(result$gbif_year[1L], "1753")
})

test_that("add_gbif_info only enriches GBIF rows and keeps originals", {
  use_mock_cache("gbif", mock_gbif_backbone_vtr())
  x <- data.frame(
    input_name = c("Quercus robur", "Panthera leo"),
    matched_name = c("Quercus robur", "Panthera leo"),
    taxon_id = c("2878688", "OTHER"),
    backbone  = c("gbif", "col"),   # row 2 was matched by another backbone
    stringsAsFactors = FALSE
  )
  result <- add_gbif_info(x)

  expect_true(all(names(x) %in% names(result)))
  expect_equal(result$origin[1L], "SOURCE")
  expect_true(is.na(result$origin[2L]))
})

test_that("add_col_info attaches COL columns incl. the SpeciesProfile sidecar", {
  bb <- mock_col_backbone_vtr()
  # add_col_info derives the sidecar path from the backbone path, so place it beside.
  side <- sub("\\.vtr$", "_species_profile.vtr", bb)
  file.copy(mock_col_species_profile_vtr(), side, overwrite = TRUE)
  withr::defer(unlink(side))
  use_mock_cache("col", bb)
  x <- data.frame(
    input_name = "Quercus robur", matched_name = "Quercus robur",
    accepted_name = "Quercus robur", taxon_id = "5T6MX",
    accepted_id = "5T6MX", backbone = "col", stringsAsFactors = FALSE
  )
  result <- add_col_info(x)

  expect_true(all(c("notho", "nomenclaturalCode", "nomenclaturalStatus",
                    "namePublishedIn", "kingdom", "phylum", "col_class",
                    "order", "infraspecificEpithet", "is_extinct",
                    "is_marine", "is_freshwater", "is_terrestrial") %in%
                  names(result)))
  expect_equal(result$kingdom[1L], "Plantae")
  expect_equal(result$nomenclaturalCode[1L], "ICN")
  # SpeciesProfile sidecar carries Quercus robur as non-extinct, terrestrial.
  expect_type(result$is_extinct, "logical")
  expect_false(result$is_extinct[1L])
  expect_true(result$is_terrestrial[1L])
})

# -- native qualifier columns (from taxify() directly) --

test_that("taxify() carries qualifier + qualifier_position natively", {
  setup_mock_backend()
  result <- taxify("Pinus cf. sylvestris", verbose = FALSE)

  expect_true("qualifier" %in% names(result))
  expect_true("qualifier_position" %in% names(result))
  expect_equal(result$qualifier, "cf.")
  expect_equal(result$qualifier_position, "species")
})

test_that("a leading Cf. prefix is recorded at genus position", {
  setup_mock_backend()
  result <- taxify("Cf. Pinus sylvestris", verbose = FALSE)

  expect_equal(result$qualifier, "cf.")
  expect_equal(result$qualifier_position, "genus")
})

test_that("names without qualifiers carry NA qualifier columns", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE)

  expect_true(is.na(result$qualifier))
  expect_true(is.na(result$qualifier_position))
})

# -- chaining --

test_that("pipe chain works: taxify |> add_hybrid_info keeps qualifier cols", {
  setup_mock_backend()
  result <- taxify(c("Quercus \u00d7 hispanica", "Pinus cf. sylvestris"),
                   verbose = FALSE) |>
    add_hybrid_info()

  expect_equal(nrow(result), 2L)
  expect_equal(result$hybrid_type[1L], "nothospecies")
  expect_equal(result$qualifier[2L], "cf.")
})

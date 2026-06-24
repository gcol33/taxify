# Tests for pipe extensions: add_hybrid_info, add_wfo_info, add_qualifier_info

setup_mock_backend <- function() {
  bb_path <- mock_backbone_vtr()
  be <- wfo_backend()
  set_backbone_path(be$name, bb_path)
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

# -- add_qualifier_info --

test_that("add_qualifier_info extracts qualifier", {
  setup_mock_backend()
  result <- taxify("Pinus cf. sylvestris", verbose = FALSE) |>
    add_qualifier_info()

  expect_true("qualifier" %in% names(result))
  expect_true("qualifier_position" %in% names(result))
  expect_equal(result$qualifier, "cf.")
  expect_true(!is.na(result$qualifier_position))
})

test_that("add_qualifier_info records a leading Cf. prefix at position 1", {
  setup_mock_backend()
  result <- taxify("Cf. Pinus sylvestris", verbose = FALSE) |>
    add_qualifier_info()

  expect_equal(result$qualifier, "cf.")
  expect_equal(result$qualifier_position, 1L)
})

test_that("add_qualifier_info returns NA for names without qualifiers", {
  setup_mock_backend()
  result <- taxify("Quercus robur", verbose = FALSE) |>
    add_qualifier_info()

  expect_true(is.na(result$qualifier))
  expect_true(is.na(result$qualifier_position))
})

# -- chaining --

test_that("pipe chain works: taxify |> add_hybrid_info |> add_qualifier_info", {
  setup_mock_backend()
  result <- taxify(c("Quercus \u00d7 hispanica", "Pinus cf. sylvestris"),
                   verbose = FALSE) |>
    add_hybrid_info() |>
    add_qualifier_info()

  expect_equal(nrow(result), 2L)
  expect_equal(result$hybrid_type[1L], "nothospecies")
  expect_equal(result$qualifier[2L], "cf.")
})

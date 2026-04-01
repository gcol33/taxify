test_that("detect_hybrid identifies nothogenus with Unicode sign", {
  res <- detect_hybrid("\u00d7 Festulolium")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "nothogenus")
  expect_equal(res$stripped, "Festulolium")
})

test_that("detect_hybrid identifies nothogenus with x", {
  res <- detect_hybrid("x Festulolium")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "nothogenus")
  expect_equal(res$stripped, "Festulolium")
})

test_that("detect_hybrid identifies nothospecies with Unicode sign", {
  res <- detect_hybrid("Quercus \u00d7 hispanica")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "nothospecies")
  expect_equal(res$stripped, "Quercus hispanica")
})

test_that("detect_hybrid identifies nothospecies with x", {
  res <- detect_hybrid("Salix x fragilis")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "nothospecies")
  expect_equal(res$stripped, "Salix fragilis")
})

test_that("detect_hybrid identifies formula hybrids", {
  res <- detect_hybrid("Quercus pyrenaica x Q. petraea")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "formula")
  # stripped should be the first parent (matching target)
  expect_equal(res$stripped, "Quercus pyrenaica")
})

test_that("detect_hybrid identifies formula with full genus names", {
  res <- detect_hybrid("Quercus pyrenaica x Quercus petraea")
  expect_true(res$is_hybrid)
  expect_equal(res$hybrid_type, "formula")
  expect_equal(res$stripped, "Quercus pyrenaica")
})

test_that("detect_hybrid does NOT flag x inside words", {

  res <- detect_hybrid("Saxifraga granulata")
  expect_false(res$is_hybrid)
  expect_equal(res$stripped, "Saxifraga granulata")
})

test_that("detect_hybrid handles simple binomial without hybrid", {
  res <- detect_hybrid("Quercus robur")
  expect_false(res$is_hybrid)
  expect_equal(res$stripped, "Quercus robur")
})

test_that("detect_hybrid handles NA and empty", {
  res <- detect_hybrid(NA_character_)
  expect_false(res$is_hybrid)

  res2 <- detect_hybrid("")
  expect_false(res2$is_hybrid)
})

test_that("parse_hybrid_formula extracts parents from formula", {
  res <- parse_hybrid_formula("Quercus pyrenaica x Q. petraea")
  expect_equal(res$parent_1, "Quercus pyrenaica")
  expect_equal(res$parent_2, "Quercus petraea")
  expect_equal(res$hybrid_type, "formula")
})

test_that("parse_hybrid_formula expands abbreviated genus", {
  res <- parse_hybrid_formula("Salix alba \u00d7 S. fragilis")
  expect_equal(res$parent_1, "Salix alba")
  expect_equal(res$parent_2, "Salix fragilis")
})

test_that("parse_hybrid_formula returns NA for nothogenus", {
  res <- parse_hybrid_formula("\u00d7 Festulolium")
  expect_true(is.na(res$parent_1))
  expect_true(is.na(res$parent_2))
  expect_equal(res$hybrid_type, "nothogenus")
})

test_that("parse_hybrid_formula returns NA for nothospecies", {
  res <- parse_hybrid_formula("Quercus \u00d7 hispanica")
  expect_true(is.na(res$parent_1))
  expect_true(is.na(res$parent_2))
  expect_equal(res$hybrid_type, "nothospecies")
})

test_that("parse_hybrid_formula returns NA for non-hybrids", {
  res <- parse_hybrid_formula("Quercus robur")
  expect_true(is.na(res$parent_1))
  expect_true(is.na(res$parent_2))
  expect_true(is.na(res$hybrid_type))
})

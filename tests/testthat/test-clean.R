test_that("clean_one strips trailing authorship", {
  res <- clean_one("Quercus robur L.")
  expect_equal(res$cleaned, "Quercus robur")
  expect_false(res$is_hybrid)
  expect_true(is.na(res$qualifier))
})

test_that("clean_one strips parenthesized authorship", {
  res <- clean_one("Rosa canina var. dumalis (Bechst.) Baker")
  # var. is stripped as qualifier, (Bechst.) as paren author, Baker as trailing
  expect_equal(res$cleaned, "Rosa canina dumalis")
  expect_equal(res$qualifier, "var.")
})

test_that("clean_one strips qualifiers", {
  res <- clean_one("Pinus cf. sylvestris")
  expect_equal(res$cleaned, "Pinus sylvestris")
  expect_equal(res$qualifier, "cf.")

  res2 <- clean_one("Festuca aff. rubra")
  expect_equal(res2$cleaned, "Festuca rubra")
  expect_equal(res2$qualifier, "aff.")
})

test_that("clean_one strips s.l. and s.str. qualifiers", {
  res <- clean_one("Ranunculus auricomus s.l.")
  expect_equal(res$cleaned, "Ranunculus auricomus")
  expect_equal(res$qualifier, "s.l.")

  res2 <- clean_one("Ranunculus auricomus s.str.")
  expect_equal(res2$cleaned, "Ranunculus auricomus")
  expect_equal(res2$qualifier, "s.str.")
})

test_that("clean_one strips agg. qualifier", {
  res <- clean_one("Rubus fruticosus agg.")
  expect_equal(res$cleaned, "Rubus fruticosus")
  expect_equal(res$qualifier, "agg.")
})

test_that("clean_one lowercases epithet but keeps genus", {
  res <- clean_one("QUERCUS ROBUR")
  expect_equal(res$cleaned, "QUERCUS robur")
})

test_that("clean_one handles NA and empty strings", {
  res <- clean_one(NA_character_)
  expect_true(is.na(res$cleaned))

  res2 <- clean_one("")
  expect_true(is.na(res2$cleaned))

  res3 <- clean_one("   ")
  expect_true(is.na(res3$cleaned))
})

test_that("clean_one strips brackets and numbers", {
  res <- clean_one("Quercus robur (123)")
  expect_equal(res$cleaned, "Quercus robur")
})

test_that("clean_one collapses whitespace", {
  res <- clean_one("Quercus   robur")
  expect_equal(res$cleaned, "Quercus robur")
})

test_that("clean_names returns correct data.frame", {
  nms <- c("Quercus robur L.", "Pinus cf. sylvestris", NA)
  df <- clean_names(nms)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 3L)
  expect_named(df, c("original", "cleaned", "is_hybrid", "qualifier", "genus_only", "hybrid_name"))
  expect_equal(df$original, nms)
  expect_equal(df$cleaned[1L], "Quercus robur")
  expect_equal(df$qualifier[2L], "cf.")
  expect_true(is.na(df$cleaned[3L]))
})

test_that("clean_one detects hybrid and strips marker", {
  res <- clean_one("Quercus \u00d7 hispanica")
  expect_true(res$is_hybrid)
  expect_equal(res$cleaned, "Quercus hispanica")
})

test_that("clean_one handles complex authorship chains", {
  res <- clean_one("Festuca rubra L. ex Huds.")
  expect_equal(res$cleaned, "Festuca rubra")
})


# -- normalize_epithets: accent + ligature + orthographic alternation --

test_that("normalize_epithets folds ligatures and digraph variants", {
  # ae-ligature and ae-digraph collapse to the same key
  expect_identical(
    normalize_epithets("Quercus \u00e6gypticus"),
    normalize_epithets("Quercus aegypticus")
  )
  # oe-ligature and oe-digraph collapse to the same key
  expect_identical(
    normalize_epithets("Genus p\u0153cilia"),
    normalize_epithets("Genus poecilia")
  )
})

test_that("normalize_epithets folds German umlauts to digraphs", {
  # Umlauted and de-umlauted German spellings of author names match
  expect_identical(
    normalize_epithets("Carex b\u00f6hmii"),
    normalize_epithets("Carex boehmii")
  )
  expect_identical(
    normalize_epithets("Hieracium m\u00fcllerianum"),
    normalize_epithets("Hieracium muellerianum")
  )
})

test_that("normalize_epithets strips other Latin-1 diacritics", {
  expect_identical(
    normalize_epithets("Genus l\u00e9ve\u00edllei"),
    normalize_epithets("Genus leveillei")
  )
  expect_identical(
    normalize_epithets("Genus n\u00fa\u00f1ezii"),
    normalize_epithets("Genus nunezii")
  )
})

test_that("normalize_epithets still applies orthographic alternation", {
  # ae -> i collapses hirtaeformis and hirtiformis
  expect_identical(
    normalize_epithets("Quercus hirtaeformis"),
    normalize_epithets("Quercus hirtiformis")
  )
  # y -> i, ph -> f, th -> t
  expect_equal(normalize_epithets("Genus phyllothalamus"),
               "genus fillotalamus")
})

test_that("normalize_epithets handles NA, empty, and single-word input", {
  expect_true(is.na(normalize_epithets(NA_character_)))
  expect_equal(normalize_epithets(""), "")
  expect_equal(normalize_epithets("Festulolium"), "festulolium")
})

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

test_that("clean_one normalizes ssp./nssp. infra-rank markers to subsp.", {
  res <- clean_one("Pinus mugo ssp. uncinata")
  expect_equal(res$cleaned, "Pinus mugo uncinata")
  expect_equal(res$qualifier, "subsp.")
  expect_equal(res$qualifier_position, "species")

  res2 <- clean_one("Festuca ovina nssp. hirtula")
  expect_equal(res2$cleaned, "Festuca ovina hirtula")
  expect_equal(res2$qualifier, "subsp.")

  # the fully spelled marker is untouched
  expect_equal(clean_one("Pinus mugo subsp. uncinata")$qualifier, "subsp.")

  # ssp is only a marker as a whole bounded token, not inside a genus/epithet
  expect_true(is.na(clean_one("Sspiraea alba")$qualifier))
})

test_that("clean_names normalizes ssp./nssp. across a vector", {
  df <- clean_names(c("Pinus mugo ssp. uncinata", "Festuca ovina nssp. hirtula",
                      "Quercus robur"))
  expect_equal(df$qualifier, c("subsp.", "subsp.", NA))
  expect_equal(df$cleaned,
               c("Pinus mugo uncinata", "Festuca ovina hirtula", "Quercus robur"))
})

test_that("clean_one recognizes s.s. as sensu stricto (s.str.)", {
  res <- clean_one("Quercus robur s.s.")
  expect_equal(res$cleaned, "Quercus robur")
  expect_equal(res$qualifier, "s.str.")
  expect_false(res$is_aggregate)

  # spaced form too
  expect_equal(clean_one("Quercus robur s. s.")$qualifier, "s.str.")

  # s.str. and sensu stricto still resolve to the same token
  expect_equal(clean_one("Quercus robur s.str.")$qualifier, "s.str.")

  df <- clean_names(c("Quercus robur s.s.", "Quercus robur s.l."))
  expect_equal(df$qualifier, c("s.str.", "s.l."))
  expect_equal(df$is_aggregate, c(FALSE, TRUE))
})

test_that("infraspecific rank variants fold to their base rank token", {
  # forma spellings
  expect_equal(clean_one("Carex flacca fo. serrulata")$qualifier, "f.")
  expect_equal(clean_one("Carex flacca forma serrulata")$qualifier, "f.")
  # additional ICN infraspecific ranks
  expect_equal(clean_one("Carex flacca subvar. serrulata")$qualifier, "subvar.")
  expect_equal(clean_one("Carex flacca subf. serrulata")$qualifier, "subf.")
  expect_equal(clean_one("Carex flacca convar. serrulata")$qualifier, "convar.")
  # notho- (hybrid) ranks fold to the base rank; the epithet is preserved
  res <- clean_one("Carex flacca nothosubsp. serrulata")
  expect_equal(res$cleaned, "Carex flacca serrulata")
  expect_equal(res$qualifier, "subsp.")
  expect_equal(clean_one("Carex flacca nothovar. serrulata")$qualifier, "var.")
  # spelled-out subspecies
  expect_equal(clean_one("Carex flacca subspecies serrulata")$qualifier, "subsp.")
})

test_that("cultivar and pathogen infrasubspecific markers are recognized", {
  expect_equal(clean_one("Malus domestica cv. Gala")$cleaned, "Malus domestica")
  expect_equal(clean_one("Malus domestica cv. Gala")$qualifier, "cv.")
  # forma specialis is one concept, not a bare forma + species
  res <- clean_one("Fusarium oxysporum f. sp. lycopersici")
  expect_equal(res$cleaned, "Fusarium oxysporum lycopersici")
  expect_equal(res$qualifier, "f.sp.")
  expect_equal(clean_one("Xanthomonas campestris pv. campestris")$qualifier, "pv.")
})

test_that("open-nomenclature and determination markers are recognized", {
  expect_equal(clean_one("Carex nr. flacca")$cleaned, "Carex flacca")
  expect_equal(clean_one("Carex nr. flacca")$qualifier, "nr.")

  # indeterminate reduces to a genus-level concept
  res <- clean_one("Carex indet.")
  expect_equal(res$cleaned, "Carex")
  expect_equal(res$qualifier, "indet.")
  expect_true(res$genus_only)

  # sp. nov.: the "nov." marker is stripped, sp. recorded
  expect_equal(clean_one("Carex sp. nov.")$cleaned, "Carex")
  expect_equal(clean_one("Carex sp. nov.")$qualifier, "sp.")
})

test_that("long/bare concept variants map like their short forms", {
  expect_equal(clean_one("Quercus robur s. lat.")$qualifier, "s.l.")   # long s.l.
  expect_equal(clean_one("Rubus fruticosus coll.")$qualifier, "s.l.")  # bare coll.
  expect_true(clean_one("Rubus fruticosus coll.")$is_aggregate)
})

test_that("species-group markers are recognized", {
  expect_equal(clean_one("Anopheles gambiae group")$cleaned, "Anopheles gambiae")
  expect_equal(clean_one("Anopheles gambiae group")$qualifier, "group")
  expect_equal(clean_one("Anopheles gambiae gr.")$qualifier, "group")
})

test_that("added markers do not match inside a real epithet", {
  # the (?=\\s|$) anchor keeps tokens from matching mid-word
  expect_true(is.na(clean_one("Carex novae-zelandiae")$qualifier))
  expect_true(is.na(clean_one("Carex gracilis")$qualifier))
  expect_true(is.na(clean_one("Convallaria majalis")$qualifier))
  expect_equal(clean_one("Carex novae-zelandiae")$cleaned, "Carex novae-zelandiae")
})

test_that("clean_one strips agg. qualifier", {
  res <- clean_one("Rubus fruticosus agg.")
  expect_equal(res$cleaned, "Rubus fruticosus")
  expect_equal(res$qualifier, "agg.")
})

test_that("clean_one records a stripped leading Cf. prefix as a qualifier", {
  res <- clean_one("Cf. Pinus sylvestris")
  expect_equal(res$cleaned, "Pinus sylvestris")
  expect_equal(res$qualifier, "cf.")

  # lowercase and no-period leading forms too
  expect_equal(clean_one("cf. Pinus sylvestris")$qualifier, "cf.")
  expect_equal(clean_one("Cf Pinus sylvestris")$qualifier, "cf.")
})

test_that("clean_names records a stripped leading Cf. prefix as a qualifier", {
  df <- clean_names(c("Cf. Pinus sylvestris", "Quercus robur"))
  expect_equal(df$qualifier[1L], "cf.")
  expect_equal(df$cleaned[1L], "Pinus sylvestris")
  expect_true(is.na(df$qualifier[2L]))
})

test_that("qualifier is canonicalized across spellings", {
  expect_equal(clean_one("Rubus fruticosus aggr.")$qualifier, "agg.")
  expect_equal(clean_one("Rubus fruticosus agg")$qualifier, "agg.")
  expect_equal(clean_one("Taraxacum officinale sensu lato")$qualifier, "s.l.")
  expect_equal(clean_one("Taraxacum officinale s. l.")$qualifier, "s.l.")
  expect_equal(clean_one("Ranunculus auricomus sensu stricto")$qualifier, "s.str.")
  expect_equal(clean_one("Taraxacum officinale sensu lato")$cleaned,
               "Taraxacum officinale")
})

test_that("qualifier_position distinguishes genus vs species placement", {
  expect_equal(clean_one("Cf. Pinus sylvestris")$qualifier_position, "genus")
  expect_equal(clean_one("Pinus cf. sylvestris")$qualifier_position, "species")
  expect_equal(clean_one("Rubus fruticosus agg.")$qualifier_position, "species")
  expect_true(is.na(clean_one("Quercus robur")$qualifier_position))

  df <- clean_names(c("Cf. Pinus sylvestris", "Pinus cf. sylvestris",
                      "Quercus robur"))
  expect_equal(df$qualifier_position, c("genus", "species", NA))
})

test_that("is_aggregate flags aggregate and sensu-lato concepts only", {
  expect_true(clean_one("Rubus fruticosus agg.")$is_aggregate)
  expect_true(clean_one("Taraxacum officinale s.l.")$is_aggregate)
  expect_false(clean_one("Pinus cf. sylvestris")$is_aggregate)
  expect_false(clean_one("Ranunculus auricomus s.str.")$is_aggregate)
  expect_false(clean_one("Quercus robur")$is_aggregate)

  df <- clean_names(c("Rubus fruticosus agg.", "Pinus cf. sylvestris"))
  expect_equal(df$is_aggregate, c(TRUE, FALSE))
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
  expect_named(df, c("original", "cleaned", "is_hybrid", "hybrid_type",
                     "qualifier", "qualifier_position", "is_aggregate",
                     "genus_only", "hybrid_name", "genus_abbrev"))
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

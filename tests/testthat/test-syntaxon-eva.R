# Real `Name alliance` values of the European Vegetation Archive (EVA,
# 2024-06-10 export; `n` is the number of plots carrying the value) against the
# EuroVegChecklist, each mapping checked by hand. The example database holds
# whole EVC classes, so every value here resolves as it does against the full
# backbone (data-raw/extract_syntaxon_examples.R).

eva_expected <- data.frame(
  value = c(
    "Fagion sylvaticae",
    "Arrhenatherion elatioris",
    "Bromion erecti",
    "Calthion palustris",
    "Phragmition australis",
    "Magnocaricion elatae",
    "Cirsio-Brachypodion pinnati",
    "Fagion silvaticae",
    "Phragmition communis",
    "Arrhenatherion",
    "Alno-Padion",
    "Cynosurion",
    "Molinion",
    "Dicrano-Pinion",
    "Fagion Luquet 1926",
    "Calthion (=Bromion racemosi Tx.1951)",
    "Luzulo luzuloidis-Fagion sylvaticae",
    "Abieti albae-Fagion sylvaticae",
    "Vaccinio-Piceion",
    "Magno-Caricion gracilis",
    "Tilio platyphylli-Acerion",
    "Luzulo-Fagion?",
    "Mesobromion erecti Br.-Bl. et Moor 1938 em. Oberdorfer 1957",
    "Quercion frainetto-cerris",
    "Carpinion",
    "Caricenion gracilis (Neuhäusl 1959) Oberd. et al. 1967",
    "Gravel Bar Vegetation"
  ),
  n = c(13560L, 7018L, 10083L, 9156L, 7282L, 3187L, 4801L, 3876L, 5029L,
        5351L, 3948L, 3615L, 3234L, 6767L, 2939L, 1530L, 1145L, 1962L, 4675L,
        2747L, 1983L, 16L, 23L, 175L, 3494L, 782L, 1752L),
  accepted = c(
    "Fagion sylvaticae", "Arrhenatherion elatioris", "Bromion erecti",
    "Calthion palustris", "Phragmition communis", "Magnocaricion elatae",
    "Cirsio-Brachypodion pinnati", "Fagion sylvaticae",
    "Phragmition communis", "Arrhenatherion elatioris", "Alnion incanae",
    "Cynosurion cristati", "Molinion caeruleae", "Dicrano-Pinion sylvestris",
    "Fagion sylvaticae", "Calthion palustris", "Luzulo-Fagion sylvaticae",
    "Fagion sylvaticae", "Piceion excelsae", "Magnocaricion gracilis",
    "Tilio-Acerion", "Luzulo-Fagion sylvaticae", "Bromion erecti",
    "Quercion confertae", NA, NA, NA),
  match_type = c(
    rep("exact", 7L), "exact_ci", "exact", "exact", "exact",
    rep("short_name", 12L), "fuzzy", "none", "none", "none"),
  stringsAsFactors = FALSE
)


test_that("EVA alliance labels resolve to the hand-checked EVC alliances", {
  withr::local_options(taxify.data_dir = taxify_example_data())
  res <- suppressWarnings(taxify(eva_expected$value, backbone = "evc",
                                 verbose = FALSE))
  expect_equal(res$accepted_name, eva_expected$accepted)
  expect_equal(res$match_type, eva_expected$match_type)
  # the lineage comes with every match
  hit <- !is.na(eva_expected$accepted)
  expect_false(anyNA(res$class[hit]))
  expect_equal(res$alliance[hit], eva_expected$accepted[hit])
  expect_equal(res$qualifier[eva_expected$value == "Luzulo-Fagion?"], "?")
})


test_that("a short form naming several alliances is left open, not guessed", {
  withr::local_options(taxify.data_dir = taxify_example_data())
  res <- suppressWarnings(taxify("Carpinion", backbone = "evc",
                                 verbose = FALSE))
  expect_equal(res$match_type, "none")
  expect_equal(res$n_ids, 3L)
  expect_setequal(strsplit(res$accepted_ids, "|", fixed = TRUE)[[1L]],
                  c("CA03A", "CA03C", "CB01G"))
})


test_that("a Czech association rolls up to its EVC alliance", {
  withr::local_options(taxify.data_dir = taxify_example_data())
  cz <- suppressWarnings(taxify(
    c("Pastinaco sativae-Arrhenatheretum elatioris",
      "TDA01 - Pastinaco sativae-Arrhenatheretum elatioris"),
    backbone = "vegcz", verbose = FALSE))
  expect_equal(cz$rank, c("association", "association"))
  expect_equal(cz$alliance, rep("Arrhenatherion elatioris", 2L))
  eu <- taxify(cz$alliance[1L], backbone = "evc", verbose = FALSE)
  expect_equal(eu$accepted_name, "Arrhenatherion elatioris")
  expect_equal(eu$class, "Molinio-Arrhenatheretea")

  chain <- suppressWarnings(taxify(
    c("Pastinaco sativae-Arrhenatheretum elatioris", "Bromion erecti"),
    backbone = c("vegcz", "evc"), verbose = FALSE))
  expect_equal(chain$backbone, c("vegcz", "evc"))
})

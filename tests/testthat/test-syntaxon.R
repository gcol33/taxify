# ---- Syntaxon names: parse, keys, matching against a syntaxon backbone ----

test_that("parse_name(code = 'syntaxon') splits name, author and annotations", {
  p <- parse_name(c(
    "Caricenion gracilis (Neuhäusl 1959) Oberd. et al. 1967",
    "Fagion sylvaticae Luquet 1926",
    "Festucion vaginatae de Soó 1929",
    "Conioselinion tatarici Golub et al. 2003 nom. inval. (5a)",
    "Koelerion arenariae Tx. 1937 corr. Gutermann et Mucina 1993",
    "Endymio non-scripti-Fagion Dierschke (1989) 1998",
    "Carici rupestris-Kobresietea bellardii Ohba 1974",
    "Dentario-Fagion sylvaticae Passarge 1968 (Regionalverband)"
  ), code = "syntaxon")

  expect_equal(p$name, c(
    "Caricenion gracilis", "Fagion sylvaticae", "Festucion vaginatae",
    "Conioselinion tatarici", "Koelerion arenariae",
    "Endymio non-scripti-Fagion", "Carici rupestris-Kobresietea bellardii",
    "Dentario-Fagion sylvaticae"))
  expect_equal(p$authorship, c(
    "(Neuhäusl 1959) Oberd. et al. 1967", "Luquet 1926",
    "de Soó 1929", "Golub et al. 2003",
    "Tx. 1937 corr. Gutermann et Mucina 1993", "Dierschke (1989) 1998",
    "Ohba 1974", "Passarge 1968"))
  expect_equal(p$rank, c("suballiance", "alliance", "alliance", "alliance",
                         "alliance", "alliance", "class", "alliance"))
  expect_equal(p$name_status[c(4L, 8L)],
               c("nom. inval. (5a)", "(Regionalverband)"))
})

test_that("syntaxon parse reads the forms vegetation databases write", {
  p <- parse_name(c(
    "25   - Molinio-Arrhenatheretea",
    "TDA   - Arrhenatherion elatioris",
    "Thero - Suaedion",
    "AVENULO-AMPELODESMION MAURITANICI",
    "Luzulo-Fagion?",
    "Fagion; Luzulo-Fagion",
    "Saxifrago-Fagenion, Tilio-Acerion, Aremonio-Fagion",
    "all. Caloplacion pyraceae, ord. Xeroverrucarietalia, cl. Epipetretea lichenosa",
    "Quercetalia(-etea) ilicis",
    "Luzulo fagion",
    "Iso‰tion Br.-Bl. 1936",
    "NA"
  ), code = "syntaxon")

  expect_equal(p$code[1:2], c("25", "TDA"))
  expect_equal(p$name, c(
    "Molinio-Arrhenatheretea", "Arrhenatherion elatioris", "Thero-Suaedion",
    "Avenulo-Ampelodesmion mauritanici", "Luzulo-Fagion", "Fagion",
    "Saxifrago-Fagenion", "Caloplacion pyraceae", "Quercetalia ilicis",
    "Luzulo-Fagion", "Isoëtion", NA))
  expect_equal(p$qualifier[5L], "?")
  expect_equal(p$rank[c(1L, 7L, 9L)], c("class", "suballiance", "order"))
})

test_that("rank is read from the last stem's suffix", {
  expect_equal(
    syntaxon_rank_of(c("Querco-Fagetea", "Fagetalia sylvaticae",
                       "Fagion sylvaticae", "Galio-Fagenion", "Galio-Fagetum",
                       "Galio-Fagetum luzuletosum", "Pinion")),
    c("class", "order", "alliance", "suballiance", "association",
      "subassociation", "alliance"))
})

test_that("normalize_syntaxon_name folds the spelling variants", {
  k <- normalize_syntaxon_name(c("Fagion silvaticae", "Fagion sylvaticae",
                                 "Juncion gerardi", "Juncion gerardii",
                                 "Thero - Suaedion", "Thero-Suaedion",
                                 "Isoëtion", "Isoetion", NA))
  expect_equal(k[1L], k[2L])
  expect_equal(k[3L], k[4L])
  expect_equal(k[5L], k[6L])
  expect_equal(k[7L], k[8L])
  expect_true(is.na(k[9L]))
})

test_that("evc is a syntaxon backbone outside the default chain", {
  expect_equal(backbone_code(c("wfo", "evc")), c("taxon", "syntaxon"))
  be <- evc_backend()
  expect_equal(be$code, "syntaxon")
  expect_equal(be$col_map$hierarchy,
               c("class", "order", "alliance", "association"))

  local_mock_evc()
  expect_false("evc" %in% installed_backbones())
})

test_that("taxify() matches syntaxa and reports the accepted lineage", {
  local_mock_evc()
  res <- taxify(c("Fagion sylvaticae Luquet 1926", "Mesobromion erecti",
                  "Fagion silvaticae", "TDA - Arrhenatherion elatioris",
                  "Molinio-Arrhenatheretea", "Arrhenatheretalia elatioris",
                  "Brachypodietalia pinnata"),
                backbone = "evc", verbose = FALSE)

  expect_equal(res$accepted_name, c(
    "Fagion sylvaticae", "Bromion erecti", "Fagion sylvaticae",
    "Arrhenatherion elatioris", "Molinio-Arrhenatheretea",
    "Arrhenatheretalia elatioris", "Brachypodietalia pinnati"))
  expect_equal(res$match_type, c("exact", "exact", "exact_ci", "exact",
                                 "exact", "exact", "fuzzy"))
  expect_equal(res$is_synonym, c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE,
                                 FALSE))
  expect_equal(res$accepted_id[1:2], c("CA02B", "DA03A"))
  expect_equal(res$rank[c(1L, 5L, 6L)], c("alliance", "class", "order"))
  expect_equal(res$class[1:2], c("Carpino-Fagetea sylvaticae",
                                 "Festuco-Brometea"))
  expect_equal(res$order[2L], "Brachypodietalia pinnati")
  expect_equal(res$alliance[c(2L, 5L)], c("Bromion erecti", NA))
  expect_equal(res$accepted_authorship[2L], "Koch 1926")
  expect_equal(res$backbone[1L], "evc")
})

test_that("a syntaxon result carries the hierarchy, not the taxon columns", {
  local_mock_evc()
  res <- taxify("Fagion sylvaticae", backbone = "evc", verbose = FALSE)
  expect_s3_class(res, "taxify_result")
  expect_true(all(c("class", "order", "alliance", "association") %in%
                    names(res)))
  expect_false(any(c("family", "genus", "epithet", "kingdom_group",
                     "hybrid_type") %in% names(res)))
  expect_equal(match("class", names(res)), match("rank", names(res)) + 1L)
})

test_that("fuzzy matching does not cross a rank suffix", {
  local_mock_evc()
  # Caricenion (a suballiance) is two edits from Caricion (an alliance).
  res <- taxify("Caricenion gracilis", backbone = "evc", verbose = FALSE)
  expect_equal(res$match_type, "none")
  # the same distance at one rank still matches
  res <- taxify("Caricion graciliss", backbone = "evc", verbose = FALSE)
  expect_equal(res$accepted_name, "Magnocaricion gracilis")
  expect_equal(res$match_type, "fuzzy")
})

test_that("fuzzy matching does not reach a name without a rank suffix", {
  names_df <- clean_syntaxon_names(c("Deschampsietum caespitosae",
                                     "Deschampsiatum caespitosae"))
  matches <- data.frame(row_idx = 1:2,
                        canonical_name = "Deschampsiosum cespitosae",
                        stringsAsFactors = FALSE)
  kept <- filter_fuzzy_syntaxon(matches, names_df, "canonical_name")
  # an -etum query has a rank, the -osum name has none; a query whose suffix
  # is misspelt has no rank either and keeps the candidate
  expect_equal(kept$row_idx, 2L)
})

test_that("a fuzzy match on a misspelt first word keeps the hierarchy", {
  local_mock_evc()
  # Magnokaricion misses the first-word block and is reached by the prefix pass
  res <- taxify("Magnokaricion gracilis", backbone = "evc", verbose = FALSE)
  expect_equal(res$match_type, "fuzzy")
  expect_equal(res$accepted_name, "Magnocaricion gracilis")
  expect_equal(res$class, "Phragmito-Magnocaricetea")
  expect_equal(res$alliance, "Magnocaricion gracilis")
})

test_that("an input author settles a syntaxon homonym", {
  local_mock_evc()
  res <- suppressWarnings(taxify(c("Cynosurion", "Cynosurion Tx. 1947",
                                   "Cynosurion Br.-Bl. 1950"),
                                 backbone = "evc", verbose = FALSE))
  expect_equal(res$n_ids, c(2L, 2L, 2L))
  expect_equal(res$accepted_name[2:3], c("Cynosurion cristati",
                                         "Arrhenatherion elatioris"))
  expect_equal(res$alliance[2:3], c("Cynosurion cristati",
                                    "Arrhenatherion elatioris"))
})

test_that("taxon and syntaxon backbones are not combined", {
  local_mock_evc()
  expect_error(taxify("Fagion sylvaticae", backbone = c("wfo", "evc"),
                      verbose = FALSE), "different nomenclature codes")
  expect_error(taxify("Fagion sylvaticae", backbone = "evc", kingdom = "plants",
                      verbose = FALSE), "constrain taxon names")
})

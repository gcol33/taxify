# ---- ITIS backend tests ----
#
# ITIS is one of the three backbones a fresh install downloads, so the default
# first-run chain runs through it. Everything below is offline: the fixture in
# helper-mock-itis-backbone.R is the flattened shape taxifydb::read_itis()
# writes, including the family / genus / kingdom columns resolved by walking the
# parent_tsn chain.

itis_fixture <- function(env = parent.frame()) {
  path <- mock_itis_backbone_vtr()
  set_backbone_path("itis", path)
  # skip the once-per-session network version check
  .taxify_env[[".version_checked.itis"]] <- TRUE
  withr::defer(set_backbone_path("itis", NULL), envir = env)
  path
}


# -- Backend construction --

test_that("itis_backend creates correct object", {
  be <- itis_backend()
  expect_s3_class(be, "taxify_itis")
  expect_s3_class(be, "taxify_backend")
  expect_equal(be$name, "itis")
  expect_equal(be$version, "2025.04")
})

test_that("ITIS col_map is the unified Darwin Core schema", {
  be <- itis_backend()
  expect_equal(be$col_map$name, "canonical_name")
  expect_equal(be$col_map$id, "taxon_id")
  expect_equal(be$col_map$rank, "taxon_rank")
  expect_equal(be$col_map$status, "taxonomic_status")
  expect_equal(be$col_map$acc_id, "accepted_name_usage_id")
  expect_equal(be$col_map$acc_name, "accepted_name")
  expect_equal(be$col_map$epithet, "specific_epithet")
})

test_that("resolve_backend('itis') dispatches to the ITIS backend", {
  be <- taxify:::resolve_backend("itis")
  expect_s3_class(be, "taxify_itis")
  expect_identical(be$name, "itis")
  expect_identical(be$version, "2025.04")
  # An already-constructed backend passes through untouched.
  expect_identical(taxify:::resolve_backend(be), be)
})

test_that("ITIS does not run the prefix-blocked fuzzy pass", {
  # The registry sets prefix_fallback for the three broad plant/all-kingdom
  # backbones only; ITIS is not one of them.
  expect_null(itis_backend()$prefix_fallback)
  expect_true(isTRUE(wfo_backend()$prefix_fallback))
})

test_that("ITIS is in the registry and in the first-run backbone set", {
  reg <- taxify:::.backbone_registry()
  i <- match("itis", reg$name)
  expect_false(is.na(i))
  expect_equal(reg$label[i], "the ITIS backbone")
  expect_equal(reg$source[i], "https://www.itis.gov")
  expect_true("itis" %in% taxify:::.default_backbone_set())
})


# -- Exact matching --

test_that("ITIS exact matching finds known species", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("Ursus arctos"), backbone)

  expect_equal(result$matched_name[1L], "Ursus arctos")
  expect_equal(result$match_type[1L], "exact")
  expect_equal(result$taxon_id[1L], "180543")
  expect_equal(result$genus[1L], "Ursus")
  expect_equal(result$epithet[1L], "arctos")
  expect_equal(result$family[1L], "Ursidae")
  expect_equal(result$authorship[1L], "Linnaeus, 1758")
  expect_true(is.na(result$fuzzy_dist[1L]))
})

test_that("ITIS case-insensitive matching works", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("ursus arctos"), backbone)

  expect_equal(result$matched_name[1L], "Ursus arctos")
  expect_equal(result$match_type[1L], "exact_ci")
  expect_equal(result$taxon_id[1L], "180543")
})

test_that("ITIS unmatched names have NA match_type", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("Nonexistus imaginus"), backbone)

  expect_true(is.na(result$match_type[1L]))
  expect_true(is.na(result$matched_name[1L]))
})


# -- Synonym resolution --

test_that("ITIS synonym resolves to its accepted TSN and name", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("Ursus horribilis"), backbone)

  expect_equal(result$matched_name[1L], "Ursus horribilis")
  expect_true(result$is_synonym[1L])
  expect_equal(result$taxon_id[1L], "180544")
  expect_equal(result$accepted_name[1L], "Ursus arctos")
  expect_equal(result$accepted_id[1L], "180543")
})

test_that("ITIS synonym across genera carries the accepted genus through", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("Felis canadensis"), backbone)

  expect_equal(result$matched_name[1L], "Felis canadensis")
  expect_true(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Lynx canadensis")
  expect_equal(result$accepted_id[1L], "180596")
  expect_equal(result$genus[1L], "Lynx")
})

test_that("ITIS accepted names resolve to themselves", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names("Salmo salar"), backbone)

  expect_false(result$is_synonym[1L])
  expect_equal(result$accepted_name[1L], "Salmo salar")
  expect_equal(result$accepted_id[1L], "161996")
})


# -- Fuzzy matching --

test_that("ITIS fuzzy matching catches a typo", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()

  result <- match_exact(be, clean_names("Ursus arctus"), backbone)
  expect_true(is.na(result$match_type[1L]))

  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_equal(result$matched_name[1L], "Ursus arctos")
  expect_equal(result$match_type[1L], "fuzzy")
  expect_equal(result$taxon_id[1L], "180543")
  expect_true(result$fuzzy_dist[1L] > 0 && result$fuzzy_dist[1L] <= 0.2)
})

test_that("ITIS fuzzy matching respects the threshold", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()

  result <- match_exact(be, clean_names("Zzzzzz xxxxxx"), backbone)
  result <- match_fuzzy(be, result, backbone, method = "dl", threshold = 0.2)
  expect_true(is.na(result$match_type[1L]))
})


# -- NA handling --

test_that("ITIS handles NA and empty inputs without crashing", {
  be <- itis_backend()
  backbone <- mock_itis_backbone_vtr()
  result <- match_exact(be, clean_names(c("Ursus arctos", NA, "")), backbone)

  expect_equal(nrow(result), 3L)
  expect_equal(result$matched_name[1L], "Ursus arctos")
  expect_true(is.na(result$matched_name[2L]))
  expect_true(is.na(result$matched_name[3L]))
})


# -- End-to-end through taxify() --

test_that("taxify(backend = 'itis') resolves names, synonyms and typos", {
  itis_fixture()
  res <- taxify(c("Ursus arctos", "Felis canadensis", "Acer saccharophorum",
                  "Ursus arctus", "Nonexistus imaginus"),
                backend = "itis", verbose = FALSE)

  expect_equal(nrow(res), 5L)
  expect_equal(res$accepted_name,
               c("Ursus arctos", "Lynx canadensis", "Acer saccharum",
                 "Ursus arctos", NA))
  expect_equal(res$accepted_id,
               c("180543", "180596", "28728", "180543", NA))
  expect_equal(res$match_type, c("exact", "exact", "exact", "fuzzy", "none"))
  expect_equal(res$backend, c(rep("itis", 4L), NA))
  expect_equal(res$backbone_version[1L], "itis:2025.04")
})

test_that("ITIS carries the parent_tsn-resolved family and genus into the result", {
  itis_fixture()
  res <- taxify(c("Acer saccharophorum", "Toxicodendron radicans",
                  "Salmo salar sebago"),
                backend = "itis", verbose = FALSE)

  expect_equal(res$family, c("Sapindaceae", "Anacardiaceae", "Salmonidae"))
  expect_equal(res$genus, c("Acer", "Toxicodendron", "Salmo"))
  expect_equal(res$rank, c("species", "species", "subspecies"))
})

test_that("add_classification() fills kingdom from ITIS and leaves deeper ranks NA", {
  # ITIS resolves kingdom (and family/genus) by walking parent_tsn, but stores
  # no phylum/class/order column, so those stay NA rather than being invented.
  itis_fixture()
  res <- taxify(c("Ursus arctos", "Acer saccharum"), backend = "itis",
                verbose = FALSE)
  cl <- add_classification(res, verbose = FALSE)

  expect_equal(cl$kingdom, c("Animalia", "Plantae"))
  expect_true(all(is.na(cl$phylum)))
  expect_true(all(is.na(cl$class)))
  expect_true(all(is.na(cl$order)))
})

test_that("upstream() walks the ITIS classification kingdom -> genus", {
  itis_fixture()
  up <- upstream("Ursus arctos", backend = "itis", verbose = FALSE)

  expect_equal(up$rank, c("kingdom", "family", "genus"))
  expect_equal(up$name, c("Animalia", "Ursidae", "Ursus"))
  expect_true(all(up$backend == "itis"))
})

test_that("synonyms() lists the ITIS synonyms of an accepted taxon", {
  itis_fixture()
  syn <- synonyms("Ursus arctos", backend = "itis", verbose = FALSE)

  expect_equal(nrow(syn), 1L)
  expect_equal(syn$synonym, "Ursus horribilis")
  expect_equal(syn$taxon_id, "180544")
  expect_equal(syn$accepted_name, "Ursus arctos")
})

test_that("children() lists accepted ITIS species and skips synonyms", {
  itis_fixture()
  kids <- children("Acer", backend = "itis", verbose = FALSE)

  expect_equal(kids$name, "Acer saccharum")
  expect_equal(kids$taxon_id, "28728")
  expect_false("Acer saccharophorum" %in% kids$name)
})

test_that("id2name() resolves an ITIS TSN to its name and accepted taxon", {
  itis_fixture()
  out <- id2name("180544", backend = "itis", verbose = FALSE)

  expect_equal(out$name, "Ursus horribilis")
  expect_true(out$is_synonym)
  expect_equal(out$accepted_name, "Ursus arctos")
  expect_equal(out$family, "Ursidae")
})

test_that("ITIS picks up names a preceding backbone in the chain misses", {
  itis_fixture()
  set_backbone_path("wfo", mock_backbone_vtr())
  .taxify_env[[".version_checked.wfo"]] <- TRUE
  withr::defer(set_backbone_path("wfo", NULL))

  res <- taxify(c("Quercus robur", "Ursus arctos"),
                backend = c("wfo", "itis"), verbose = FALSE)

  expect_equal(res$backend, c("wfo", "itis"))
  expect_equal(res$accepted_name, c("Quercus robur", "Ursus arctos"))
  expect_equal(res$accepted_id[2L], "180543")
})

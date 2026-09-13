# An infraspecific name matches its own backbone record, and resolves to its
# species only when the backbone does not carry it (#71, #78). The shared wfo
# fixture holds autonyms only (Quercus robur subsp. robur), where species and
# subspecies share an accepted name, so it cannot tell the two apart; this
# fixture carries accepted non-autonym subspecies and varieties.

infra_backbone_df <- function() {
  data.frame(
    taxon_id = sprintf("wcvp-%03d", 1:9),
    canonical_name = c(
      "Pinus nigra",
      "Pinus nigra subsp. laricio",
      "Pinus nigra subsp. salzmannii",
      "Quercus petraea",
      "Quercus petraea subsp. huguetiana",
      "Mentha piperita nothosubsp. citrata",
      "Mentha piperita",
      "Panthera leo",
      "Panthera leo persica"
    ),
    taxon_rank = c("SPECIES", "SUBSPECIES", "SUBSPECIES", "SPECIES",
                   "SUBSPECIES", "NOTHOSUBSPECIES", "SPECIES", "SPECIES",
                   "SUBSPECIES"),
    taxonomic_status = "ACCEPTED",
    accepted_name_usage_id = NA_character_,
    family = c(rep("Pinaceae", 3), rep("Fagaceae", 2), rep("Lamiaceae", 2),
               rep("Felidae", 2)),
    genus = c(rep("Pinus", 3), rep("Quercus", 2), rep("Mentha", 2),
              rep("Panthera", 2)),
    specific_epithet = c(rep("nigra", 3), rep("petraea", 2),
                         rep("piperita", 2), rep("leo", 2)),
    authorship = "L.",
    infraspecific_epithet = c(NA, "laricio", "salzmannii", NA, "huguetiana",
                              "citrata", NA, NA, "persica"),
    stringsAsFactors = FALSE
  )
}

setup_infra_backbone <- function(env = parent.frame()) {
  df <- precompute_keys(infra_backbone_df(), "canonical_name", "genus",
                        "specific_epithet")
  df <- embed_accepted(df,
    id_col = "taxon_id", acc_id_col = "accepted_name_usage_id",
    name_col = "canonical_name", family_col = "family", genus_col = "genus",
    status_col = "taxonomic_status", authorship_col = "authorship")
  df <- df[order(df$genus), ]
  vtr <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, vtr)
  dd <- tempfile("dd_infra_")
  dir.create(file.path(dd, "wfo", "latest"), recursive = TRUE)
  file.copy(vtr, file.path(dd, "wfo", "latest", "wfo.vtr"))
  withr::local_options(list(taxify.data_dir = dd), .local_envir = env)
  set_backbone_path("wfo", vtr)
  withr::defer(set_backbone_path("wfo", NULL), envir = env)
  # A new vtr path per call, so the session block memo never serves the
  # shared fixture's rows here.
  invisible(vtr)
}

test_that("an accepted subspecies matches its own record, not its species", {
  setup_infra_backbone()
  res <- taxify(c("Pinus nigra subsp. laricio", "Pinus nigra subsp. salzmannii",
                  "Quercus petraea subsp. huguetiana"),
                backbone = "wfo", verbose = FALSE)
  expect_equal(res$taxon_id, c("wcvp-002", "wcvp-003", "wcvp-005"))
  expect_equal(res$rank, rep("subspecies", 3))
  expect_equal(res$match_type, rep("exact", 3))
  expect_equal(res$accepted_name,
               c("Pinus nigra subsp. laricio", "Pinus nigra subsp. salzmannii",
                 "Quercus petraea subsp. huguetiana"))
  expect_true(all(is.na(res$qualifier)))
})

test_that("rank-marker spellings and an author before the marker still match", {
  setup_infra_backbone()
  res <- taxify(c("Pinus nigra ssp. laricio", "Pinus nigra Subsp. laricio",
                  "Pinus nigra subspecies laricio",
                  "Pinus nigra J.F.Arnold subsp. laricio (Poir.) Maire"),
                backbone = "wfo", verbose = FALSE)
  expect_equal(res$taxon_id, rep("wcvp-002", 4))
})

test_that("a misspelled infraspecific epithet reaches fuzzy matching", {
  setup_infra_backbone()
  res <- taxify("Pinus nigra subsp. laricia", backbone = "wfo", verbose = FALSE)
  expect_equal(res$match_type, "fuzzy")
  expect_equal(res$taxon_id, "wcvp-002")
})

test_that("an absent infraspecific name resolves to its species as rank_fallback", {
  setup_infra_backbone()
  res <- taxify(c("Quercus petraea var. xyzzyensis", "Pinus nigra subsp. laricio"),
                backbone = "wfo", fuzzy = FALSE, verbose = FALSE)
  expect_equal(res$match_type, c("rank_fallback", "exact"))
  expect_equal(res$taxon_id, c("wcvp-004", "wcvp-002"))
  expect_equal(res$backbone, c("wfo", "wfo"))
  expect_equal(attr(res, "taxify_meta")$match_tally$rank_fallback, 1L)
})

test_that("notho- ranks and marker-less trinomials reach their records", {
  setup_infra_backbone()
  res <- taxify(c("Mentha piperita nssp. citrata", "Mentha piperita subsp. citrata",
                  "Panthera leo persica", "Panthera leo ssp. persica"),
                backbone = "wfo", fuzzy = FALSE, verbose = FALSE)
  expect_equal(res$taxon_id, c("wcvp-006", "wcvp-006", "wcvp-009", "wcvp-009"))
  expect_false(any(res$match_type == "rank_fallback"))
})

test_that("reconcile() and inspect() classify the species fallback", {
  setup_infra_backbone()
  rec <- reconcile(c("Quercus petraea var. xyzzyensis", "Pinus nigra subsp. laricio"),
                   backbone = "wfo", fuzzy = FALSE, verbose = FALSE)
  expect_equal(rec$status, c("rank_fallback", "unchanged"))

  res <- taxify(c("Quercus petraea var. xyzzyensis", "Pinus nigra subsp. laricio"),
                backbone = "wfo", fuzzy = FALSE, verbose = FALSE)
  ins <- suppressWarnings(inspect(res))
  expect_true(any(grepl("rank_fallback", ins$anomalies)))
  expect_false(any(grepl("case", ins$anomalies)))
})

test_that("clean_names keeps canonical rank markers and reports infra_rank", {
  cl <- clean_names(c("Poa annua L. subsp. exilis (Tomm.) Asch. & Graebn.",
                      "Quercus robur Var. pedunculiflora",
                      "QUERCUS ROBUR VAR. PEDUNCULIFLORA",
                      "Carex flacca nothosubsp. serrulata",
                      "Poa annua L. f.",
                      "Quercus robur"))
  expect_equal(cl$cleaned,
               c("Poa annua subsp. exilis", "Quercus robur var. pedunculiflora",
                 "QUERCUS robur var. pedunculiflora",
                 "Carex flacca nothosubsp. serrulata", "Poa annua",
                 "Quercus robur"))
  expect_equal(cl$infra_rank, c("subsp.", "var.", "var.", "subsp.", NA, NA))
  expect_true(all(is.na(cl$qualifier)))

  v <- taxify:::infra_key_variants(cl$cleaned)
  expect_equal(v$folded[4], "Carex flacca subsp. serrulata")
  expect_equal(v$bare[1], "Poa annua exilis")
  expect_true(is.na(v$bare[6]))
})

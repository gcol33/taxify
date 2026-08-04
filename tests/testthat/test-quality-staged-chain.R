# ---- The fallback chain is staged by match quality, not by backbone (#35) ----
#
# Acilius sulcatus is a diving beetle (Dytiscidae). Acalles is a weevil genus
# (Curculionidae), and "Acalles sulcatus" sits 3 edits away, inside the default
# fuzzy threshold. COL carries the weevil and not the diving beetle; GBIF
# carries the diving beetle as an accepted name. Asking COL first for any match
# it can reach therefore answered a beetle query with a weevil, and GBIF was
# never consulted.
#
# The coverage fixture deliberately gives the leading backbone BOTH genera, so
# the out-of-scope pre-filter cannot be what saves the name here. Only the
# staging can.

mock_two_row_backbone_vtr <- function(canonical, family, genus, epithet,
                                      authorship = NA_character_) {
  df <- data.frame(
    taxon_id               = paste0("T", seq_along(canonical)),
    canonical_name         = canonical,
    scientificName         = trimws(paste(canonical, ifelse(is.na(authorship), "",
                                                            authorship))),
    taxon_rank             = rep("SPECIES", length(canonical)),
    taxonomic_status       = rep("ACCEPTED", length(canonical)),
    accepted_name_usage_id = rep(NA_character_, length(canonical)),
    family                 = family,
    genus                  = genus,
    specific_epithet       = epithet,
    authorship             = authorship,
    infraspecific_epithet  = rep(NA_character_, length(canonical)),
    kingdom                = rep("Animalia", length(canonical)),
    stringsAsFactors       = FALSE
  )
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(df,
    id_col     = "taxon_id",
    acc_id_col = "accepted_name_usage_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus",
    status_col = "taxonomic_status"
  )
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

# COL = the weevil only; GBIF = the diving beetle. Both genera are registered
# and both are listed as covered by COL, so nothing is filtered out of scope.
set_beetle_fixture <- function(env = parent.frame()) {
  set_backbone_path("col", mock_two_row_backbone_vtr(
    canonical  = "Acalles sulcatus",
    family     = "Curculionidae",
    genus      = "Acalles",
    epithet    = "sulcatus",
    authorship = "Rosenhauer"
  ))
  set_backbone_path("gbif", mock_two_row_backbone_vtr(
    canonical  = "Acilius sulcatus",
    family     = "Dytiscidae",
    genus      = "Acilius",
    epithet    = "sulcatus",
    authorship = "(Linnaeus, 1758)"
  ))

  .taxify_env$register <- data.frame(
    genus         = c("Acalles",       "Acilius"),
    kingdom       = c("Animalia",      "Animalia"),
    phylum        = c("Arthropoda",    "Arthropoda"),
    class         = c("Insecta",       "Insecta"),
    order         = c("Coleoptera",    "Coleoptera"),
    family        = c("Curculionidae", "Dytiscidae"),
    kingdom_group = c("animalia",      "animalia"),
    taxon_group   = c("insect",        "insect"),
    life_form     = c("insect",        "insect"),
    stringsAsFactors = FALSE
  )

  cov_path <- mock_coverage_vtr(
    genus    = c("Acalles", "Acilius", "Acilius"),
    backbone = c("col",     "col",     "gbif")
  )
  clear_coverage_cache()
  withr::defer({
    set_backbone_path("col", NULL)
    set_backbone_path("gbif", NULL)
    .taxify_env$register <- NULL
    clear_coverage_cache()
  }, envir = env)

  cov_path
}


test_that("an exact match in a later backbone beats a fuzzy one in an earlier (#35)", {
  cov_path <- set_beetle_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Acilius sulcatus", backbone = c("col", "gbif"), verbose = FALSE)
  )

  expect_equal(result$accepted_name, "Acilius sulcatus")
  expect_equal(result$match_type, "exact")
  expect_equal(result$backbone, "gbif")
  expect_equal(result$family, "Dytiscidae")
})


test_that("the leading backbone still wins when both match at the same quality", {
  # Backbone priority is what decides between two matches of equal quality, so
  # a name COL holds exactly must stay with COL even though GBIF follows it.
  cov_path <- set_beetle_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Acalles sulcatus", backbone = c("col", "gbif"), verbose = FALSE)
  )

  expect_equal(result$match_type, "exact")
  expect_equal(result$backbone, "col")
  expect_equal(result$family, "Curculionidae")
})


test_that("fuzzy still resolves against the leading backbone when no backbone matches exactly", {
  # With no exact hit anywhere the second sweep runs, and priority order applies
  # inside the fuzzy tier exactly as before.
  cov_path <- set_beetle_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify("Acalles sulcatvs", backbone = c("col", "gbif"), verbose = FALSE)
  )

  expect_equal(result$accepted_name, "Acalles sulcatus")
  expect_equal(result$match_type, "fuzzy")
  expect_equal(result$backbone, "col")
})


test_that("fuzzy = FALSE runs one sweep and reaches the later backbone", {
  cov_path <- set_beetle_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify(c("Acilius sulcatus", "Acalles sulcatvs"),
           backbone = c("col", "gbif"), fuzzy = FALSE, verbose = FALSE)
  )

  expect_equal(result$match_type, c("exact", "none"))
  expect_equal(result$backbone, c("gbif", NA))
})


test_that("staging holds across a batch mixing both tiers", {
  # The exact hit must not be pulled back to COL just because the batch also
  # contains a name only COL can answer, and vice versa.
  cov_path <- set_beetle_fixture()

  result <- with_mocked_bindings(
    ensure_coverage = function(verbose = TRUE) cov_path,
    taxify(c("Acilius sulcatus", "Acalles sulcatus", "Acalles sulcatvs"),
           backbone = c("col", "gbif"), verbose = FALSE)
  )

  expect_equal(result$accepted_name,
               c("Acilius sulcatus", "Acalles sulcatus", "Acalles sulcatus"))
  expect_equal(result$match_type, c("exact", "exact", "fuzzy"))
  expect_equal(result$backbone, c("gbif", "col", "col"))
})

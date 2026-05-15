# Creates a small GBIF-like backbone for testing.
# Mirrors what the runtime sees: a pre-built `.vtr` from taxifydb. Status values
# are already mapped to ACCEPTED/SYNONYM (taxifydb collapses GBIF-native values
# like HOMOTYPIC_SYNONYM at build time). GBIF differences from WFO/COL:
# - id (character, originally integer) as taxon key
# - canonical_name (without authorship) for matching
# - genus_or_above instead of genus
# - is_synonym_flag (logical) + accepted_id (parent_key for synonyms)
# - family already denormalized (resolved from family_key during conversion)

mock_gbif_backbone_df <- function() {
  data.frame(
    id = c(
      "2878688", "2878691", "2878689", "2878700",
      "5285637", "5285640", "2704173", "2704174",
      "3040970", "3040972", "3005623", "2878695",
      "7768191", "2685484", "2685490"
    ),
    canonical_name = c(
      "Quercus robur",
      "Quercus petraea",
      "Quercus robur subsp. robur",
      "Quercus pedunculata",
      "Pinus sylvestris",
      "Pinus silvestris",
      "Festuca rubra",
      "Festuca rubra subsp. rubra",
      "Salix alba",
      "Salix fragilis",
      "Rosa canina",
      "Quercus hispanica",
      "Festulolium",
      "Abies alba",
      "Abies pectinata"
    ),
    scientific_name = c(
      "Quercus robur L.",
      "Quercus petraea (Matt.) Liebl.",
      "Quercus robur subsp. robur L.",
      "Quercus pedunculata Ehrh.",
      "Pinus sylvestris L.",
      "Pinus silvestris",
      "Festuca rubra L.",
      "Festuca rubra subsp. rubra L.",
      "Salix alba L.",
      "Salix fragilis L.",
      "Rosa canina L.",
      "Quercus hispanica Lam.",
      "Festulolium Asch. & Graebn.",
      "Abies alba Mill.",
      "Abies pectinata (Lam.) Kunze"
    ),
    rank = c(
      "SPECIES", "SPECIES", "SUBSPECIES", "SPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SUBSPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "GENUS", "SPECIES", "SPECIES"
    ),
    status = c(
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "SYNONYM", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM"
    ),
    is_synonym_flag = c(
      FALSE, FALSE, FALSE, TRUE,
      FALSE, TRUE, FALSE, FALSE,
      FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, TRUE
    ),
    parent_key = c(
      "2877951", "2877951", "2878688", "2878688",
      "5284517", "5285637", "2704172", "2704173",
      "3040969", "3040969", "3005622", "2877951",
      "7768190", "2685483", "2685484"
    ),
    accepted_id = c(
      NA, NA, NA, "2878688",
      NA, "5285637", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "2685484"
    ),
    family = c(
      "Fagaceae", "Fagaceae", "Fagaceae", "Fagaceae",
      "Pinaceae", "Pinaceae", "Poaceae", "Poaceae",
      "Salicaceae", "Salicaceae", "Rosaceae", "Fagaceae",
      "Poaceae", "Pinaceae", "Pinaceae"
    ),
    genus_or_above = c(
      "Quercus", "Quercus", "Quercus", "Quercus",
      "Pinus", "Pinus", "Festuca", "Festuca",
      "Salix", "Salix", "Rosa", "Quercus",
      "Festulolium", "Abies", "Abies"
    ),
    specific_epithet = c(
      "robur", "petraea", "robur", "pedunculata",
      "sylvestris", "silvestris", "rubra", "rubra",
      "alba", "fragilis", "canina", "hispanica",
      NA, "alba", "pectinata"
    ),
    authorship = c(
      "L.", "(Matt.) Liebl.", "L.", "Ehrh.",
      "L.", NA, "L.", "L.",
      "L.", "L.", "L.", "Lam.",
      "Asch. & Graebn.", "Mill.", "(Lam.) Kunze"
    ),
    infra_specific_epithet = c(
      NA, NA, "robur", NA,
      NA, NA, NA, "rubra",
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    notho_type = c(
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, "SPECIFIC",
      "GENERIC", NA, NA
    ),
    nom_status = c(
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}"
    ),
    bracket_authorship = c(
      NA, "Matt.", NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, "Lam."
    ),
    bracket_year = c(
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    year = c(
      "1753", "1784", NA, NA,
      "1753", NA, "1753", NA,
      "1753", "1753", "1753", NA,
      NA, "1768", NA
    ),
    name_published_in = c(
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    origin = c(
      "SOURCE", "SOURCE", "SOURCE", "SOURCE",
      "SOURCE", "SOURCE", "SOURCE", "SOURCE",
      "SOURCE", "SOURCE", "SOURCE", "SOURCE",
      "SOURCE", "SOURCE", "SOURCE"
    ),
    issues = c(
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}", "{}",
      "{}", "{}", "{}"
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock GBIF backbone as a vectra .vtr file
#'
#' Mirrors what taxify sees in production: a pre-built `.vtr` (status already
#' mapped to ACCEPTED/SYNONYM) put through the runtime-side key precomputation
#' and accepted-info embedding.
#'
#' @return Path to the temporary .vtr file.
mock_gbif_backbone_vtr <- function() {
  df <- mock_gbif_backbone_df()

  # Precompute keys (GBIF uses canonical_name + genus_or_above)
  df <- precompute_keys(df, "canonical_name", "genus_or_above",
                        "specific_epithet")

  # Embed accepted taxon info
  df <- embed_accepted(df,
    id_col     = "id",
    acc_id_col = "accepted_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus_or_above",
    status_col = "status"
  )

  # Sort by genus for zone-map pruning
  df <- df[order(df$genus_or_above, na.last = TRUE), ]
  rownames(df) <- NULL

  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

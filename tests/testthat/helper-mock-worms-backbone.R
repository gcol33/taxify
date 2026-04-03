# Creates a small WoRMS-like backbone for testing.
# WoRMS uses unified schema (canonical_name, taxon_id, etc.).
# Marine-focused taxonomy with habitat flags available via
# SpeciesProfile. Uses numeric AphiaIDs as taxon_id.

mock_worms_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "127160", "127161", "127160_sub1", "127160_syn_1",
      "127162", "127162_syn_1", "127163", "127163_sub1",
      "127164", "127165", "127166", "127167",
      "127168", "127169", "127169_syn_1"
    ),
    canonical_name = c(
      "Gadus morhua",
      "Gadus macrocephalus",
      "Gadus morhua subsp. morhua",
      "Gadus callarias",
      "Salmo salar",
      "Salmo salmo",
      "Crassostrea gigas",
      "Crassostrea gigas subsp. gigas",
      "Posidonia oceanica",
      "Zostera marina",
      "Tursiops truncatus",
      "Carcharodon carcharias",
      "Laminaria",
      "Mytilus edulis",
      "Mytilus pellucidus"
    ),
    taxon_rank = c(
      "SPECIES", "SPECIES", "SUBSPECIES", "SPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SUBSPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "GENUS", "SPECIES", "SPECIES"
    ),
    taxonomic_status = c(
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "SYNONYM", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM"
    ),
    accepted_name_usage_id = c(
      NA, NA, NA, "127160",
      NA, "127162", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "127169"
    ),
    family = c(
      "Gadidae", "Gadidae", "Gadidae", "Gadidae",
      "Salmonidae", "Salmonidae", "Ostreidae", "Ostreidae",
      "Posidoniaceae", "Zosteraceae", "Delphinidae", "Lamnidae",
      "Laminariaceae", "Mytilidae", "Mytilidae"
    ),
    genus = c(
      "Gadus", "Gadus", "Gadus", "Gadus",
      "Salmo", "Salmo", "Crassostrea", "Crassostrea",
      "Posidonia", "Zostera", "Tursiops", "Carcharodon",
      "Laminaria", "Mytilus", "Mytilus"
    ),
    specific_epithet = c(
      "morhua", "macrocephalus", "morhua", "callarias",
      "salar", "salmo", "gigas", "gigas",
      "oceanica", "marina", "truncatus", "carcharias",
      NA, "edulis", "pellucidus"
    ),
    authorship = c(
      "Linnaeus, 1758", "Tilesius, 1810", "Linnaeus, 1758", "Linnaeus, 1758",
      "Linnaeus, 1758", NA, "(Thunberg, 1793)", "(Thunberg, 1793)",
      "(Linnaeus) Delile, 1813", "Linnaeus, 1753",
      "(Montagu, 1821)", "Linnaeus, 1758",
      "Lamouroux, 1813", "Linnaeus, 1758", NA
    ),
    infraspecific_epithet = c(
      NA, NA, "morhua", NA,
      NA, NA, NA, "gigas",
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock WoRMS backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_worms_backbone_vtr <- function() {
  df <- mock_worms_backbone_df()

  # Precompute keys
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")

  # Embed accepted taxon info
  df <- embed_accepted(df,
    id_col     = "taxon_id",
    acc_id_col = "accepted_name_usage_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus",
    status_col = "taxonomic_status"
  )

  # Sort by genus for zone-map pruning
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL

  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

# Creates a small Euro+Med-like backbone for testing.
# Euro+Med uses unified schema (canonical_name, taxon_id, etc.).
# UUID-format taxon_ids. European vascular plant taxonomy with
# accepted species, synonyms, subspecies, and genera.

mock_euromed_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "adb99dfe-7c2b-4396-a957-33e56cddd057",
      "f03c28b8-3cd7-4cdc-ac8e-67caef8839be",
      "4288da75-a895-460e-88b4-565de1ccb030",
      "57680c60-0afc-4374-8cf7-3ba5a9d46e11",
      "b1000001-0000-0000-0000-000000000001",
      "b1000002-0000-0000-0000-000000000002",
      "b1000003-0000-0000-0000-000000000003",
      "b1000004-0000-0000-0000-000000000004",
      "b1000005-0000-0000-0000-000000000005",
      "b1000006-0000-0000-0000-000000000006",
      "b1000007-0000-0000-0000-000000000007",
      "b1000008-0000-0000-0000-000000000008",
      "b1000009-0000-0000-0000-000000000009",
      "b1000010-0000-0000-0000-000000000010",
      "b1000011-0000-0000-0000-000000000011"
    ),
    canonical_name = c(
      "Quercus robur",
      "Quercus",
      "Quercus pedunculata",
      "Quercus robur subsp. robur",
      "Fagus sylvatica",
      "Fagus sylvatica subsp. sylvatica",
      "Abies alba",
      "Abies alba subsp. alba",
      "Pinus sylvestris",
      "Ranunculus acris",
      "Ranunculus acer",
      "Betula pendula",
      "Betula verrucosa",
      "Betula",
      "Ranunculus"
    ),
    taxon_rank = c(
      "SPECIES", "GENUS", "SPECIES", "SUBSPECIES",
      "SPECIES", "SUBSPECIES", "SPECIES", "SUBSPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "SPECIES", "GENUS", "GENUS"
    ),
    taxonomic_status = c(
      "ACCEPTED", "ACCEPTED", "SYNONYM", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM", "ACCEPTED",
      "SYNONYM", "ACCEPTED", "ACCEPTED"
    ),
    accepted_name_usage_id = c(
      NA, NA,
      "adb99dfe-7c2b-4396-a957-33e56cddd057",
      NA, NA, NA, NA, NA, NA, NA,
      "b1000006-0000-0000-0000-000000000006",
      NA,
      "b1000008-0000-0000-0000-000000000008",
      NA, NA
    ),
    family = c(
      "Fagaceae", "Fagaceae", "Fagaceae", "Fagaceae",
      "Fagaceae", "Fagaceae", "Pinaceae", "Pinaceae",
      "Pinaceae", "Ranunculaceae", "Ranunculaceae", "Betulaceae",
      "Betulaceae", "Betulaceae", "Ranunculaceae"
    ),
    genus = c(
      "Quercus", "Quercus", "Quercus", "Quercus",
      "Fagus", "Fagus", "Abies", "Abies",
      "Pinus", "Ranunculus", "Ranunculus", "Betula",
      "Betula", "Betula", "Ranunculus"
    ),
    specific_epithet = c(
      "robur", NA, "pedunculata", "robur",
      "sylvatica", "sylvatica", "alba", "alba",
      "sylvestris", "acris", "acer", "pendula",
      "verrucosa", NA, NA
    ),
    authorship = c(
      "L.", NA, "(Loisel.) Bonnier & Layens", NA,
      "L.", NA, "Mill.", NA,
      "L.", "L.", NA, "Roth",
      NA, "L.", "L."
    ),
    infraspecific_epithet = c(
      NA, NA, NA, "robur",
      NA, "sylvatica", NA, "alba",
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock Euro+Med backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_euromed_backbone_vtr <- function() {
  df <- mock_euromed_backbone_df()

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

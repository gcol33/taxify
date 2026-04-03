# Creates a small NCBI-like backbone for testing.
# NCBI uses unified schema (canonical_name, taxon_id, etc.).
# Synonyms are alternative name strings for the same tax_id,
# emitted as separate rows with synthetic IDs (tax_id_syn_N).

mock_ncbi_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "39395", "38942", "39395_sub1", "39395_old",
      "3349", "3349_old", "4608", "4608_sub1",
      "3700", "3701", "3764", "39396",
      "63459", "3369", "3369_syn_1"
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
      NA, NA, NA, "39395",
      NA, "3349", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "3369"
    ),
    family = c(
      "Fagaceae", "Fagaceae", "Fagaceae", "Fagaceae",
      "Pinaceae", "Pinaceae", "Poaceae", "Poaceae",
      "Salicaceae", "Salicaceae", "Rosaceae", "Fagaceae",
      "Poaceae", "Pinaceae", "Pinaceae"
    ),
    genus = c(
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
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    infraspecific_epithet = c(
      NA, NA, "robur", NA,
      NA, NA, NA, "rubra",
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock NCBI backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_ncbi_backbone_vtr <- function() {
  df <- mock_ncbi_backbone_df()

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

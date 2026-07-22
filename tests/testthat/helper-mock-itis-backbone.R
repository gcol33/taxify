# Creates a small ITIS-like backbone for testing.
#
# ITIS ships a relational SQLite dump: taxonomic_units + synonym_links +
# taxon_unit_types. taxifydb::read_itis() flattens it to the unified schema,
# resolving family, genus and kingdom by walking the parent_tsn chain, and keeps
# kingdom / kingdom_id as backbone extras. The fixture below is that flattened
# shape: numeric TSN identifiers, uppercase ranks and statuses, a resolved
# classification, and synonym rows pointing at their accepted TSN.

mock_itis_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "180542", "180543", "180544",
      "180580", "180596", "180585",
      "161996", "161997",
      "180092",
      "28727", "28728", "28749",
      "18037"
    ),
    canonical_name = c(
      "Ursus", "Ursus arctos", "Ursus horribilis",
      "Lynx", "Lynx canadensis", "Felis canadensis",
      "Salmo salar", "Salmo salar sebago",
      "Homo sapiens",
      "Acer", "Acer saccharum", "Acer saccharophorum",
      "Toxicodendron radicans"
    ),
    taxon_rank = c(
      "GENUS", "SPECIES", "SPECIES",
      "GENUS", "SPECIES", "SPECIES",
      "SPECIES", "SUBSPECIES",
      "SPECIES",
      "GENUS", "SPECIES", "SPECIES",
      "SPECIES"
    ),
    taxonomic_status = c(
      "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "ACCEPTED",
      "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED"
    ),
    accepted_name_usage_id = c(
      NA, NA, "180543",
      NA, NA, "180596",
      NA, NA,
      NA,
      NA, NA, "28728",
      NA
    ),
    family = c(
      "Ursidae", "Ursidae", "Ursidae",
      "Felidae", "Felidae", "Felidae",
      "Salmonidae", "Salmonidae",
      "Hominidae",
      "Sapindaceae", "Sapindaceae", "Sapindaceae",
      "Anacardiaceae"
    ),
    genus = c(
      "Ursus", "Ursus", "Ursus",
      "Lynx", "Lynx", "Felis",
      "Salmo", "Salmo",
      "Homo",
      "Acer", "Acer", "Acer",
      "Toxicodendron"
    ),
    specific_epithet = c(
      NA, "arctos", "horribilis",
      NA, "canadensis", "canadensis",
      "salar", "salar",
      "sapiens",
      NA, "saccharum", "saccharophorum",
      "radicans"
    ),
    authorship = c(
      NA, "Linnaeus, 1758", "Ord, 1815",
      NA, "Kerr, 1792", "Kerr, 1792",
      "Linnaeus, 1758", "Girard, 1853",
      "Linnaeus, 1758",
      NA, "Marshall", "K. Koch",
      "(L.) Kuntze"
    ),
    infraspecific_epithet = c(
      NA, NA, NA,
      NA, NA, NA,
      NA, "sebago",
      NA,
      NA, NA, NA,
      NA
    ),
    kingdom = c(
      "Animalia", "Animalia", "Animalia",
      "Animalia", "Animalia", "Animalia",
      "Animalia", "Animalia",
      "Animalia",
      "Plantae", "Plantae", "Plantae",
      "Plantae"
    ),
    kingdom_id = c(
      5L, 5L, 5L,
      5L, 5L, 5L,
      5L, 5L,
      5L,
      3L, 3L, 3L,
      3L
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock ITIS backbone as a vectra .vtr file
#'
#' Runs the same precomputation the real build applies: `precompute_keys()` +
#' `embed_accepted()` + sort by genus.
#'
#' @return Path to the temporary .vtr file.
mock_itis_backbone_vtr <- function() {
  df <- mock_itis_backbone_df()

  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")

  df <- embed_accepted(df,
    id_col         = "taxon_id",
    acc_id_col     = "accepted_name_usage_id",
    name_col       = "canonical_name",
    family_col     = "family",
    genus_col      = "genus",
    status_col     = "taxonomic_status",
    authorship_col = "authorship"
  )

  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL

  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

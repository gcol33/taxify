# Creates a small COL-like backbone for testing.
# COL differences from WFO:
# - canonicalName (without authorship) for matching
# - genericName instead of genus
# - Short alphanumeric taxonIDs
# - notho column for hybrids
# - Status values stored as uppercase (normalized during download)

mock_col_backbone_df <- function() {
  data.frame(
    taxonID = c(
      "5T6MX", "5T6MY", "5T6MZ", "5T6N1",
      "5T6N2", "5T6N3", "5T6N4", "5T6N5",
      "5T6N6", "5T6N7", "5T6N8", "5T6N9",
      "5T6NA", "5T6NB", "5T6NC"
    ),
    canonicalName = c(
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
    scientificName = c(
      "Quercus robur L.",
      "Quercus petraea (Matt.) Liebl.",
      "Quercus robur subsp. robur L.",
      "Quercus pedunculata (Mattusch.) Bonnier & Layens",
      "Pinus sylvestris L.",
      "Pinus silvestris",
      "Festuca rubra L.",
      "Festuca rubra subsp. rubra L.",
      "Salix alba L.",
      "Salix fragilis L.",
      "Rosa canina L.",
      "Quercus hispanica Lam.",
      "Festulolium",
      "Abies alba Mill.",
      "Abies pectinata (Lam.) Kunze"
    ),
    taxonRank = c(
      "SPECIES", "SPECIES", "SUBSPECIES", "SPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SUBSPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "GENUS", "SPECIES", "SPECIES"
    ),
    taxonomicStatus = c(
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "SYNONYM", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM"
    ),
    acceptedNameUsageID = c(
      NA, NA, NA, "5T6MX",
      NA, "5T6N2", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "5T6NB"
    ),
    family = c(
      "Fagaceae", "Fagaceae", "Fagaceae", "Fagaceae",
      "Pinaceae", "Pinaceae", "Poaceae", "Poaceae",
      "Salicaceae", "Salicaceae", "Rosaceae", "Fagaceae",
      "Poaceae", "Pinaceae", "Pinaceae"
    ),
    genericName = c(
      "Quercus", "Quercus", "Quercus", "Quercus",
      "Pinus", "Pinus", "Festuca", "Festuca",
      "Salix", "Salix", "Rosa", "Quercus",
      "Festulolium", "Abies", "Abies"
    ),
    specificEpithet = c(
      "robur", "petraea", "robur", "pedunculata",
      "sylvestris", "silvestris", "rubra", "rubra",
      "alba", "fragilis", "canina", "hispanica",
      NA, "alba", "pectinata"
    ),
    scientificNameAuthorship = c(
      "L.", "(Matt.) Liebl.", "L.", "(Mattusch.) Bonnier & Layens",
      "L.", NA, "L.", "L.",
      "L.", "L.", "L.", "Lam.",
      NA, "Mill.", "(Lam.) Kunze"
    ),
    infraspecificEpithet = c(
      NA, NA, "robur", NA,
      NA, NA, NA, "rubra",
      NA, NA, NA, NA,
      NA, NA, NA
    ),
    notho = c(
      NA, NA, NA, NA,
      NA, NA, NA, NA,
      NA, NA, NA, "specific",
      "generic", NA, NA
    ),
    nomenclaturalCode = c(
      "ICN", "ICN", "ICN", "ICN",
      "ICN", "ICN", "ICN", "ICN",
      "ICN", "ICN", "ICN", "ICN",
      "ICN", "ICN", "ICN"
    ),
    kingdom = c(
      "Plantae", "Plantae", "Plantae", "Plantae",
      "Plantae", "Plantae", "Plantae", "Plantae",
      "Plantae", "Plantae", "Plantae", "Plantae",
      "Plantae", "Plantae", "Plantae"
    ),
    stringsAsFactors = FALSE
  )
}


#' Create a mock COL backbone as a vectra .vtr file
#'
#' Uses the same precomputation pipeline as taxify_download.taxify_col.
#'
#' @return Path to the temporary .vtr file.
mock_col_backbone_vtr <- function() {
  df <- mock_col_backbone_df()

  # Precompute keys (COL uses canonicalName + genericName)
  df <- precompute_keys(df, "canonicalName", "genericName", "specificEpithet")

  # Embed accepted taxon info
  df <- embed_accepted(df,
    id_col     = "taxonID",
    acc_id_col = "acceptedNameUsageID",
    name_col   = "canonicalName",
    family_col = "family",
    genus_col  = "genericName",
    status_col = "taxonomicStatus"
  )

  # Sort by genus for zone-map pruning
  df <- df[order(df$genericName, na.last = TRUE), ]
  rownames(df) <- NULL

  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}


#' Create a mock COL SpeciesProfile as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_col_species_profile_vtr <- function() {
  df <- data.frame(
    taxonID = c("5T6MX", "5T6N2", "5T6NB"),
    isExtinct = c("false", "false", "false"),
    isMarine = c("false", "false", "false"),
    isFreshwater = c("false", "false", "false"),
    isTerrestrial = c("true", "true", "true"),
    stringsAsFactors = FALSE
  )
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp)
  tmp
}

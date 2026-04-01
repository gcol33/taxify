# Creates a small WFO-like backbone for testing.
# Called by tests that need a mock backbone.

mock_backbone_df <- function() {
  data.frame(
    taxonID = c(
      "wfo-0000001", "wfo-0000002", "wfo-0000003", "wfo-0000004",
      "wfo-0000005", "wfo-0000006", "wfo-0000007", "wfo-0000008",
      "wfo-0000009", "wfo-0000010", "wfo-0000011", "wfo-0000012",
      "wfo-0000013", "wfo-0000014", "wfo-0000015"
    ),
    scientificName = c(
      "Quercus robur",          # accepted species
      "Quercus petraea",        # accepted species
      "Quercus robur subsp. robur", # accepted subspecies
      "Quercus pedunculata",    # synonym -> wfo-0000001
      "Pinus sylvestris",       # accepted species
      "Pinus silvestris",       # synonym (old spelling) -> wfo-0000005
      "Festuca rubra",          # accepted species
      "Festuca rubra subsp. rubra", # accepted subspecies
      "Salix alba",             # accepted species
      "Salix fragilis",         # accepted species
      "Rosa canina",            # accepted species
      "Quercus hispanica",      # accepted nothospecies
      "Festulolium",            # accepted nothogenus
      "Abies alba",             # accepted species
      "Abies pectinata"         # synonym -> wfo-0000014
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
      NA, NA, NA, "wfo-0000001",
      NA, "wfo-0000005", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "wfo-0000014"
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
    stringsAsFactors = FALSE
  )
}


#' Create a mock backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_backbone_vtr <- function() {
  df <- mock_backbone_df()
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp)
  tmp
}


#' Create a mock backbone as a vectra node (lazy)
#'
#' @return A vectra node.
mock_backbone_node <- function() {
  path <- mock_backbone_vtr()
  vectra::tbl(path)
}

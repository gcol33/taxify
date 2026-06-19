# Creates a small WFO-like backbone for testing.
# Called by tests that need a mock backbone.

mock_backbone_df <- function(with_nom_status = FALSE) {
  # Two homonym synonyms wired up at the end of the fixture so the homonym
  # test (Pinus abies in WFO) is exercised in miniature:
  #   wfo-0000018: Pinus abies (Thunb.)  Valid       -> wfo-0000019 Picea polita
  #   wfo-0000019: Picea polita (Accepted)
  #   wfo-0000020: Pinus abies (L.)      Valid       -> wfo-0000005 Pinus sylvestris  ← reuses Pinus sylvestris as a stand-in target
  #   wfo-0000021: Pinus abies (Lour.)   Illegitimate -> wfo-0000022 Cunninghamia lanceolata
  #   wfo-0000022: Cunninghamia lanceolata (Accepted)
  df <- data.frame(
    taxon_id = c(
      "wfo-0000001", "wfo-0000002", "wfo-0000003", "wfo-0000004",
      "wfo-0000005", "wfo-0000006", "wfo-0000007", "wfo-0000008",
      "wfo-0000009", "wfo-0000010", "wfo-0000011", "wfo-0000012",
      "wfo-0000013", "wfo-0000014", "wfo-0000015",
      "wfo-0000016", "wfo-0000017",
      "wfo-0000018", "wfo-0000019", "wfo-0000020", "wfo-0000021",
      "wfo-0000022"
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
      "Abies pectinata",
      "Quercus",
      "Pinus",
      # Homonym block:
      "Pinus abies",       # 18 - Thunb. -> Picea polita
      "Picea polita",      # 19 - Accepted
      "Pinus abies",       # 20 - L. -> Pinus sylvestris (stand-in target)
      "Pinus abies",       # 21 - Lour. (illegitimate) -> Cunninghamia
      "Cunninghamia lanceolata" # 22 - Accepted
    ),
    taxon_rank = c(
      "SPECIES", "SPECIES", "SUBSPECIES", "SPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SUBSPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "GENUS", "SPECIES", "SPECIES",
      "GENUS", "GENUS",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "SPECIES"
    ),
    taxonomic_status = c(
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "SYNONYM", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "ACCEPTED", "ACCEPTED",
      "ACCEPTED", "ACCEPTED", "SYNONYM",
      "ACCEPTED", "ACCEPTED",
      "SYNONYM", "ACCEPTED", "SYNONYM", "SYNONYM",
      "ACCEPTED"
    ),
    accepted_name_usage_id = c(
      NA, NA, NA, "wfo-0000001",
      NA, "wfo-0000005", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "wfo-0000014",
      NA, NA,
      "wfo-0000019", NA, "wfo-0000005", "wfo-0000022",
      NA
    ),
    family = c(
      "Fagaceae", "Fagaceae", "Fagaceae", "Fagaceae",
      "Pinaceae", "Pinaceae", "Poaceae", "Poaceae",
      "Salicaceae", "Salicaceae", "Rosaceae", "Fagaceae",
      "Poaceae", "Pinaceae", "Pinaceae",
      "Fagaceae", "Pinaceae",
      "Pinaceae", "Pinaceae", "Pinaceae", "Pinaceae",
      "Cupressaceae"
    ),
    genus = c(
      "Quercus", "Quercus", "Quercus", "Quercus",
      "Pinus", "Pinus", "Festuca", "Festuca",
      "Salix", "Salix", "Rosa", "Quercus",
      "Festulolium", "Abies", "Abies",
      "Quercus", "Pinus",
      "Pinus", "Picea", "Pinus", "Pinus",
      "Cunninghamia"
    ),
    specific_epithet = c(
      "robur", "petraea", "robur", "pedunculata",
      "sylvestris", "silvestris", "rubra", "rubra",
      "alba", "fragilis", "canina", "hispanica",
      NA, "alba", "pectinata",
      NA, NA,
      "abies", "polita", "abies", "abies",
      "lanceolata"
    ),
    authorship = c(
      "L.", "(Matt.) Liebl.", "L.", "(Mattusch.) Bonnier & Layens",
      "L.", NA, "L.", "L.",
      "L.", "L.", "L.", "Lam.",
      NA, "Mill.", "(Lam.) Kunze",
      "L.", "L.",
      "Thunb.", "(Siebold & Zucc.) Carriere", "L.", "Lour.",
      "Lamb."
    ),
    infraspecific_epithet = c(
      NA, NA, "robur", NA,
      NA, NA, NA, "rubra",
      NA, NA, NA, NA,
      NA, NA, NA,
      NA, NA,
      NA, NA, NA, NA,
      NA
    ),
    stringsAsFactors = FALSE
  )
  if (with_nom_status) {
    # WFO uses literal "Valid" / "Illegitimate". Mark our homonym block
    # accordingly; everything else gets blank.
    df$nomenclaturalStatus <- c(
      rep("", 17L),
      "Valid",        # 18 - Pinus abies (Thunb.)
      "",             # 19 - Picea polita
      "Valid",        # 20 - Pinus abies (L.)
      "Illegitimate", # 21 - Pinus abies (Lour.)
      ""              # 22 - Cunninghamia
    )
  }
  df
}


#' Create a mock backbone as a vectra .vtr file
#'
#' Uses the same precomputation pipeline as the real download functions:
#' `precompute_keys()` + `embed_accepted()` + sort by genus + index.
#'
#' @param with_nom_status Logical. When `TRUE`, include the WFO
#'   `nomenclaturalStatus` column on the synthetic backbone so homonym
#'   disambiguation tests can exercise the Valid-filter path.
#' @return Path to the temporary .vtr file.
mock_backbone_vtr <- function(with_nom_status = FALSE) {
  df <- mock_backbone_df(with_nom_status = with_nom_status)

  # Precompute keys against the unified-schema names
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")

  # Embed accepted taxon info (synonym self-join)
  df <- embed_accepted(df,
    id_col         = "taxon_id",
    acc_id_col     = "accepted_name_usage_id",
    name_col       = "canonical_name",
    family_col     = "family",
    genus_col      = "genus",
    status_col     = "taxonomic_status",
    authorship_col = "authorship"
  )

  # Sort by genus for zone-map pruning
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL

  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}


#' Create a mock backbone as a vectra node (lazy)
#'
#' @param with_nom_status Logical. See [mock_backbone_vtr()].
#' @return A vectra node.
mock_backbone_node <- function(with_nom_status = FALSE) {
  path <- mock_backbone_vtr(with_nom_status = with_nom_status)
  vectra::tbl(path)
}

# Creates a small Species Fungorum Plus-like backbone for testing.
# Uses unified schema (canonical_name, taxon_id, etc.).
# Fungal taxonomy with denormalized classification from ChecklistBank.

mock_fungorum_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "100001", "100002", "100003", "100003_syn_1",
      "100004", "100004_syn_1", "100005", "100006",
      "100007", "100008", "100009", "100010",
      "100011", "100012", "100012_syn_1"
    ),
    canonical_name = c(
      "Amanita muscaria",
      "Amanita phalloides",
      "Boletus edulis",
      "Boletus bulbosus",
      "Cantharellus cibarius",
      "Cantharellus pallens",
      "Morchella esculenta",
      "Tuber melanosporum",
      "Saccharomyces cerevisiae",
      "Penicillium chrysogenum",
      "Aspergillus niger",
      "Russula emetica",
      "Agaricus",
      "Lactarius deliciosus",
      "Lactarius salmonicolor"
    ),
    taxon_rank = c(
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
      "SPECIES", "SPECIES", "SPECIES", "SPECIES",
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
      NA, NA, NA, "100003",
      NA, "100004", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "100012"
    ),
    family = c(
      "Amanitaceae", "Amanitaceae", "Boletaceae", "Boletaceae",
      "Cantharellaceae", "Cantharellaceae", "Morchellaceae", "Tuberaceae",
      "Saccharomycetaceae", "Trichocomaceae", "Trichocomaceae", "Russulaceae",
      "Agaricaceae", "Russulaceae", "Russulaceae"
    ),
    genus = c(
      "Amanita", "Amanita", "Boletus", "Boletus",
      "Cantharellus", "Cantharellus", "Morchella", "Tuber",
      "Saccharomyces", "Penicillium", "Aspergillus", "Russula",
      "Agaricus", "Lactarius", "Lactarius"
    ),
    specific_epithet = c(
      "muscaria", "phalloides", "edulis", "bulbosus",
      "cibarius", "pallens", "esculenta", "melanosporum",
      "cerevisiae", "chrysogenum", "niger", "emetica",
      NA, "deliciosus", "salmonicolor"
    ),
    authorship = c(
      "(L.) Lam.", "(Vaill. ex Fr.) Link", "Bull.", "Fr.",
      "Fr.", "Pilat", "(L.) Pers.", "Vittad.",
      "(Desm.) Meyen", "Thom", "Tiegh.", "(Schaeff.) Pers.",
      "L.", "(L.) Gray", "R. Heim & Leclair"
    ),
    infraspecific_epithet = rep(NA_character_, 15L),
    stringsAsFactors = FALSE
  )
}


#' Create a mock fungorum backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_fungorum_backbone_vtr <- function() {
  df <- mock_fungorum_backbone_df()

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

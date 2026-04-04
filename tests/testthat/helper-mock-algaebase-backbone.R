# Creates a small AlgaeBase-like backbone for testing.
# Uses unified schema (canonical_name, taxon_id, etc.).
# Algal taxonomy — hierarchy walk resolves family/genus from
# parentNameUsageID since AlgaeBase has no denormalized classification.

mock_algaebase_backbone_df <- function() {
  data.frame(
    taxon_id = c(
      "200001", "200002", "200003", "200003_syn_1",
      "200004", "200004_syn_1", "200005", "200006",
      "200007", "200008", "200009", "200010",
      "200011", "200012", "200012_syn_1"
    ),
    canonical_name = c(
      "Chlorella vulgaris",
      "Chlamydomonas reinhardtii",
      "Ulva lactuca",
      "Ulva latissima",
      "Fucus vesiculosus",
      "Fucus inflatus",
      "Sargassum muticum",
      "Gracilaria gracilis",
      "Spirulina platensis",
      "Dunaliella salina",
      "Caulerpa taxifolia",
      "Macrocystis pyrifera",
      "Codium",
      "Porphyra umbilicalis",
      "Porphyra laciniata"
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
      NA, NA, NA, "200003",
      NA, "200004", NA, NA,
      NA, NA, NA, NA,
      NA, NA, "200012"
    ),
    family = c(
      "Chlorellaceae", "Chlamydomonadaceae", "Ulvaceae", "Ulvaceae",
      "Fucaceae", "Fucaceae", "Sargassaceae", "Gracilariaceae",
      "Spirulinaceae", "Dunaliellaceae", "Caulerpaceae", "Laminariaceae",
      "Codiaceae", "Bangiaceae", "Bangiaceae"
    ),
    genus = c(
      "Chlorella", "Chlamydomonas", "Ulva", "Ulva",
      "Fucus", "Fucus", "Sargassum", "Gracilaria",
      "Spirulina", "Dunaliella", "Caulerpa", "Macrocystis",
      "Codium", "Porphyra", "Porphyra"
    ),
    specific_epithet = c(
      "vulgaris", "reinhardtii", "lactuca", "latissima",
      "vesiculosus", "inflatus", "muticum", "gracilis",
      "platensis", "salina", "taxifolia", "pyrifera",
      NA, "umbilicalis", "laciniata"
    ),
    authorship = c(
      "Beyerinck", "P.A. Dangeard", "Linnaeus", "Linnaeus",
      "Linnaeus", "Linnaeus", "(Yendo) Fensholt", "(Stackhouse) Steentoft",
      "Gomont", "(Dunal) Teodoresco", "(M.Vahl) C.Agardh", "(Linnaeus) C.Agardh",
      "Stackhouse", "(Linnaeus) Kutzing", "(Lightfoot) C.Agardh"
    ),
    infraspecific_epithet = rep(NA_character_, 15L),
    stringsAsFactors = FALSE
  )
}


#' Create a mock AlgaeBase backbone as a vectra .vtr file
#'
#' @return Path to the temporary .vtr file.
mock_algaebase_backbone_vtr <- function() {
  df <- mock_algaebase_backbone_df()

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

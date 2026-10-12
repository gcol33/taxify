# A small EuroVegChecklist-shaped syntaxon backbone for testing: three classes
# with one order and a few alliances each, and synonyms written the way
# FloraVeg.EU lists them. The accepted names, authors and codes are the EVC's;
# the second "Cynosurion" record (Br.-Bl. 1950, filed under the Arrhenatherion)
# is a fixture-only homonym that gives the authorship tiebreak something to
# separate.

mock_evc_backbone_df <- function() {
  acc <- data.frame(
    taxon_id = c("CM", "CM01", "CM01A", "CM01C", "CA", "CA02", "CA02B", "CA02D",
                 "DA", "DA03", "DA03A", "PA", "PA01", "PA01A", "PA01B"),
    canonical_name = c(
      "Molinio-Arrhenatheretea", "Arrhenatheretalia elatioris",
      "Arrhenatherion elatioris", "Cynosurion cristati",
      "Carpino-Fagetea sylvaticae", "Fagetalia sylvaticae",
      "Fagion sylvaticae", "Carpinion betuli",
      "Festuco-Brometea", "Brachypodietalia pinnati", "Bromion erecti",
      "Phragmito-Magnocaricetea", "Phragmitetalia australis",
      "Phragmition australis", "Magnocaricion gracilis"),
    authorship = c(
      "Tx. 1937", "Tx. 1931", "Koch 1926", "Tx. 1947",
      "Jakucs ex Passarge 1968", "Pawlowski 1928", "Luquet 1926",
      "Issler 1931", "Br.-Bl. et Tx. ex Soo 1947", "Korneck 1974",
      "Koch 1926", "Klika in Klika et Novak 1941", "Koch 1926", "Koch 1926",
      "Gehu 1961"),
    taxon_rank = c("CLASS", "ORDER", "ALLIANCE", "ALLIANCE", "CLASS", "ORDER",
                   "ALLIANCE", "ALLIANCE", "CLASS", "ORDER", "ALLIANCE",
                   "CLASS", "ORDER", "ALLIANCE", "ALLIANCE"),
    taxonomic_status = "ACCEPTED",
    accepted_name_usage_id = NA_character_,
    stringsAsFactors = FALSE
  )
  syn <- data.frame(
    taxon_id = c("DA03A:mesobrom1", "DA03A:mesobrom2", "CM01A:arrhen1",
                 "CA02B:asperul1", "CA02B:eufagion", "PA01A:phragcom",
                 "PA01B:caricgra", "CM01C:cynos1", "CM01A:cynos2"),
    canonical_name = c("Mesobromion erecti", "Mesobromion", "Arrhenatherion",
                       "Asperulo-Fagion", "Eu-Fagion", "Phragmition communis",
                       "Caricion gracilis", "Cynosurion", "Cynosurion"),
    authorship = c("(Br.-Bl. et Moor 1938) Zoller 1954", "Oberd. 1949",
                   "Br.-Bl. 1931", "Tx. 1955", "Klika in Klika et Novak 1941",
                   "Koch 1926", "Neuhausl 1959", "Tx. 1947", "Br.-Bl. 1950"),
    taxon_rank = "ALLIANCE",
    taxonomic_status = "SYNONYM",
    accepted_name_usage_id = c("DA03A", "DA03A", "CM01A", "CA02B", "CA02B",
                               "PA01A", "PA01B", "CM01C", "CM01A"),
    stringsAsFactors = FALSE
  )
  df <- rbind(acc, syn)
  unit <- ifelse(is.na(df$accepted_name_usage_id), df$taxon_id,
                 df$accepted_name_usage_id)
  name_of <- stats::setNames(acc$canonical_name, acc$taxon_id)
  df$class <- unname(name_of[substr(unit, 1L, 2L)])
  df$order <- ifelse(nchar(unit) >= 4L, unname(name_of[substr(unit, 1L, 4L)]),
                     NA_character_)
  df$alliance <- ifelse(nchar(unit) == 5L, unname(name_of[unit]),
                        NA_character_)
  df$association <- NA_character_
  df
}


#' Build the mock EVC backbone as a .vtr through the syntaxon build path
mock_evc_backbone_vtr <- function() {
  df <- precompute_keys(mock_evc_backbone_df(), "canonical_name",
                        code = "syntaxon")
  df <- embed_accepted(df,
    id_col         = "taxon_id",
    acc_id_col     = "accepted_name_usage_id",
    name_col       = "canonical_name",
    status_col     = "taxonomic_status",
    authorship_col = "authorship"
  )
  df <- df[order(df$block_key), ]
  rownames(df) <- NULL
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}


#' Point the session's "evc" backbone at the mock for the calling test
local_mock_evc <- function(env = parent.frame()) {
  set_backbone_path("evc", mock_evc_backbone_vtr())
  .taxify_env[[".version_checked.evc"]] <- TRUE
  withr::defer(set_backbone_path("evc", NULL), envir = env)
}

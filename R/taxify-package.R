#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||%
NULL

# Suppress R CMD check NOTEs for vectra NSE column references
utils::globalVariables(c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus",
  "acceptedNameUsageID", "family", "genus", "specificEpithet",
  "scientificNameAuthorship", "dist", "join_key",
  "scientificNameID", "parentNameUsageID", "namePublishedIn",
  "higherClassification", "taxonRemarks", "infraspecificEpithet",
  # COL-specific column references
  "canonicalName", "genericName",
  # GBIF-specific column references
  "id", "canonical_name", "genus_or_above", "specific_epithet",
  "is_synonym_flag", "accepted_id", "status", "authorship",
  "notho_type", "nom_status", "bracket_authorship", "bracket_year",
  "name_published_in", "origin", "infra_specific_epithet",
  # vectra string distance functions (used in NSE mutate expressions)
  "dl_dist_norm", "levenshtein_norm", "jaro_winkler"
))

# Package-level backbone cache environment (paths to .vtr files)
.taxify_cache <- NULL

# Package-level session state (manifest cache, version-check flags)
.taxify_env <- NULL

.onLoad <- function(libname, pkgname) {
  .taxify_cache <<- new.env(parent = emptyenv())
  .taxify_env   <<- new.env(parent = emptyenv())
}

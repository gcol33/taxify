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
  "higherClassification", "taxonRemarks", "infraspecificEpithet"
))

# Package-level backbone cache environment
.taxify_cache <- NULL

.onLoad <- function(libname, pkgname) {
  .taxify_cache <<- new.env(parent = emptyenv())
}

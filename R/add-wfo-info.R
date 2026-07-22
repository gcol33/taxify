#' Add WFO-specific columns
#'
#' Joins extra World Flora Online columns to a [taxify()] result by
#' looking up `taxon_id` in the WFO backbone.
#'
#' @param x A data.frame returned by [taxify()] with `backend == "wfo"`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{scientificNameID}{WFO scientificNameID.}
#'   \item{parentNameUsageID}{WFO parentNameUsageID.}
#'   \item{namePublishedIn}{Publication reference.}
#'   \item{higherClassification}{Higher classification string.}
#'   \item{taxonRemarks}{Taxonomic remarks.}
#'   \item{infraspecificEpithet}{Infraspecific epithet (for subspecies,
#'     varieties, forms).}
#' }
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur") |>
#'   add_wfo_info()
#'
#' options(old)
#'
#' @export
add_wfo_info <- function(x) {
  # Output column (user-facing, camelCase) -> source column in the .vtr.
  # taxon_id is the unified-schema join key; infraspecific_epithet is the
  # unified main-schema name renamed to infraspecificEpithet for stable output.
  col_map <- c(
    scientificNameID     = "scientificNameID",
    parentNameUsageID    = "parentNameUsageID",
    namePublishedIn      = "namePublishedIn",
    higherClassification = "higherClassification",
    taxonRemarks         = "taxonRemarks",
    infraspecificEpithet = "infraspecific_epithet"
  )
  enrich_from_backbone(
    x, wfo_backend(), col_map,
    enrichment_name = "wfo_info", label = "WFO",
    probe_cols = c("scientificNameID", "namePublishedIn",
                   "higherClassification")
  )
}

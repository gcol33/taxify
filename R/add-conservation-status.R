#' Add conservation status
#'
#' Joins IUCN Red List conservation status to a [taxify()] result by
#' looking up `accepted_name` in the conservation status enrichment.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Show download progress if enrichment data needs
#'   to be fetched. Default `TRUE`.
#' @return The same data.frame with an additional column:
#' \describe{
#'   \item{conservation_status}{IUCN category: `"LC"` (Least Concern),
#'     `"NT"` (Near Threatened), `"VU"` (Vulnerable), `"EN"` (Endangered),
#'     `"CR"` (Critically Endangered), `"EW"` (Extinct in the Wild),
#'     `"EX"` (Extinct), or `NA` if not assessed.}
#' }
#'
#' @details
#' Conservation status values are compiled from publicly available sources
#' including GBIF and the IUCN Red List API. Coverage is global across all
#' taxonomic groups (~166k species).
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Panthera tigris", backend = "gbif") |>
#'   add_conservation_status()
#'
#' options(old)
#'
#' @export
add_conservation_status <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "conservation_status",
    col_map         = c(conservation_status = "conservation_status"),
    source_label    = "IUCN Red List",
    verbose         = verbose
  )
}

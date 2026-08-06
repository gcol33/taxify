#' Add Collembola body length (BETSI export)
#'
#' Joins per-species springtail body length to a [taxify()] result by looking up
#' `accepted_name`. The value is the median over the BETSI compilation's
#' per-source measurements, with the observed range and the measurement and
#' source counts behind it.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{betsi_body_length_mm}{Body length (mm), median of the per-source
#'     measurements.}
#'   \item{betsi_body_length_min_mm}{Smallest measurement (mm).}
#'   \item{betsi_body_length_max_mm}{Largest measurement (mm).}
#'   \item{betsi_body_length_n}{Number of measurements aggregated.}
#'   \item{betsi_body_length_sources}{Number of distinct literature sources.}
#' }
#'
#' @details
#' Source: body length values from the BETSI database (Biological and Ecological
#' Traits of Soil Invertebrates), the 2017 all-Collembola export requested by
#' Bonfanti (2018), CC BY-NC 4.0. Coverage: 1,374 species. The European-compendia
#' body-length floor: it agrees with the Ellers et al. body size at Pearson
#' r = 0.96 over 262 shared species and with the Plazi treatment values at
#' r = 0.906. Body length is also available through
#' [add_trait()]`("body_length")`, which coalesces it with the Plazi, monograph
#' and other springtail sources.
#'
#' @references
#' Bonfanti J (2018) Body length trait values from the BETSI database, on all
#' Collembola species. Zenodo. \doi{10.5281/zenodo.1292461}
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_betsi_collembola_body_length()
#' }
#'
#' @export
add_betsi_collembola_body_length <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("betsi_body_length_mm", "betsi_body_length_min_mm",
                "betsi_body_length_max_mm", "betsi_body_length_n",
                "betsi_body_length_sources")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "betsi_collembola_body_length",
    col_map         = col_map,
    source_label    = "BETSI Collembola body length (Bonfanti 2018)",
    cols            = cols,
    verbose         = verbose
  )
}

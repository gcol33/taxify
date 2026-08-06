#' Add Collembola traits (Ellers et al. 2018)
#'
#' Joins European springtail functional traits to a [taxify()] result by looking
#' up `accepted_name`: vertical stratification, body size, reproduction mode and
#' climatic preferences.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{ellers_vertical_distribution}{Vertical stratification (soil depth
#'     class).}
#'   \item{ellers_body_size_mm}{Body size (mm).}
#'   \item{ellers_reproduction}{Reproduction mode (sexual or asexual).}
#'   \item{ellers_moisture_pref}{Moisture preference.}
#'   \item{ellers_temperature_pref}{Temperature preference.}
#'   \item{ellers_thermal_niche_breadth}{Thermal niche breadth.}
#' }
#'
#' @details
#' Source: Collembola trait table from Ellers et al. (2018), Dryad, CC0.
#' Coverage: 278 European Collembola species; taxonomy follows the Checklist of
#' the Collembola of the World. The openly licensed analogue of the BETSI
#' multi-trait matrices; its body size agrees with the BETSI body-length floor at
#' Pearson r = 0.96 over 262 shared species. The body size is also available
#' through [add_trait()]`("body_length")`.
#'
#' @references
#' Ellers J, Berg MP, Dias ATC, Fontana S, Ooms A, Moretti M (2018) Diversity in
#' form and function: vertical distribution of soil fauna mediates
#' multidimensional trait variation. Journal of Animal Ecology 87:933-944.
#' \doi{10.1111/1365-2656.12838}
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_ellers_collembola()
#' }
#'
#' @export
add_ellers_collembola <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("ellers_vertical_distribution", "ellers_body_size_mm",
                "ellers_reproduction", "ellers_moisture_pref",
                "ellers_temperature_pref", "ellers_thermal_niche_breadth")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "ellers_collembola",
    col_map         = col_map,
    source_label    = "Collembola traits (Ellers et al. 2018)",
    cols            = cols,
    verbose         = verbose
  )
}

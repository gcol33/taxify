#' Add amphibian heat tolerance (Pottier)
#'
#' Joins amphibian upper thermal-limit and body-size summaries to a [taxify()]
#' result by `accepted_name`. Per-measurement records are reduced to species
#' medians; heat tolerance pools across metrics and acclimation conditions, so it
#' is an approximate species-level upper thermal limit.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric columns
#'   `pottier_heat_tolerance_c`, `pottier_acclimation_temp_c`,
#'   `pottier_svl_mm`, `pottier_body_mass_g`.
#'
#' @details Source: Pottier et al. (2022) amphibian heat tolerance database
#'   (Scientific Data, CC-BY 4.0).
#'
#' @references
#' Pottier P et al. (2022) A comprehensive database of amphibian heat tolerance.
#' Scientific Data 9:600. \doi{10.1038/s41597-022-01704-9}
#'
#' @examples
#' \dontrun{
#' taxify("Rana temporaria", backend = "gbif") |>
#'   add_pottier()
#' }
#'
#' @export
add_pottier <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c("heat_tolerance_c", "acclimation_temp_c", "svl_mm", "body_mass_g")
  col_map <- stats::setNames(base_cols, paste0("pottier_", base_cols))
  enrich_simple(
    x,
    enrichment_name = "pottier",
    col_map         = col_map,
    source_label    = "Pottier amphibian heat tolerance",
    cols            = cols,
    verbose         = verbose
  )
}

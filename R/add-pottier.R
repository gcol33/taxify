#' Add amphibian heat tolerance (Pottier)
#'
#' Joins amphibian upper thermal-limit and body-size summaries to a [taxify()]
#' result by `accepted_name`. Per-measurement records are reduced to species
#' medians; heat tolerance pools across metrics and acclimation conditions, so it
#' is an approximate species-level upper thermal limit.
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Rana temporaria", backend = "gbif") |>
#'   add_pottier()
#' }
#'
#' @export
add_pottier <- function(x, verbose = TRUE) {
  cols <- c("heat_tolerance_c", "acclimation_temp_c", "svl_mm", "body_mass_g")
  col_map <- stats::setNames(cols, paste0("pottier_", cols))
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "pottier",
    col_map         = col_map,
    source_label    = "Pottier amphibian heat tolerance",
    na_types        = na_types,
    verbose         = verbose
  )
}

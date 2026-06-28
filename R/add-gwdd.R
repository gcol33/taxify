#' Add wood density (Global Wood Density Database v2)
#'
#' Joins species-level wood density to a [taxify()] result by looking up
#' `accepted_name`. Wood density is reported as wood specific gravity (oven-dry
#' mass / green volume), dimensionless and numerically equal to g/cm3.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{gwdd_wood_density_g_cm3}{Species-mean wood density (g/cm3).}
#'   \item{gwdd_wood_density_trunk_g_cm3}{Trunk wood density (g/cm3).}
#'   \item{gwdd_wood_density_branch_g_cm3}{Branch wood density (g/cm3).}
#'   \item{gwdd_n_measurements}{Number of underlying measurements.}
#' }
#'
#' @details
#' Source: Global Wood Density Database v2 (Fischer et al. 2026, New Phytologist,
#' CC BY 4.0). Coverage: ~17.3k species. Bark density is not part of the
#' aggregated source and is not included.
#'
#' @references
#' Fischer FJ et al. (2026) The Global Wood Density Database version 2. New
#' Phytologist. \doi{10.1111/nph.70860}
#'
#' @examples
#' \donttest{
#' taxify("Quercus robur", backend = "gbif") |>
#'   add_gwdd()
#' }
#'
#' @export
add_gwdd <- function(x, verbose = TRUE) {
  col_map <- c(
    gwdd_wood_density_g_cm3        = "wood_density_g_cm3",
    gwdd_wood_density_trunk_g_cm3  = "wood_density_trunk_g_cm3",
    gwdd_wood_density_branch_g_cm3 = "wood_density_branch_g_cm3",
    gwdd_n_measurements            = "n_measurements"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "gwdd",
    col_map         = col_map,
    source_label    = "Global Wood Density Database v2",
    na_types        = na_types,
    verbose         = verbose
  )
}

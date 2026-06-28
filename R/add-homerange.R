#' Add mammal home-range size (HomeRange)
#'
#' Joins species-median home-range size and body mass to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric `homerange_home_range_km2` and
#'   `homerange_body_mass_kg`.
#'
#' @details Source: Broekman et al. (2023) HomeRange database (Dryad, CC0).
#'   Per-individual records are reduced to species medians.
#'
#' @references
#' Broekman MJE et al. (2023) HomeRange: a global database of mammalian home
#' ranges. Dryad. \doi{10.5061/dryad.d2547d85x}
#'
#' @examples
#' \donttest{
#' taxify("Panthera leo", backend = "gbif") |>
#'   add_homerange()
#' }
#'
#' @export
add_homerange <- function(x, verbose = TRUE) {
  col_map <- c(homerange_home_range_km2 = "home_range_km2",
               homerange_body_mass_kg   = "body_mass_kg")
  na_types <- stats::setNames(rep(list(NA_real_), 2), names(col_map))
  enrich_simple(
    x,
    enrichment_name = "homerange",
    col_map         = col_map,
    source_label    = "HomeRange",
    na_types        = na_types,
    verbose         = verbose
  )
}

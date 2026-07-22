#' Add mammal home-range size (HomeRange)
#'
#' Joins species-median home-range size and body mass to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
#' \dontrun{
#' taxify("Panthera leo", backbone = "gbif") |>
#'   add_homerange()
#' }
#'
#' @export
add_homerange <- function(x, cols = NULL, verbose = TRUE) {
  col_map <- c(homerange_home_range_km2 = "home_range_km2",
               homerange_body_mass_kg   = "body_mass_kg")
  enrich_simple(
    x,
    enrichment_name = "homerange",
    col_map         = col_map,
    source_label    = "HomeRange",
    cols            = cols,
    verbose         = verbose
  )
}

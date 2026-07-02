#' Add population density (TetraDENSITY)
#'
#' Joins species-median terrestrial-vertebrate population density to a [taxify()]
#' result by `accepted_name`. Only `ind/km2` records are used.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric `tetradensity_density_ind_km2`.
#'
#' @details Source: Santini et al. TetraDENSITY (figshare, CC-BY 4.0). Records
#'   in other density units are excluded to avoid mixing.
#'
#' @references
#' Santini L et al. TetraDENSITY: a database of population density estimates in
#' terrestrial vertebrates. figshare. \doi{10.6084/m9.figshare.5371633}
#'
#' @examples
#' \donttest{
#' taxify("Capreolus capreolus", backend = "gbif") |>
#'   add_tetradensity()
#' }
#'
#' @export
add_tetradensity <- function(x, cols = NULL, verbose = TRUE) {
  col_map <- c(tetradensity_density_ind_km2 = "density_ind_km2")
  na_types <- list(tetradensity_density_ind_km2 = NA_real_)
  enrich_simple(
    x,
    enrichment_name = "tetradensity",
    col_map         = col_map,
    source_label    = "TetraDENSITY",
    na_types        = na_types,
    cols            = cols,
    verbose         = verbose
  )
}

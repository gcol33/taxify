#' Add Arctic marine benthos traits
#'
#' Joins Arctic Traits Database functional traits to a [taxify()] result by
#' `accepted_name`. Each fuzzy-coded trait is reduced to its dominant category.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `arctic_traits_` columns:
#'   `feeding_habit`, `skeleton`, `reproduction`, `larval_development`, `size`,
#'   `living_habit`, `body_form`, `mobility`, `bioturbation`, `depth_range`,
#'   `trophic_level`, `fragility`, `sociability`, `longevity`.
#'
#' @details Source: Arctic Traits Database (Degen & Faulwetter 2019, University
#'   of Vienna PHAIDRA, CC-BY 4.0).
#'
#' @references
#' Degen R, Faulwetter S (2019) The Arctic Traits Database. University of Vienna.
#' \doi{10.25365/phaidra.49}
#'
#' @examples
#' \donttest{
#' taxify("Astarte borealis", backend = "gbif") |>
#'   add_arctic_traits()
#' }
#'
#' @export
add_arctic_traits <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c("feeding_habit", "skeleton", "reproduction", "larval_development",
            "size", "living_habit", "body_form", "mobility", "bioturbation",
            "depth_range", "trophic_level", "fragility", "sociability",
            "longevity")
  col_map <- stats::setNames(base_cols, paste0("arctic_traits_", base_cols))
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "arctic_traits",
    col_map         = col_map,
    source_label    = "Arctic Traits Database",
    na_types        = na_types,
    cols            = cols,
    verbose         = verbose
  )
}

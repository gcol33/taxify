#' Add Arctic marine benthos traits
#'
#' Joins Arctic Traits Database functional traits to a [taxify()] result by
#' `accepted_name`. Each fuzzy-coded trait is reduced to its dominant category.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `arctic_traits_` columns:
#'   `arctic_traits_feeding_habit`, `arctic_traits_skeleton`, `arctic_traits_reproduction`, `arctic_traits_larval_development`, `arctic_traits_size`,
#'   `arctic_traits_living_habit`, `arctic_traits_body_form`, `arctic_traits_mobility`, `arctic_traits_bioturbation`, `arctic_traits_depth_range`,
#'   `arctic_traits_trophic_level`, `arctic_traits_fragility`, `arctic_traits_sociability`, `arctic_traits_longevity`.
#'
#' @details Source: Arctic Traits Database (Degen & Faulwetter 2019, University
#'   of Vienna PHAIDRA, CC-BY 4.0).
#'
#' @references
#' Degen R, Faulwetter S (2019) The Arctic Traits Database. University of Vienna.
#' \doi{10.25365/phaidra.49}
#'
#' @examples
#' \dontrun{
#' taxify("Astarte borealis", backbone = "gbif") |>
#'   add_arctic_traits()
#' }
#'
#' @export
add_arctic_traits <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_arctic_traits, cols = cols, verbose = verbose)
}


.door_arctic_traits <- list(
  enrichment_name = "arctic_traits",
  col_map = c(
    arctic_traits_feeding_habit = "feeding_habit",
    arctic_traits_skeleton = "skeleton",
    arctic_traits_reproduction = "reproduction",
    arctic_traits_larval_development = "larval_development",
    arctic_traits_size = "size",
    arctic_traits_living_habit = "living_habit",
    arctic_traits_body_form = "body_form",
    arctic_traits_mobility = "mobility",
    arctic_traits_bioturbation = "bioturbation",
    arctic_traits_depth_range = "depth_range",
    arctic_traits_trophic_level = "trophic_level",
    arctic_traits_fragility = "fragility",
    arctic_traits_sociability = "sociability",
    arctic_traits_longevity = "longevity"
  ),
  source_label = "Arctic Traits Database"
)

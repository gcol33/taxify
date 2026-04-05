#' Add cross-taxon body mass and metabolic rate (AnimalTraits)
#'
#' Joins AnimalTraits body mass and metabolic rate data to a [taxify()]
#' result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{animaltraits_body_mass_kg}{Median body mass in kg.}
#'   \item{animaltraits_metabolic_rate_w}{Median metabolic rate in watts.}
#' }
#'
#' @details
#' Source: AnimalTraits (Hebert et al. 2022, CC0). Coverage: ~2k species
#' across arthropods, vertebrates, molluscs, and annelids. Individual-level
#' observations aggregated to species medians.
#'
#' @references
#' Hebert K et al. (2022) AnimalTraits -- a curated animal trait database
#' for body mass, metabolic rate and brain size. Scientific Data 9:265.
#'
#' @examples
#' \dontrun{
#' taxify("Drosophila melanogaster") |>
#'   add_animaltraits()
#' }
#'
#' @export
add_animaltraits <- function(x, verbose = TRUE) {
  col_map <- c(
    animaltraits_body_mass_kg     = "body_mass_kg",
    animaltraits_metabolic_rate_w = "metabolic_rate_w"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "animaltraits",
    col_map         = col_map,
    source_label    = "AnimalTraits",
    na_types        = na_types,
    verbose         = verbose
  )
}

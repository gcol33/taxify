#' Add European pollinator traits (EuPollTrait)
#'
#' Joins European bee and hoverfly morphological, biogeographic and ecological
#' traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `eupolltrait_` columns: numeric `eupolltrait_itd_mm`,
#'   `eupolltrait_tongue_length_mm`, `eupolltrait_species_temperature_index`,
#'   `eupolltrait_species_continentality_index`, `eupolltrait_area_of_occupancy`, `eupolltrait_extent_of_occurrence`;
#'   categorical `eupolltrait_sociality`, `eupolltrait_nest`, `eupolltrait_larval_nutrition`, `eupolltrait_body_length_category`.
#'
#' @details Source: EuPollTrait (Milicic et al. 2025, Zenodo, CC-BY 4.0).
#'
#' @references
#' Milicic M et al. (2025) EuPollTrait: a trait database for European bees and
#' hoverflies. Zenodo. \doi{10.5281/zenodo.18032357}
#'
#' @examples
#' \dontrun{
#' taxify("Bombus terrestris", backbone = "gbif") |>
#'   add_eupolltrait()
#' }
#'
#' @export
add_eupolltrait <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_eupolltrait, cols = cols, verbose = verbose)
}


.door_eupolltrait <- list(
  enrichment_name = "eupolltrait",
  col_map = c(
    eupolltrait_itd_mm = "itd_mm",
    eupolltrait_tongue_length_mm = "tongue_length_mm",
    eupolltrait_species_temperature_index = "species_temperature_index",
    eupolltrait_species_continentality_index = "species_continentality_index",
    eupolltrait_area_of_occupancy = "area_of_occupancy",
    eupolltrait_extent_of_occurrence = "extent_of_occurrence",
    eupolltrait_sociality = "sociality",
    eupolltrait_nest = "nest",
    eupolltrait_larval_nutrition = "larval_nutrition",
    eupolltrait_body_length_category = "body_length_category"
  ),
  source_label = "EuPollTrait"
)

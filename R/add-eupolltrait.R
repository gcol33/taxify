#' Add European pollinator traits (EuPollTrait)
#'
#' Joins European bee and hoverfly morphological, biogeographic and ecological
#' traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `eupolltrait_` columns: numeric `itd_mm`,
#'   `tongue_length_mm`, `species_temperature_index`,
#'   `species_continentality_index`, `area_of_occupancy`, `extent_of_occurrence`;
#'   categorical `sociality`, `nest`, `larval_nutrition`, `body_length_category`.
#'
#' @details Source: EuPollTrait (Milicic et al. 2025, Zenodo, CC-BY 4.0).
#'
#' @references
#' Milicic M et al. (2025) EuPollTrait: a trait database for European bees and
#' hoverflies. Zenodo. \doi{10.5281/zenodo.18032357}
#'
#' @examples
#' \donttest{
#' taxify("Bombus terrestris", backend = "gbif") |>
#'   add_eupolltrait()
#' }
#'
#' @export
add_eupolltrait <- function(x, verbose = TRUE) {
  num_cols <- c("itd_mm", "tongue_length_mm", "species_temperature_index",
                "species_continentality_index", "area_of_occupancy",
                "extent_of_occurrence")
  cat_cols <- c("sociality", "nest", "larval_nutrition", "body_length_category")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("eupolltrait_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("eupolltrait_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "eupolltrait",
    col_map         = col_map,
    source_label    = "EuPollTrait",
    na_types        = na_types,
    verbose         = verbose
  )
}

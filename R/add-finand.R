#' Add Helsinki urban-forest carabid traits (Finand & Kotze)
#'
#' Joins ground-beetle traits measured from Helsinki specimens to a [taxify()]
#' result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all of them, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `finand_` columns: numeric `finand_body_length_mm`;
#'   categorical `finand_wing_morph`, `finand_feeding_type`, `finand_habitat_pref`, `finand_moisture_pref`.
#'
#' @details Source: Finand & Kotze (2025), 34 species from 25 remnant urban
#'   forests in Helsinki.
#'
#'   Small, and carried for a reason no larger source can supply. Every other
#'   reachable carabid trait table traces its body sizes and wing classes back
#'   to carabids.org (Homburg et al. 2014), so agreement between them is not
#'   corroboration. These body lengths were measured from the beetles the
#'   authors caught, which makes them the one independent check: they run at a
#'   median ratio of 0.9946 against the NW European arthropod compilation over
#'   28 shared species, with only 7.1 percent exactly equal.
#'
#'   `body_length_mm` is a whole-body length despite the source column being
#'   terse about it; elytra length would sit near 0.6 of these values.
#'
#'   `wing_morph` records the morph of the beetles caught in Helsinki, so it can
#'   name a definite morph where a species-level source calls the species
#'   dimorphic. Compare [add_chowdhury()], which states the species' capacity.
#'
#' @references
#' Finand B, Kotze DJ (2025) Habitat specialisation and dispersal capacity drive
#' rapid carabid beetle responses to urban forest fragmentation. Zenodo.
#' \doi{10.5281/zenodo.17184995}
#'
#' @examples
#' \dontrun{
#' taxify(c("Carabus glabratus", "Cychrus caraboides")) |>
#'   add_finand()
#' }
#'
#' @export
add_finand <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_finand, cols = cols, verbose = verbose)
}


.door_finand <- list(
  enrichment_name = "finand",
  col_map = c(
    finand_body_length_mm = "body_length_mm",
    finand_wing_morph = "wing_morph",
    finand_feeding_type = "feeding_type",
    finand_habitat_pref = "habitat_pref",
    finand_moisture_pref = "moisture_pref"
  ),
  source_label = "Finand & Kotze Helsinki carabid traits"
)

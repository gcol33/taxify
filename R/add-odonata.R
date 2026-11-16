#' Add odonate behavioural/ecological traits (OPD)
#'
#' Joins Odonate Phenotypic Database categorical traits to a [taxify()] result by
#' `accepted_name` (modal value per species).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `odonata_territoriality`,
#'   `odonata_flight_mode`, `odonata_mate_guarding`, `odonata_habitat_openness`,
#'   `odonata_has_wing_pigment`.
#'
#' @details Source: Odonate Phenotypic Database (Waller et al., Dryad, CC-BY 4.0).
#'
#' @references
#' Waller JT et al. The Odonate Phenotypic Database. Dryad.
#' \doi{10.5061/dryad.15pm5qc}
#'
#' @examples
#' \dontrun{
#' taxify("Calopteryx splendens", backbone = "gbif") |>
#'   add_odonata()
#' }
#'
#' @export
add_odonata <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_odonata, cols = cols, verbose = verbose)
}


.door_odonata <- list(
  enrichment_name = "odonata",
  col_map = c(
    odonata_territoriality = "territoriality",
    odonata_flight_mode = "flight_mode",
    odonata_mate_guarding = "mate_guarding",
    odonata_habitat_openness = "habitat_openness",
    odonata_has_wing_pigment = "has_wing_pigment"
  ),
  source_label = "Odonate Phenotypic Database"
)

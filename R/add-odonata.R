#' Add odonate behavioural/ecological traits (OPD)
#'
#' Joins Odonate Phenotypic Database categorical traits to a [taxify()] result by
#' `accepted_name` (modal value per species).
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Calopteryx splendens", backend = "gbif") |>
#'   add_odonata()
#' }
#'
#' @export
add_odonata <- function(x, verbose = TRUE) {
  cols <- c("territoriality", "flight_mode", "mate_guarding",
            "habitat_openness", "has_wing_pigment")
  col_map <- stats::setNames(cols, paste0("odonata_", cols))
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "odonata",
    col_map         = col_map,
    source_label    = "Odonate Phenotypic Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

#' Add marine zooplankton traits
#'
#' Joins global marine-zooplankton traits to a [taxify()] result by
#' `accepted_name` (species-level summaries).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `zooplankton_` columns: numeric
#'   `zooplankton_body_length_max_mm`, `zooplankton_carbon_weight_mg`, `zooplankton_nitrogen_pdw_pct`; categorical
#'   `zooplankton_vertical_distribution`, `zooplankton_reproduction_mode`, `zooplankton_trophic_group`,
#'   `zooplankton_feeding_mode`, `zooplankton_myelination`, `zooplankton_habitat_association`,
#'   `zooplankton_diel_vertical_migration`, `zooplankton_bioluminescence`.
#'
#' @details Source: Pata & Hunt global marine zooplankton trait database
#'   (Zenodo, CC-BY-SA 4.0).
#'
#' @references
#' Pata PR, Hunt BPV (2025) A global trait database for marine zooplankton.
#' Zenodo. \doi{10.5281/zenodo.8102913}
#'
#' @examples
#' \dontrun{
#' taxify("Calanus finmarchicus", backbone = "gbif") |>
#'   add_zooplankton()
#' }
#'
#' @export
add_zooplankton <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_zooplankton, cols = cols, verbose = verbose)
}


.door_zooplankton <- list(
  enrichment_name = "zooplankton",
  col_map = c(
    zooplankton_body_length_max_mm = "body_length_max_mm",
    zooplankton_carbon_weight_mg = "carbon_weight_mg",
    zooplankton_nitrogen_pdw_pct = "nitrogen_pdw_pct",
    zooplankton_vertical_distribution = "vertical_distribution",
    zooplankton_reproduction_mode = "reproduction_mode",
    zooplankton_trophic_group = "trophic_group",
    zooplankton_feeding_mode = "feeding_mode",
    zooplankton_myelination = "myelination",
    zooplankton_habitat_association = "habitat_association",
    zooplankton_diel_vertical_migration = "diel_vertical_migration",
    zooplankton_bioluminescence = "bioluminescence"
  ),
  source_label = "Global Zooplankton Trait Database"
)

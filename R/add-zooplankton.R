#' Add marine zooplankton traits
#'
#' Joins global marine-zooplankton traits to a [taxify()] result by
#' `accepted_name` (species-level summaries).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `zooplankton_` columns: numeric
#'   `body_length_max_mm`, `carbon_weight_mg`, `nitrogen_pdw_pct`; categorical
#'   `vertical_distribution`, `reproduction_mode`, `trophic_group`,
#'   `feeding_mode`, `myelination`, `habitat_association`,
#'   `diel_vertical_migration`, `bioluminescence`.
#'
#' @details Source: Pata & Hunt global marine zooplankton trait database
#'   (Zenodo, CC-BY-SA 4.0).
#'
#' @references
#' Pata PR, Hunt BPV (2025) A global trait database for marine zooplankton.
#' Zenodo. \doi{10.5281/zenodo.8102913}
#'
#' @examples
#' \donttest{
#' taxify("Calanus finmarchicus", backend = "gbif") |>
#'   add_zooplankton()
#' }
#'
#' @export
add_zooplankton <- function(x, verbose = TRUE) {
  num_cols <- c("body_length_max_mm", "carbon_weight_mg", "nitrogen_pdw_pct")
  cat_cols <- c("vertical_distribution", "reproduction_mode", "trophic_group",
                "feeding_mode", "myelination", "habitat_association",
                "diel_vertical_migration", "bioluminescence")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("zooplankton_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("zooplankton_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "zooplankton",
    col_map         = col_map,
    source_label    = "Global Zooplankton Trait Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

#' Add NZ marine benthos traits (NZTD)
#'
#' Joins New Zealand marine benthic-invertebrate functional traits to a
#' [taxify()] result by `accepted_name`. Each fuzzy-coded trait is reduced to its
#' dominant modality.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `nztd_` columns: `nztd_bioturbation`,
#'   `nztd_body_size`, `nztd_degree_of_attachment`, `nztd_feeding_mode`, `nztd_living_habit`,
#'   `nztd_mobility`, `nztd_morphology`, `nztd_movement_method`, `nztd_rigidity`.
#'
#' @details Source: NZTD (Lam-Gordillo et al. 2023, figshare, CC-BY 4.0).
#'
#' @references
#' Lam-Gordillo O et al. (2023) New Zealand Trait Database (NZTD) for marine
#' benthic invertebrates. figshare. \doi{10.6084/m9.figshare.21939647}
#'
#' @examples
#' \dontrun{
#' taxify("Macomona liliana", backbone = "gbif") |>
#'   add_nztd()
#' }
#'
#' @export
add_nztd <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_nztd, cols = cols, verbose = verbose)
}


.door_nztd <- list(
  enrichment_name = "nztd",
  col_map = c(
    nztd_bioturbation = "bioturbation",
    nztd_body_size = "body_size",
    nztd_degree_of_attachment = "degree_of_attachment",
    nztd_feeding_mode = "feeding_mode",
    nztd_living_habit = "living_habit",
    nztd_mobility = "mobility",
    nztd_morphology = "morphology",
    nztd_movement_method = "movement_method",
    nztd_rigidity = "rigidity"
  ),
  source_label = "NZTD"
)

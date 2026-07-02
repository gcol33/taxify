#' Add NZ marine benthos traits (NZTD)
#'
#' Joins New Zealand marine benthic-invertebrate functional traits to a
#' [taxify()] result by `accepted_name`. Each fuzzy-coded trait is reduced to its
#' dominant modality.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `nztd_` columns: `bioturbation`,
#'   `body_size`, `degree_of_attachment`, `feeding_mode`, `living_habit`,
#'   `mobility`, `morphology`, `movement_method`, `rigidity`.
#'
#' @details Source: NZTD (Lam-Gordillo et al. 2023, figshare, CC-BY 4.0).
#'
#' @references
#' Lam-Gordillo O et al. (2023) New Zealand Trait Database (NZTD) for marine
#' benthic invertebrates. figshare. \doi{10.6084/m9.figshare.21939647}
#'
#' @examples
#' \donttest{
#' taxify("Macomona liliana", backend = "gbif") |>
#'   add_nztd()
#' }
#'
#' @export
add_nztd <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c("bioturbation", "body_size", "degree_of_attachment", "feeding_mode",
            "living_habit", "mobility", "morphology", "movement_method",
            "rigidity")
  col_map <- stats::setNames(base_cols, paste0("nztd_", base_cols))
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "nztd",
    col_map         = col_map,
    source_label    = "NZTD",
    na_types        = na_types,
    cols            = cols,
    verbose         = verbose
  )
}

#' Add aquatic-invertebrate dispersal traits (DISPERSE)
#'
#' Joins genus-level dispersal-related traits for European aquatic
#' macroinvertebrates to a [taxify()] result by `genus`. Each fuzzy-coded trait
#' is reduced to its dominant modality (with the database's own labels).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `disperse_body_size_cm`,
#'   `disperse_life_cycle`, `disperse_repro_cycles`, `disperse_dispersal`,
#'   `disperse_adult_lifespan`, `disperse_female_wing_mm`, `disperse_wing_type`,
#'   `disperse_fecundity` (joined on genus).
#'
#' @details Source: DISPERSE (Sarremejane et al. 2020, Scientific Data, CC-BY
#'   4.0). Joins on genus because the database is genus-resolved.
#'
#' @references
#' Sarremejane R et al. (2020) DISPERSE, a trait database to assess the dispersal
#' potential of European aquatic macroinvertebrates. Scientific Data 7:386.
#' \doi{10.6084/m9.figshare.c.5000633}
#'
#' @examples
#' \donttest{
#' taxify("Baetis rhodani", backend = "gbif") |>
#'   add_disperse()
#' }
#'
#' @export
add_disperse <- function(x, verbose = TRUE) {
  cols <- c("disperse_body_size_cm", "disperse_life_cycle",
            "disperse_repro_cycles", "disperse_dispersal",
            "disperse_adult_lifespan", "disperse_female_wing_mm",
            "disperse_wing_type", "disperse_fecundity")
  col_map <- stats::setNames(cols, cols)
  na_types <- stats::setNames(rep(list(NA_character_), length(cols)), cols)
  enrich_simple(
    x,
    enrichment_name = "disperse",
    col_map         = col_map,
    source_label    = "DISPERSE",
    na_types        = na_types,
    join_col        = "genus",
    verbose         = verbose
  )
}

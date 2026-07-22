#' Add aquatic-invertebrate dispersal traits (DISPERSE)
#'
#' Joins genus-level dispersal-related traits for European aquatic
#' macroinvertebrates to a [taxify()] result by `genus`. Each fuzzy-coded trait
#' is reduced to its dominant modality (with the database's own labels).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `disperse_body_size_cm`,
#'   `disperse_life_cycle`, `disperse_repro_cycles`, `disperse_dispersal`,
#'   `disperse_adult_lifespan`, `disperse_female_wing_mm`, `disperse_wing_type`,
#'   `disperse_fecundity`, `disperse_drift`, and the numeric bin-midpoint columns
#'   `disperse_body_size_cm_mid`, `disperse_female_wing_mm_mid`,
#'   `disperse_fecundity_mid` (all joined on genus).
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
#' \dontrun{
#' taxify("Baetis rhodani", backend = "gbif") |>
#'   add_disperse()
#' }
#'
#' @export
add_disperse <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c("disperse_body_size_cm", "disperse_life_cycle",
            "disperse_repro_cycles", "disperse_dispersal",
            "disperse_adult_lifespan", "disperse_female_wing_mm",
            "disperse_wing_type", "disperse_fecundity", "disperse_drift")
  mid_cols <- c("disperse_body_size_cm_mid", "disperse_female_wing_mm_mid",
            "disperse_fecundity_mid")
  base_cols <- c(cat_cols, mid_cols)
  col_map <- stats::setNames(base_cols, base_cols)
  enrich_simple(
    x,
    enrichment_name = "disperse",
    col_map         = col_map,
    source_label    = "DISPERSE",
    join_col        = "genus",
    cols            = cols,
    verbose         = verbose
  )
}

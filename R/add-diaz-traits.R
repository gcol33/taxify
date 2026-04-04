#' Add seed mass and plant height (Diaz et al. 2022)
#'
#' Joins species-level mean seed mass and plant height from Diaz et al.
#' (2022) to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{seed_mass_mg}{Seed mass in milligrams (species-level mean).}
#'   \item{plant_height_m}{Plant height in metres (species-level mean).}
#' }
#'
#' @details
#' Source: Diaz et al. 2022, TRY File Archive (CC BY 3.0).
#' Coverage: ~46k plant species. Plants only.
#'
#' @references
#' Diaz S et al. (2022) The global spectrum of plant form and function:
#' enhanced species-level trait data. TRY File Archive.
#'
#' @examples
#' \dontrun{
#' taxify("Quercus robur") |>
#'   add_diaz_traits()
#' }
#'
#' @export
add_diaz_traits <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "diaz_traits",
    col_map         = c(
      seed_mass_mg   = "seed_mass_mg",
      plant_height_m = "plant_height_m"
    ),
    source_label    = "Diaz et al. 2022",
    na_types        = list(
      seed_mass_mg   = NA_real_,
      plant_height_m = NA_real_
    ),
    verbose         = verbose
  )
}

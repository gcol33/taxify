#' Add seed mass and plant height (Diaz et al. 2022)
#'
#' Joins species-level mean seed mass and plant height from Diaz et al.
#' (2022) to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
#' Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
#' Kleyer M, Wirth C, Prentice IC, et al. (2022) The global spectrum of plant
#' form and function: enhanced species-level trait dataset. Scientific Data
#' 9:755. \doi{10.1038/s41597-022-01774-9}
#'
#' Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
#' Kleyer M, Wirth C, Prentice IC, et al. (2016) The global spectrum of plant
#' form and function. Nature 529:167-171. \doi{10.1038/nature16489}
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur") |>
#'   add_diaz_traits()
#'
#' options(old)
#'
#' @export
add_diaz_traits <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "diaz_traits",
    col_map         = c(
      seed_mass_mg   = "seed_mass_mg",
      plant_height_m = "plant_height_m"
    ),
    source_label    = "Diaz et al. 2022",
    cols            = cols,
    verbose         = verbose
  )
}

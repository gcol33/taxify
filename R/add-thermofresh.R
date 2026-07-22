#' Add freshwater thermal-tolerance traits (ThermoFresh)
#'
#' Joins species-level critical thermal limits for freshwater fish,
#' invertebrates and amphibians to a [taxify()] result by looking up
#' `accepted_name`. All values are in degrees Celsius.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{thermofresh_ctmax}{Critical thermal maximum (degrees C).}
#'   \item{thermofresh_ctmin}{Critical thermal minimum (degrees C).}
#'   \item{thermofresh_lt50}{Median lethal temperature (degrees C).}
#'   \item{thermofresh_ltmax}{Lethal thermal maximum (degrees C).}
#'   \item{thermofresh_ltmin}{Lethal thermal minimum (degrees C).}
#' }
#'
#' @details Source: the Freshwater thermal-tolerance database (Helena Bayat and
#'   contributors, Zenodo, CC BY 4.0). Each source record is one tolerance test;
#'   values are reduced to species-level medians per metric.
#'
#' @references
#' Freshwater thermal-tolerance database. Zenodo. \doi{10.5281/zenodo.14056760}
#'
#' @examples
#' \dontrun{
#' taxify("Salmo trutta", backbone = "gbif") |>
#'   add_thermofresh()
#' }
#'
#' @export
add_thermofresh <- function(x, cols = NULL, verbose = TRUE) {
  num_cols <- c(
    thermofresh_ctmax = "ctmax",
    thermofresh_ctmin = "ctmin",
    thermofresh_lt50  = "lt50",
    thermofresh_ltmax = "ltmax",
    thermofresh_ltmin = "ltmin"
  )
  enrich_simple(
    x,
    enrichment_name = "thermofresh",
    col_map         = num_cols,
    source_label    = "ThermoFresh freshwater thermal tolerance",
    cols            = cols,
    verbose         = verbose
  )
}

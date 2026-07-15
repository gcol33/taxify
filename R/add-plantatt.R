#' Add British and Irish plant attributes (PLANTATT)
#'
#' Joins attributes of British and Irish vascular plants (Hill et al. 2004) to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{plantatt_ellenberg_light, plantatt_ellenberg_moisture,
#'     plantatt_ellenberg_reaction, plantatt_ellenberg_nitrogen,
#'     plantatt_ellenberg_salt}{Ellenberg indicator values calibrated for the
#'     British flora.}
#'   \item{plantatt_max_height_cm}{Maximum height, cm.}
#'   \item{plantatt_life_form}{Life-form code, kept verbatim (`Ch`, `Ph`,
#'     `Gn`, ...).}
#'   \item{plantatt_woodiness}{Woodiness code, kept verbatim (`w` woody,
#'     `h` herbaceous, `sw` semi-woody).}
#'   \item{plantatt_native_status}{Native-status code, kept verbatim (`N`
#'     native, `AN` alien naturalised, `AR` archaeophyte, ...).}
#' }
#'
#' @details
#' 1,887 taxa. For the German-flora equivalent see [add_floraweb()], for the
#' British Ecoflora traits [add_ecoflora()], and for European-calibration
#' indicator values [add_eive()].
#'
#' This source states no licence (it is copyright the Biological Records
#' Centre), so taxify ships no pre-built copy of it. The first call builds it
#' from the original source on your own machine, which requires the taxifydb
#' package (`remotes::install_github("gcol33/taxifydb")`). taxify redistributes
#' none of the data. Cite Hill et al. (2004) when you use it.
#'
#' @references
#' Hill MO, Preston CD, Roy DB (2004) PLANTATT: Attributes of British and Irish
#' Plants. Biological Records Centre, Centre for Ecology and Hydrology.
#'
#' @examples
#' \dontrun{
#' # Builds the enrichment on first use (needs taxifydb).
#' taxify("Bellis perennis", backend = "gbif") |>
#'   add_plantatt()
#' }
#'
#' @export
add_plantatt <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("ellenberg_light", "ellenberg_moisture", "ellenberg_reaction",
            "ellenberg_nitrogen", "ellenberg_salt", "max_height_cm",
            "life_form", "woodiness", "native_status")
  col_map <- stats::setNames(base, paste0("plantatt_", base))
  enrich_simple(
    x, enrichment_name = "plantatt", col_map = col_map,
    source_label = "PLANTATT (Hill et al. 2004)",
    cols = cols, col_prefix = "plantatt_", out_prefix = "plantatt_",
    verbose = verbose
  )
}

#' Add British and Irish bryophyte attributes (BRYOATT)
#'
#' Joins attributes of British and Irish mosses, liverworts and hornworts
#' (Hill et al. 2007) to a [taxify()] result by looking up `accepted_name`.
#' Bryophytes are otherwise almost absent from the bundled trait databases.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{bryoatt_ellenberg_light, bryoatt_ellenberg_moisture,
#'     bryoatt_ellenberg_reaction, bryoatt_ellenberg_nitrogen,
#'     bryoatt_ellenberg_salt}{Ellenberg indicator values calibrated for British
#'     and Irish bryophytes.}
#'   \item{bryoatt_life_form}{Life-form code, kept verbatim (`Ts`, `Mr`,
#'     `Ms`, ...).}
#'   \item{bryoatt_plant_group}{Plant group: `M` moss, `L` liverwort,
#'     `H` hornwort.}
#'   \item{bryoatt_status}{Status code, kept verbatim (`N` native, `AN` alien
#'     naturalised, `AR` archaeophyte).}
#' }
#'
#' @details
#' 1,194 taxa. The vascular-plant companion is [add_plantatt()].
#'
#' This source states no licence (it is copyright the Biological Records
#' Centre), so taxify ships no pre-built copy of it. The first call builds it
#' from the original source on your own machine, which requires the taxifydb
#' package (`remotes::install_github("gcol33/taxifydb")`). taxify redistributes
#' none of the data. Cite Hill et al. (2007) when you use it.
#'
#' @references
#' Hill MO, Preston CD, Bosanquet SDS, Roy DB (2007) BRYOATT: Attributes of
#' British and Irish Mosses, Liverworts and Hornworts. NERC Centre for Ecology
#' and Hydrology.
#'
#' @examples
#' \dontrun{
#' # Builds the enrichment on first use (needs taxifydb).
#' taxify("Polytrichum commune", backend = "gbif") |>
#'   add_bryoatt()
#' }
#'
#' @export
add_bryoatt <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("ellenberg_light", "ellenberg_moisture", "ellenberg_reaction",
            "ellenberg_nitrogen", "ellenberg_salt", "life_form",
            "plant_group", "status")
  col_map <- stats::setNames(base, paste0("bryoatt_", base))
  enrich_simple(
    x, enrichment_name = "bryoatt", col_map = col_map,
    source_label = "BRYOATT (Hill et al. 2007)",
    cols = cols, col_prefix = "bryoatt_", out_prefix = "bryoatt_",
    verbose = verbose
  )
}

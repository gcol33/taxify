#' Add thermal tolerance limits (GlobTherm)
#'
#' Joins GlobTherm upper and lower thermal tolerance limits to a [taxify()]
#' result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{globtherm_thermal_max_c}{Upper thermal limit (degrees Celsius).}
#'   \item{globtherm_thermal_max_metric}{Definition of the upper limit (e.g.
#'     ctmax, LT50, UTNZ); the value is ambiguous without it.}
#'   \item{globtherm_thermal_min_c}{Lower thermal limit (degrees Celsius).}
#'   \item{globtherm_thermal_min_metric}{Definition of the lower limit (e.g.
#'     ctmin, LT50, LTNZ).}
#'   \item{globtherm_thermal_max_error}{Reported error on the upper limit.}
#'   \item{globtherm_thermal_min_error}{Reported error on the lower limit.}
#' }
#'
#' @details
#' Source: GlobTherm (Bennett et al. 2018, Scientific Data, CC0).
#' Coverage: ~2.1k species across aquatic and terrestrial groups.
#'
#' @references
#' Bennett JM et al. (2018) GlobTherm, a database on the thermal tolerance for
#' aquatic and terrestrial organisms. Scientific Data 5:180022.
#' \doi{10.1038/sdata.2018.22}
#'
#' @examples
#' \donttest{
#' taxify("Lepomis gibbosus", backend = "gbif") |>
#'   add_globtherm()
#' }
#'
#' @export
add_globtherm <- function(x, verbose = TRUE) {
  col_map <- c(
    globtherm_thermal_max_c      = "thermal_max_c",
    globtherm_thermal_max_metric = "thermal_max_metric",
    globtherm_thermal_min_c      = "thermal_min_c",
    globtherm_thermal_min_metric = "thermal_min_metric",
    globtherm_thermal_max_error  = "thermal_max_error",
    globtherm_thermal_min_error  = "thermal_min_error"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("globtherm_thermal_max_metric",
             "globtherm_thermal_min_metric")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "globtherm",
    col_map         = col_map,
    source_label    = "GlobTherm",
    na_types        = na_types,
    verbose         = verbose
  )
}

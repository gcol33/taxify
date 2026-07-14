#' Add freshwater invertebrate traits (US EPA)
#'
#' Joins primary functional traits of freshwater macroinvertebrates from the
#' U.S. EPA Freshwater Biological Traits Database to a [taxify()] result.
#' Records are reduced to per-taxon modes. The database records each trait at
#' the finest available resolution, so the join matches `accepted_name` first
#' and then fills any trait still missing from the taxon's genus-level row; a
#' species-level value is never overwritten.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{epa_feeding_mode}{Functional feeding group.}
#'   \item{epa_habit}{Primary habit (e.g. clinger, burrower, swimmer).}
#'   \item{epa_voltinism}{Number of generations per year.}
#'   \item{epa_thermal_preference}{Thermal preference.}
#'   \item{epa_body_size_class}{Maximum body-size class.}
#' }
#' `cols = "all"` also attaches body shape, rheophily, oviposition behaviour,
#' and diapause.
#'
#' @details
#' Source: U.S. EPA Freshwater Biological Traits Database (2012), a public-domain
#' U.S. Government work, compiled primarily from Vieira et al. (2006).
#'
#' @references
#' U.S. Environmental Protection Agency (2012) Freshwater Biological Traits
#' Database. Compiled from Vieira NKM et al. (2006) A database of lotic
#' invertebrate traits for North America, USGS Data Series 187.
#'
#' @examples
#' \dontrun{
#' # Downloads the enrichment on first use.
#' taxify("Baetis", backend = "gbif") |>
#'   add_epa_freshwater()
#' }
#'
#' @export
add_epa_freshwater <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("feeding_mode", "habit", "voltinism", "thermal_preference",
            "body_size_class")
  col_map <- stats::setNames(base, paste0("epa_", base))
  enrich_simple(
    x, enrichment_name = "epa_freshwater", col_map = col_map,
    source_label = "US EPA Freshwater Biological Traits",
    genus_fallback = TRUE,
    cols = cols, col_prefix = "epa_", out_prefix = "epa_", verbose = verbose
  )
}

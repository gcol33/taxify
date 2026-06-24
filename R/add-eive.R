#' Add EIVE ecological indicator values
#'
#' Joins EIVE 1.0 (Dengler et al. 2023) ecological indicator values to a
#' [taxify()] result by looking up `accepted_name`. EIVE provides
#' continuous indicator values for European vascular plants, superseding
#' the original ordinal Ellenberg values.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{eive_light}{Light indicator value (continuous).}
#'   \item{eive_temperature}{Temperature indicator value (continuous).}
#'   \item{eive_moisture}{Moisture indicator value (continuous).}
#'   \item{eive_reaction}{Soil reaction (pH) indicator value (continuous).}
#'   \item{eive_nutrients}{Nutrient indicator value (continuous).}
#' }
#'
#' @details
#' Source: EIVE 1.0 (Dengler et al. 2023, Zenodo, CC BY 4.0).
#' Coverage: ~14.5k European vascular plant species.
#'
#' @references
#' Dengler J et al. (2023) EIVE 1.0 -- a standardized set of Ecological
#' Indicator Values for Europe. Vegetation Classification and Survey 4:7-29.
#' doi:10.3897/VCS.98324
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Arrhenatherum elatius") |>
#'   add_eive()
#'
#' options(old)
#'
#' @export
add_eive <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "eive",
    col_map         = c(
      eive_light       = "light",
      eive_temperature = "temperature",
      eive_moisture    = "moisture",
      eive_reaction    = "reaction",
      eive_nutrients   = "nutrients"
    ),
    source_label    = "EIVE 1.0",
    na_types        = list(
      eive_light       = NA_real_,
      eive_temperature = NA_real_,
      eive_moisture    = NA_real_,
      eive_reaction    = NA_real_,
      eive_nutrients   = NA_real_
    ),
    verbose         = verbose
  )
}

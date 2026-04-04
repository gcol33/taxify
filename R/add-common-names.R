#' Add common (vernacular) names
#'
#' Joins GBIF vernacular names to a [taxify()] result by looking up
#' `accepted_name`, filtered by language.
#'
#' @param x A data.frame returned by [taxify()].
#' @param lang Character. ISO 639-1 language code (e.g., `"en"`, `"de"`,
#'   `"fr"`). Default `"en"`.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with an additional column:
#' \describe{
#'   \item{common_name}{The vernacular name in the requested language,
#'     or `NA` if none is available.}
#' }
#'
#' @details
#' Source: GBIF backbone vernacular names (CC0). Multi-language via ISO
#' 639-1 codes. When multiple common names exist for a species in the
#' requested language, the first (most commonly used) is returned.
#'
#' @examples
#' \dontrun{
#' taxify("Quercus robur") |>
#'   add_common_names()
#'
#' taxify("Quercus robur") |>
#'   add_common_names(lang = "de")
#' }
#'
#' @export
add_common_names <- function(x, lang = "en", verbose = TRUE) {
  enrich_by_group(
    x,
    enrichment_name = "common_names",
    group_col       = "lang",
    groups          = lang,
    value_cols      = c(common_name = "common_name"),
    source_label    = "GBIF vernacular names",
    verbose         = verbose
  )
}

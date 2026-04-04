#' Add common (vernacular) names
#'
#' Joins vernacular names to a [taxify()] result by looking up
#' `accepted_name`, filtered by language.
#'
#' @param x A data.frame returned by [taxify()].
#' @param lang Character. ISO 639-1 language code (e.g., `"en"`, `"de"`,
#'   `"fr"`), or `NA` to return names without a language tag (NCBI/OTT
#'   sources). Default `"en"`.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with an additional column:
#' \describe{
#'   \item{common_name}{The vernacular name in the requested language,
#'     or `NA` if none is available.}
#' }
#'
#' @details
#' Common names are merged from three sources:
#' \itemize{
#'   \item GBIF backbone vernacular names (CC0) — multi-language via ISO
#'     639-1 codes.
#'   \item NCBI Taxonomy common names (public domain) — no language tag
#'     (`lang = NA`).
#'   \item Open Tree of Life common names (CC0) — no language tag
#'     (`lang = NA`).
#' }
#' When multiple common names exist for a species in the requested
#' language, the first (most commonly used) is returned.
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
    source_label    = "vernacular names",
    verbose         = verbose
  )
}

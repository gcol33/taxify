#' Add bee morphometrics (Ostwald)
#'
#' Joins global bee morphological traits to a [taxify()] result by
#' `accepted_name`. Long-format measurements are reduced to species medians.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric columns `bee_ostwald_itd_mm`
#'   (intertegular distance), `bee_ostwald_forewing_length_mm`,
#'   `bee_ostwald_tongue_length_mm`, `bee_ostwald_tongue_width_mm`,
#'   `bee_ostwald_body_length_mm`, `bee_ostwald_thorax_length_mm`,
#'   `bee_ostwald_hair_length_mm`, `bee_ostwald_hair_coverage_pct`.
#'
#' @details Source: Ostwald et al. global bee morphology (Zenodo, CC-BY 4.0).
#'
#' @references
#' Ostwald MM et al. (2024) A global database of bee morphological traits.
#' Zenodo. \doi{10.5281/zenodo.13366989}
#'
#' @examples
#' \dontrun{
#' taxify("Apis mellifera", backbone = "gbif") |>
#'   add_bee_ostwald()
#' }
#'
#' @export
add_bee_ostwald <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c("itd_mm", "forewing_length_mm", "tongue_length_mm",
            "tongue_width_mm", "body_length_mm", "thorax_length_mm",
            "hair_length_mm", "hair_coverage_pct")
  col_map <- stats::setNames(base_cols, paste0("bee_ostwald_", base_cols))
  enrich_simple(
    x,
    enrichment_name = "bee_ostwald",
    col_map         = col_map,
    source_label    = "Bee morphology (Ostwald)",
    cols            = cols,
    verbose         = verbose
  )
}

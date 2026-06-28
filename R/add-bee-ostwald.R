#' Add bee morphometrics (Ostwald)
#'
#' Joins global bee morphological traits to a [taxify()] result by
#' `accepted_name`. Long-format measurements are reduced to species medians.
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Apis mellifera", backend = "gbif") |>
#'   add_bee_ostwald()
#' }
#'
#' @export
add_bee_ostwald <- function(x, verbose = TRUE) {
  cols <- c("itd_mm", "forewing_length_mm", "tongue_length_mm",
            "tongue_width_mm", "body_length_mm", "thorax_length_mm",
            "hair_length_mm", "hair_coverage_pct")
  col_map <- stats::setNames(cols, paste0("bee_ostwald_", cols))
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "bee_ostwald",
    col_map         = col_map,
    source_label    = "Bee morphology (Ostwald)",
    na_types        = na_types,
    verbose         = verbose
  )
}

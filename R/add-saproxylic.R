#' Add saproxylic beetle morphology (Hagge)
#'
#' Joins European deadwood-beetle body and appendage morphometrics to a
#' [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric `saproxylic_` columns:
#'   `body_length_mm`, `body_width_mm`, `body_height_mm`, `mass_mg`,
#'   `colour_lightness`, `head_length_mm`, `pronotum_length_mm`,
#'   `elytra_length_mm`, `wing_length_mm`, `wing_aspect`, `antenna_length_mm`,
#'   `eye_length_mm`.
#'
#' @details Source: Hagge et al. (2021) saproxylic beetle morphology (Dryad, CC0).
#'
#' @references
#' Hagge J et al. (2021) Morphological trait database of European saproxylic
#' beetles. Dryad. \doi{10.5061/dryad.2fqz612p3}
#'
#' @examples
#' \donttest{
#' taxify("Rhysodes sulcatus", backend = "gbif") |>
#'   add_saproxylic()
#' }
#'
#' @export
add_saproxylic <- function(x, verbose = TRUE) {
  cols <- c("body_length_mm", "body_width_mm", "body_height_mm", "mass_mg",
            "colour_lightness", "head_length_mm", "pronotum_length_mm",
            "elytra_length_mm", "wing_length_mm", "wing_aspect",
            "antenna_length_mm", "eye_length_mm")
  col_map <- stats::setNames(cols, paste0("saproxylic_", cols))
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "saproxylic",
    col_map         = col_map,
    source_label    = "Saproxylic beetle morphology",
    na_types        = na_types,
    verbose         = verbose
  )
}

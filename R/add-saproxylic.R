#' Add saproxylic beetle morphology (Hagge)
#'
#' Joins European deadwood-beetle body and appendage morphometrics to a
#' [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
add_saproxylic <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c("body_length_mm", "body_width_mm", "body_height_mm", "mass_mg",
            "colour_lightness", "head_length_mm", "pronotum_length_mm",
            "elytra_length_mm", "wing_length_mm", "wing_aspect",
            "antenna_length_mm", "eye_length_mm")
  col_map <- stats::setNames(base_cols, paste0("saproxylic_", base_cols))
  enrich_simple(
    x,
    enrichment_name = "saproxylic",
    col_map         = col_map,
    source_label    = "Saproxylic beetle morphology",
    cols            = cols,
    verbose         = verbose
  )
}

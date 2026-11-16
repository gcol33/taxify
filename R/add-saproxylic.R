#' Add saproxylic beetle morphology (Hagge)
#'
#' Joins European deadwood-beetle body and appendage morphometrics to a
#' [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric `saproxylic_` columns:
#'   `saproxylic_body_length_mm`, `saproxylic_body_width_mm`, `saproxylic_body_height_mm`, `saproxylic_mass_mg`,
#'   `saproxylic_colour_lightness`, `saproxylic_head_length_mm`, `saproxylic_pronotum_length_mm`,
#'   `saproxylic_elytra_length_mm`, `saproxylic_wing_length_mm`, `saproxylic_wing_aspect`, `saproxylic_antenna_length_mm`,
#'   `saproxylic_eye_length_mm`.
#'
#' @details Source: Hagge et al. (2021) saproxylic beetle morphology (Dryad, CC0).
#'
#' @references
#' Hagge J et al. (2021) Morphological trait database of European saproxylic
#' beetles. Dryad. \doi{10.5061/dryad.2fqz612p3}
#'
#' @examples
#' \dontrun{
#' taxify("Rhysodes sulcatus", backbone = "gbif") |>
#'   add_saproxylic()
#' }
#'
#' @export
add_saproxylic <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_saproxylic, cols = cols, verbose = verbose)
}


.door_saproxylic <- list(
  enrichment_name = "saproxylic",
  col_map = c(
    saproxylic_body_length_mm = "body_length_mm",
    saproxylic_body_width_mm = "body_width_mm",
    saproxylic_body_height_mm = "body_height_mm",
    saproxylic_mass_mg = "mass_mg",
    saproxylic_colour_lightness = "colour_lightness",
    saproxylic_head_length_mm = "head_length_mm",
    saproxylic_pronotum_length_mm = "pronotum_length_mm",
    saproxylic_elytra_length_mm = "elytra_length_mm",
    saproxylic_wing_length_mm = "wing_length_mm",
    saproxylic_wing_aspect = "wing_aspect",
    saproxylic_antenna_length_mm = "antenna_length_mm",
    saproxylic_eye_length_mm = "eye_length_mm"
  ),
  source_label = "Saproxylic beetle morphology"
)

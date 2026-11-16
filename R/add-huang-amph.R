#' Add amphibian morphometrics (Huang)
#'
#' Joins species-level amphibian body measurements to a [taxify()] result by
#' `accepted_name`. Only measurements comparable across Anura, Caudata and
#' Gymnophiona are carried; per-specimen values are reduced to species medians.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric `huang_amph_svl_mm`,
#'   `huang_amph_head_length_mm`, `huang_amph_head_width_mm`,
#'   `huang_amph_eye_diameter_mm`, `huang_amph_forelimb_length_mm`,
#'   `huang_amph_hindlimb_length_mm` and categorical `huang_amph_taxon_order`.
#'
#' @details Source: Huang amphibian morphological dataset (figshare, CC-BY 4.0).
#'
#' @references
#' Huang et al. A global amphibian morphological trait dataset. figshare.
#' \doi{10.6084/m9.figshare.21159229}
#'
#' @examples
#' \dontrun{
#' taxify("Bufo bufo", backbone = "gbif") |>
#'   add_huang_amph()
#' }
#'
#' @export
add_huang_amph <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_huang_amph, cols = cols, verbose = verbose)
}


.door_huang_amph <- list(
  enrichment_name = "huang_amph",
  col_map = c(
    huang_amph_svl_mm = "svl_mm",
    huang_amph_head_length_mm = "head_length_mm",
    huang_amph_head_width_mm = "head_width_mm",
    huang_amph_eye_diameter_mm = "eye_diameter_mm",
    huang_amph_forelimb_length_mm = "forelimb_length_mm",
    huang_amph_hindlimb_length_mm = "hindlimb_length_mm",
    huang_amph_taxon_order = "taxon_order"
  ),
  source_label = "Huang amphibian morphology"
)

#' Add amphibian morphometrics (Huang)
#'
#' Joins species-level amphibian body measurements to a [taxify()] result by
#' `accepted_name`. Only measurements comparable across Anura, Caudata and
#' Gymnophiona are carried; per-specimen values are reduced to species medians.
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Bufo bufo", backend = "gbif") |>
#'   add_huang_amph()
#' }
#'
#' @export
add_huang_amph <- function(x, verbose = TRUE) {
  num_cols <- c("svl_mm", "head_length_mm", "head_width_mm", "eye_diameter_mm",
                "forelimb_length_mm", "hindlimb_length_mm")
  cat_cols <- c("taxon_order")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("huang_amph_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("huang_amph_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "huang_amph",
    col_map         = col_map,
    source_label    = "Huang amphibian morphology",
    na_types        = na_types,
    verbose         = verbose
  )
}

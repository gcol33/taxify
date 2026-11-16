#' Add Neotropical frugivore traits (Frugivoria)
#'
#' Joins shared bird/mammal frugivore traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `frugivoria_` columns: categorical
#'   `frugivoria_taxon_group`, `frugivoria_diet_category`; numeric `frugivoria_diet_breadth`, `frugivoria_body_mass_g`,
#'   `frugivoria_body_size_mm`, `frugivoria_longevity`, `frugivoria_generation_time`.
#'
#' @details Source: Gerstner et al. (2023) Frugivoria (EDI, CC-BY 4.0).
#'
#' @references
#' Gerstner BE et al. (2023) Frugivoria: a trait database for birds and mammals
#' exhibiting frugivory across contiguous Neotropical moist forests. EDI
#' (edi.1220.5).
#'
#' @examples
#' \dontrun{
#' taxify("Ramphastos toco", backbone = "gbif") |>
#'   add_frugivoria()
#' }
#'
#' @export
add_frugivoria <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_frugivoria, cols = cols, verbose = verbose)
}


.door_frugivoria <- list(
  enrichment_name = "frugivoria",
  col_map = c(
    frugivoria_diet_breadth = "diet_breadth",
    frugivoria_body_mass_g = "body_mass_g",
    frugivoria_body_size_mm = "body_size_mm",
    frugivoria_longevity = "longevity",
    frugivoria_generation_time = "generation_time",
    frugivoria_taxon_group = "taxon_group",
    frugivoria_diet_category = "diet_category"
  ),
  source_label = "Frugivoria"
)

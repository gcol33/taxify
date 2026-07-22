#' Add Neotropical frugivore traits (Frugivoria)
#'
#' Joins shared bird/mammal frugivore traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `frugivoria_` columns: categorical
#'   `taxon_group`, `diet_category`; numeric `diet_breadth`, `body_mass_g`,
#'   `body_size_mm`, `longevity`, `generation_time`.
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
  num_cols <- c("diet_breadth", "body_mass_g", "body_size_mm", "longevity",
                "generation_time")
  cat_cols <- c("taxon_group", "diet_category")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("frugivoria_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "frugivoria",
    col_map         = col_map,
    source_label    = "Frugivoria",
    cols            = cols,
    verbose         = verbose
  )
}

#' Add Neotropical frugivore traits (Frugivoria)
#'
#' Joins shared bird/mammal frugivore traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Ramphastos toco", backend = "gbif") |>
#'   add_frugivoria()
#' }
#'
#' @export
add_frugivoria <- function(x, verbose = TRUE) {
  num_cols <- c("diet_breadth", "body_mass_g", "body_size_mm", "longevity",
                "generation_time")
  cat_cols <- c("taxon_group", "diet_category")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("frugivoria_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("frugivoria_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "frugivoria",
    col_map         = col_map,
    source_label    = "Frugivoria",
    na_types        = na_types,
    verbose         = verbose
  )
}

#' Add freshwater mussel traits (SHELD)
#'
#' Joins US freshwater-mussel life-history and host traits to a [taxify()] result
#' by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `sheld_` columns: numeric `mean_length_mm`,
#'   `max_length_mm`, `mature_age`, `max_age`, `growth_rate`, `fecundity`,
#'   `n_host_species`, `n_host_family`; categorical `brood`, `marsupial_gills`,
#'   `hermaphrodite`, `shell_sculpture`.
#'
#' @details Source: SHELD (Hopper et al. 2023, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Hopper GW et al. (2023) A trait dataset for freshwater mussels of the United
#' States of America. Scientific Data 10:745. \doi{10.1038/s41597-023-02635-9}
#'
#' @examples
#' \donttest{
#' taxify("Lampsilis cardium", backend = "gbif") |>
#'   add_sheld()
#' }
#'
#' @export
add_sheld <- function(x, verbose = TRUE) {
  num_cols <- c("mean_length_mm", "max_length_mm", "mature_age", "max_age",
                "growth_rate", "fecundity", "n_host_species", "n_host_family")
  cat_cols <- c("brood", "marsupial_gills", "hermaphrodite", "shell_sculpture")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("sheld_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("sheld_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "sheld",
    col_map         = col_map,
    source_label    = "SHELD freshwater mussels",
    na_types        = na_types,
    verbose         = verbose
  )
}

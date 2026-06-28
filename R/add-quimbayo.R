#' Add reef-fish traits (Quimbayo)
#'
#' Joins Atlantic and Eastern-Pacific reef-fish life-history, ecology and
#' behaviour traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `quimbayo_` columns: numeric
#'   `body_size_max_cm`, `aspect_ratio`, `trophic_level`, `depth_min_m`,
#'   `depth_max_m`, `temp_occurrence_mean_c`; categorical `home_range`,
#'   `diel_activity`, `water_level`, `body_shape`, `mouth_position`, `diet`,
#'   `spawning`, `size_group`.
#'
#' @details Source: Quimbayo et al. (2021) reef-fish trait database (ESA data
#'   paper; Zenodo, open).
#'
#' @references
#' Quimbayo JP et al. (2021) Life-history traits, geographical range, and
#' conservation aspects of reef fishes. Ecology. \doi{10.5281/zenodo.4455016}
#'
#' @examples
#' \donttest{
#' taxify("Thalassoma bifasciatum", backend = "gbif") |>
#'   add_quimbayo()
#' }
#'
#' @export
add_quimbayo <- function(x, verbose = TRUE) {
  num_cols <- c("body_size_max_cm", "aspect_ratio", "trophic_level",
                "depth_min_m", "depth_max_m", "temp_occurrence_mean_c")
  cat_cols <- c("home_range", "diel_activity", "water_level", "body_shape",
                "mouth_position", "diet", "spawning", "size_group")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("quimbayo_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("quimbayo_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "quimbayo",
    col_map         = col_map,
    source_label    = "Quimbayo reef fish",
    na_types        = na_types,
    verbose         = verbose
  )
}

#' Add reef-fish traits (Quimbayo)
#'
#' Joins Atlantic and Eastern-Pacific reef-fish life-history, ecology and
#' behaviour traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `quimbayo_` columns: numeric
#'   `quimbayo_body_size_max_cm`, `quimbayo_aspect_ratio`, `quimbayo_trophic_level`, `quimbayo_depth_min_m`,
#'   `quimbayo_depth_max_m`, `quimbayo_temp_occurrence_mean_c`; categorical `quimbayo_home_range`,
#'   `quimbayo_diel_activity`, `quimbayo_water_level`, `quimbayo_body_shape`, `quimbayo_mouth_position`, `quimbayo_diet`,
#'   `quimbayo_spawning`, `quimbayo_size_group`.
#'
#' @details Source: Quimbayo et al. (2021) reef-fish trait database (ESA data
#'   paper; Zenodo, open).
#'
#' @references
#' Quimbayo JP et al. (2021) Life-history traits, geographical range, and
#' conservation aspects of reef fishes. Ecology. \doi{10.5281/zenodo.4455016}
#'
#' @examples
#' \dontrun{
#' taxify("Thalassoma bifasciatum", backbone = "gbif") |>
#'   add_quimbayo()
#' }
#'
#' @export
add_quimbayo <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_quimbayo, cols = cols, verbose = verbose)
}


.door_quimbayo <- list(
  enrichment_name = "quimbayo",
  col_map = c(
    quimbayo_body_size_max_cm = "body_size_max_cm",
    quimbayo_aspect_ratio = "aspect_ratio",
    quimbayo_trophic_level = "trophic_level",
    quimbayo_depth_min_m = "depth_min_m",
    quimbayo_depth_max_m = "depth_max_m",
    quimbayo_temp_occurrence_mean_c = "temp_occurrence_mean_c",
    quimbayo_home_range = "home_range",
    quimbayo_diel_activity = "diel_activity",
    quimbayo_water_level = "water_level",
    quimbayo_body_shape = "body_shape",
    quimbayo_mouth_position = "mouth_position",
    quimbayo_diet = "diet",
    quimbayo_spawning = "spawning",
    quimbayo_size_group = "size_group"
  ),
  source_label = "Quimbayo reef fish"
)

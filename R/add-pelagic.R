#' Add pelagic species traits
#'
#' Joins pelagic fish/cephalopod/gelatinous traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `pelagic_` columns: numeric `pelagic_depth_min_m`,
#'   `pelagic_depth_max_m`, `pelagic_temp_min_c`, `pelagic_temp_max_c`, `pelagic_temp_mean_c`,
#'   `pelagic_length_min_tl_cm`, `pelagic_length_max_tl_cm`, `pelagic_trophic_level`; categorical
#'   `pelagic_vert_habitat`, `pelagic_horz_habitat`, `pelagic_body_shape`, `pelagic_phys_defense`, `pelagic_gregarious`.
#'
#' @details Source: Gleiber et al. (2024) Pelagic Species Trait Database
#'   (Borealis, CC-BY 4.0).
#'
#' @references
#' Gleiber MR et al. (2024) A trait database for pelagic species. Scientific
#' Data. \doi{10.5683/SP3/0YFJED}
#'
#' @examples
#' \dontrun{
#' taxify("Thunnus albacares", backbone = "gbif") |>
#'   add_pelagic()
#' }
#'
#' @export
add_pelagic <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_pelagic, cols = cols, verbose = verbose)
}


.door_pelagic <- list(
  enrichment_name = "pelagic",
  col_map = c(
    pelagic_depth_min_m = "depth_min_m",
    pelagic_depth_max_m = "depth_max_m",
    pelagic_temp_min_c = "temp_min_c",
    pelagic_temp_max_c = "temp_max_c",
    pelagic_temp_mean_c = "temp_mean_c",
    pelagic_length_min_tl_cm = "length_min_tl_cm",
    pelagic_length_max_tl_cm = "length_max_tl_cm",
    pelagic_trophic_level = "trophic_level",
    pelagic_vert_habitat = "vert_habitat",
    pelagic_horz_habitat = "horz_habitat",
    pelagic_body_shape = "body_shape",
    pelagic_phys_defense = "phys_defense",
    pelagic_gregarious = "gregarious"
  ),
  source_label = "Pelagic Species Trait Database"
)

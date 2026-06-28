#' Add pelagic species traits
#'
#' Joins pelagic fish/cephalopod/gelatinous traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `pelagic_` columns: numeric `depth_min_m`,
#'   `depth_max_m`, `temp_min_c`, `temp_max_c`, `temp_mean_c`,
#'   `length_min_tl_cm`, `length_max_tl_cm`, `trophic_level`; categorical
#'   `vert_habitat`, `horz_habitat`, `body_shape`, `phys_defense`, `gregarious`.
#'
#' @details Source: Gleiber et al. (2024) Pelagic Species Trait Database
#'   (Borealis, CC-BY 4.0).
#'
#' @references
#' Gleiber MR et al. (2024) A trait database for pelagic species. Scientific
#' Data. \doi{10.5683/SP3/0YFJED}
#'
#' @examples
#' \donttest{
#' taxify("Thunnus albacares", backend = "gbif") |>
#'   add_pelagic()
#' }
#'
#' @export
add_pelagic <- function(x, verbose = TRUE) {
  num_cols <- c("depth_min_m", "depth_max_m", "temp_min_c", "temp_max_c",
                "temp_mean_c", "length_min_tl_cm", "length_max_tl_cm",
                "trophic_level")
  cat_cols <- c("vert_habitat", "horz_habitat", "body_shape", "phys_defense",
                "gregarious")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("pelagic_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("pelagic_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "pelagic",
    col_map         = col_map,
    source_label    = "Pelagic Species Trait Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

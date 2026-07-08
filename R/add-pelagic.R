#' Add pelagic species traits
#'
#' Joins pelagic fish/cephalopod/gelatinous traits to a [taxify()] result by
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
add_pelagic <- function(x, cols = NULL, verbose = TRUE) {
  num_cols <- c("depth_min_m", "depth_max_m", "temp_min_c", "temp_max_c",
                "temp_mean_c", "length_min_tl_cm", "length_max_tl_cm",
                "trophic_level")
  cat_cols <- c("vert_habitat", "horz_habitat", "body_shape", "phys_defense",
                "gregarious")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("pelagic_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "pelagic",
    col_map         = col_map,
    source_label    = "Pelagic Species Trait Database",
    cols            = cols,
    verbose         = verbose
  )
}

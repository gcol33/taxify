#' Add freshwater mussel traits (SHELD)
#'
#' Joins US freshwater-mussel life-history and host traits to a [taxify()] result
#' by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `sheld_` columns: numeric `sheld_mean_length_mm`,
#'   `sheld_max_length_mm`, `sheld_mature_age`, `sheld_max_age`, `sheld_growth_rate`, `sheld_fecundity`,
#'   `sheld_n_host_species`, `sheld_n_host_family`; categorical `sheld_brood`, `sheld_marsupial_gills`,
#'   `sheld_hermaphrodite`, `sheld_shell_sculpture`.
#'
#' @details Source: SHELD (Hopper et al. 2023, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Hopper GW et al. (2023) A trait dataset for freshwater mussels of the United
#' States of America. Scientific Data 10:745. \doi{10.1038/s41597-023-02635-9}
#'
#' @examples
#' \dontrun{
#' taxify("Lampsilis cardium", backbone = "gbif") |>
#'   add_sheld()
#' }
#'
#' @export
add_sheld <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_sheld, cols = cols, verbose = verbose)
}


.door_sheld <- list(
  enrichment_name = "sheld",
  col_map = c(
    sheld_mean_length_mm = "mean_length_mm",
    sheld_max_length_mm = "max_length_mm",
    sheld_mature_age = "mature_age",
    sheld_max_age = "max_age",
    sheld_growth_rate = "growth_rate",
    sheld_fecundity = "fecundity",
    sheld_n_host_species = "n_host_species",
    sheld_n_host_family = "n_host_family",
    sheld_brood = "brood",
    sheld_marsupial_gills = "marsupial_gills",
    sheld_hermaphrodite = "hermaphrodite",
    sheld_shell_sculpture = "shell_sculpture"
  ),
  source_label = "SHELD freshwater mussels"
)

#' Add phytoplankton cell metrics (Rimet & Druart)
#'
#' Joins cell-level morphometrics for temperate-lake phytoplankton to a
#' [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with numeric columns
#'   `rimet_phyto_cell_length_um`, `rimet_phyto_cell_width_um`,
#'   `rimet_phyto_cell_thickness_um`, `rimet_phyto_cell_surface_area_um2`,
#'   `rimet_phyto_cell_biovolume_um3`.
#'
#' @details Source: Rimet & Druart (2018) phytoplankton metrics database
#'   (Zenodo, CC-BY 4.0).
#'
#' @references
#' Rimet F, Druart JC (2018) A trait database for phytoplankton of temperate
#' lakes. Zenodo. \doi{10.5281/zenodo.1164834}
#'
#' @examples
#' \donttest{
#' taxify("Asterionella formosa", backend = "gbif") |>
#'   add_rimet_phyto()
#' }
#'
#' @export
add_rimet_phyto <- function(x, verbose = TRUE) {
  cols <- c("cell_length_um", "cell_width_um", "cell_thickness_um",
            "cell_surface_area_um2", "cell_biovolume_um3")
  col_map <- stats::setNames(cols, paste0("rimet_phyto_", cols))
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "rimet_phyto",
    col_map         = col_map,
    source_label    = "Rimet phytoplankton",
    na_types        = na_types,
    verbose         = verbose
  )
}

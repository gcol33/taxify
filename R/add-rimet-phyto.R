#' Add phytoplankton cell metrics (Rimet & Druart)
#'
#' Joins cell-level morphometrics for temperate-lake phytoplankton to a
#' [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
#' \dontrun{
#' taxify("Asterionella formosa", backbone = "gbif") |>
#'   add_rimet_phyto()
#' }
#'
#' @export
add_rimet_phyto <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_rimet_phyto, cols = cols, verbose = verbose)
}


.door_rimet_phyto <- list(
  enrichment_name = "rimet_phyto",
  col_map = c(
    rimet_phyto_cell_length_um = "cell_length_um",
    rimet_phyto_cell_width_um = "cell_width_um",
    rimet_phyto_cell_thickness_um = "cell_thickness_um",
    rimet_phyto_cell_surface_area_um2 = "cell_surface_area_um2",
    rimet_phyto_cell_biovolume_um3 = "cell_biovolume_um3"
  ),
  source_label = "Rimet phytoplankton"
)

#' Add German ground-beetle traits and occupancy trends (Chowdhury et al. 2025)
#'
#' Joins carabid (ground beetle) traits and modelled national occupancy trends to
#' a [taxify()] result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all of them, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `chowdhury_` columns: numeric
#'   `body_length_mm` and `occupancy_trend`; categorical `wing_morph`,
#'   `trophic_level`, `habitat_pref`, `red_list_germany`, `red_list_iucn`,
#'   `threat_status`, `trend_status`, `trend_significance`.
#'
#' @details Source: Supporting Information Data S1 of Chowdhury et al. (2025),
#'   383 German carabid species, 382 of them with traits. Ground beetles are one
#'   of the most intensively sampled insect groups in ecology, and this is the
#'   largest openly reachable block of carabid traits.
#'
#'   `wing_morph` is three-state -- long-winged, short-winged, and the 83
#'   dimorphic species that produce both forms. Dimorphism is the trait of
#'   interest in carabid dispersal ecology, so it is never collapsed into a
#'   flight-capable/flightless binary.
#'
#'   `red_list_germany` is the German national Red List code (`*`, 1, 2, 3, V,
#'   R, G, D). `red_list_iucn` restates that same national assessment in IUCN
#'   letter codes and is **not** a global IUCN assessment: it maps
#'   deterministically onto `red_list_germany` (`*` to LC, 1 to CR, 2 to EN, 3
#'   to VU, V to NT), with no off-diagonal case in all 382 species. A species can
#'   be critically endangered at its German range edge and of least concern
#'   globally, so these columns stay on this door and out of the global
#'   `conservation_status` trait.
#'
#'   `occupancy_trend` is the paper's own result: the modelled change in
#'   occupancy probability over two years, negative for a declining species.
#'
#' @references
#' Chowdhury S, Jaureguiberry P, Rada S, et al. (2025) Widespread decline of
#' ground beetles in Germany. Diversity and Distributions.
#' \doi{10.1111/ddi.70112}
#'
#' @examples
#' \dontrun{
#' taxify(c("Carabus coriaceus", "Amara aenea")) |>
#'   add_chowdhury()
#' }
#'
#' @export
add_chowdhury <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("body_length_mm", "wing_morph", "trophic_level", "habitat_pref",
                "red_list_germany", "red_list_iucn", "threat_status",
                "occupancy_trend", "trend_status", "trend_significance")
  col_map <- stats::setNames(all_cols, paste0("chowdhury_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "chowdhury",
    col_map         = col_map,
    source_label    = "Chowdhury German carabid traits",
    cols            = cols,
    verbose         = verbose
  )
}

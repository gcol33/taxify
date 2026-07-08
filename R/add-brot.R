#' Add Mediterranean plant traits (BROT 2.0)
#'
#' Joins Mediterranean-Basin plant fire-response, regeneration and functional
#' traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `brot_` columns: numeric `seed_mass_mg`,
#'   `sla_mm2_mg`, `height_m`, `leaf_area_mm2`; categorical `resp_fire`,
#'   `growth_form`, `disp_mode`, `fruit_type`, `soil_seed_bank`,
#'   `seedling_emergence`.
#'
#' @details Source: BROT 2.0 (Tavsanoglu & Pausas 2018, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Tavsanoglu C, Pausas JG (2018) A functional trait database for Mediterranean
#' Basin plants (BROT 2.0). Scientific Data 5:180135.
#' \doi{10.6084/m9.figshare.c.3843841}
#'
#' @examples
#' \donttest{
#' taxify("Quercus coccifera", backend = "gbif") |>
#'   add_brot()
#' }
#'
#' @export
add_brot <- function(x, cols = NULL, verbose = TRUE) {
  num_cols <- c("seed_mass_mg", "sla_mm2_mg", "height_m", "leaf_area_mm2")
  cat_cols <- c("resp_fire", "growth_form", "disp_mode", "fruit_type",
                "soil_seed_bank", "seedling_emergence")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("brot_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "brot",
    col_map         = col_map,
    source_label    = "BROT 2.0",
    cols            = cols,
    verbose         = verbose
  )
}

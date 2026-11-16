#' Add Mediterranean plant traits (BROT 2.0)
#'
#' Joins Mediterranean-Basin plant fire-response, regeneration and functional
#' traits to a [taxify()] result by `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `brot_` columns: numeric `brot_seed_mass_mg`,
#'   `brot_sla_mm2_mg`, `brot_height_m`, `brot_leaf_area_mm2`; categorical `brot_resp_fire`,
#'   `brot_growth_form`, `brot_disp_mode`, `brot_fruit_type`, `brot_soil_seed_bank`,
#'   `brot_seedling_emergence`.
#'
#' @details Source: BROT 2.0 (Tavsanoglu & Pausas 2018, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Tavsanoglu C, Pausas JG (2018) A functional trait database for Mediterranean
#' Basin plants (BROT 2.0). Scientific Data 5:180135.
#' \doi{10.6084/m9.figshare.c.3843841}
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus coccifera", backbone = "gbif") |>
#'   add_brot()
#'
#' options(old)
#'
#' @export
add_brot <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_brot, cols = cols, verbose = verbose)
}


.door_brot <- list(
  enrichment_name = "brot",
  col_map = c(
    brot_seed_mass_mg = "seed_mass_mg",
    brot_sla_mm2_mg = "sla_mm2_mg",
    brot_height_m = "height_m",
    brot_leaf_area_mm2 = "leaf_area_mm2",
    brot_resp_fire = "resp_fire",
    brot_growth_form = "growth_form",
    brot_disp_mode = "disp_mode",
    brot_fruit_type = "fruit_type",
    brot_soil_seed_bank = "soil_seed_bank",
    brot_seedling_emergence = "seedling_emergence"
  ),
  source_label = "BROT 2.0"
)

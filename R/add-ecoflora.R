#' Add British plant traits from Ecoflora
#'
#' Joins traits from the Ecological Flora of the British Isles (Fitter & Peat
#' 1994) to a [taxify()] result by looking up `accepted_name`. Ecoflora covers
#' the vascular flora of the British Isles, providing canopy height, leaf
#' traits, life form, flowering phenology, pollination and reproduction, seed
#' weight, and British-calibrated Ellenberg indicator values. Every column
#' carries a `_uk` suffix to mark the British-flora calibration and to avoid
#' collisions when chained with other plant-trait enrichments
#' (e.g. [add_baseflor()] for France, [add_floraweb()] for Germany).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional `_uk` columns:
#' \describe{
#'   \item{ecoflora_height_max_mm_uk, ecoflora_height_min_mm_uk}{Typical maximum and minimum
#'     plant height (mm; Ecoflora records cm).}
#'   \item{ecoflora_leaf_area_uk}{Leaf area class (cm\eqn{^2}).}
#'   \item{ecoflora_leaf_longevity_uk}{Leaf longevity (e.g. evergreen, deciduous).}
#'   \item{ecoflora_root_system_uk}{Root system type.}
#'   \item{ecoflora_photosynthetic_pathway_uk}{Photosynthetic pathway (C3/C4/CAM).}
#'   \item{ecoflora_life_form_uk}{Raunkiaer life form.}
#'   \item{ecoflora_reproduction_uk}{Reproduction method.}
#'   \item{ecoflora_flower_begin_month_uk, ecoflora_flower_end_month_uk}{Flowering months (1-12).}
#'   \item{ecoflora_pollination_vector_uk}{Pollen vector(s).}
#'   \item{ecoflora_seed_weight_mg_uk}{Seed weight (mg).}
#'   \item{ecoflora_propagule_uk}{Propagule / dispersule type.}
#'   \item{ecoflora_ell_light_uk, ecoflora_ell_moisture_uk, ecoflora_ell_reaction_uk, ecoflora_ell_nitrogen_uk,
#'     ell_salt_uk}{Ellenberg indicator values calibrated for the British flora
#'     (light, moisture, reaction, nitrogen, salt).}
#' }
#'
#' @details
#' Source: Ecoflora (Ecological Flora of the British Isles). Ecoflora has no
#' bulk download or API; the bundled dataset was collected one species at a
#' time and is redistributed under the source licence (CC BY-NC-SA 4.0). The
#' `.vtr` is downloaded from the taxify release on first use and cached.
#'
#' For French-flora traits see [add_baseflor()]; for German-flora traits see
#' [add_floraweb()]; for European-calibration indicator values see [add_eive()].
#'
#' @references
#' Fitter AH, Peat HJ (1994) The Ecological Flora Database. Journal of Ecology
#' 82:415-425.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Bellis perennis") |>
#'   add_ecoflora()
#'
#' options(old)
#'
#' @export
add_ecoflora <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_ecoflora, cols = cols, verbose = verbose)
}


.door_ecoflora <- list(
  enrichment_name = "ecoflora",
  col_map = c(
    height_max_mm_uk = "height_max_mm_uk",
    height_min_mm_uk = "height_min_mm_uk",
    leaf_area_uk = "leaf_area_uk",
    leaf_longevity_uk = "leaf_longevity_uk",
    root_system_uk = "root_system_uk",
    photosynthetic_pathway_uk = "photosynthetic_pathway_uk",
    life_form_uk = "life_form_uk",
    reproduction_uk = "reproduction_uk",
    flower_begin_month_uk = "flower_begin_month_uk",
    flower_end_month_uk = "flower_end_month_uk",
    pollination_vector_uk = "pollination_vector_uk",
    seed_weight_mg_uk = "seed_weight_mg_uk",
    propagule_uk = "propagule_uk",
    ell_light_uk = "ell_light_uk",
    ell_moisture_uk = "ell_moisture_uk",
    ell_reaction_uk = "ell_reaction_uk",
    ell_nitrogen_uk = "ell_nitrogen_uk",
    ell_salt_uk = "ell_salt_uk"
  ),
  source_label = "Ecoflora (Ecological Flora of the British Isles)"
)

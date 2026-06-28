#' Add Australian plant traits (AusTraits)
#'
#' Joins species-level plant functional traits to a [taxify()] result by looking
#' up `accepted_name`. Values are aggregated from the long-format AusTraits
#' database (numeric traits by median, categorical traits by mode).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{austraits_plant_growth_form}{Plant growth form.}
#'   \item{austraits_life_history}{Life history (annual/perennial/...).}
#'   \item{austraits_woodiness}{Woodiness.}
#'   \item{austraits_photosynthetic_pathway}{Photosynthetic pathway (C3/C4/CAM).}
#'   \item{austraits_dispersal_syndrome}{Dispersal syndrome.}
#'   \item{austraits_resprouting_capacity}{Resprouting capacity (fire response).}
#'   \item{austraits_flowering_time}{Flowering time.}
#'   \item{austraits_plant_height_m}{Plant height (m).}
#'   \item{austraits_leaf_length_mm}{Leaf length (mm).}
#'   \item{austraits_leaf_width_mm}{Leaf width (mm).}
#'   \item{austraits_leaf_area_mm2}{Leaf area (mm2).}
#'   \item{austraits_leaf_mass_per_area}{Leaf mass per area (g/m2; SLA is its
#'     reciprocal).}
#'   \item{austraits_leaf_n_per_dry_mass}{Leaf nitrogen per dry mass (mg/g).}
#'   \item{austraits_leaf_p_per_dry_mass}{Leaf phosphorus per dry mass (mg/g).}
#'   \item{austraits_seed_dry_mass_mg}{Seed dry mass (mg).}
#'   \item{austraits_wood_density_g_cm3}{Wood density (g/cm3).}
#' }
#'
#' @details
#' Source: AusTraits (Falster et al. 2021, Scientific Data, CC BY 4.0).
#' Coverage: ~33k Australian plant taxa.
#'
#' @references
#' Falster D et al. (2021) AusTraits, a curated plant trait database for the
#' Australian flora. Scientific Data 8:254. \doi{10.1038/s41597-021-01006-6}
#'
#' @examples
#' \donttest{
#' taxify("Eucalyptus globulus", backend = "gbif") |>
#'   add_austraits()
#' }
#'
#' @export
add_austraits <- function(x, verbose = TRUE) {
  col_map <- c(
    austraits_plant_growth_form      = "plant_growth_form",
    austraits_life_history           = "life_history",
    austraits_woodiness              = "woodiness",
    austraits_photosynthetic_pathway = "photosynthetic_pathway",
    austraits_dispersal_syndrome     = "dispersal_syndrome",
    austraits_resprouting_capacity   = "resprouting_capacity",
    austraits_flowering_time         = "flowering_time",
    austraits_plant_height_m         = "plant_height_m",
    austraits_leaf_length_mm         = "leaf_length_mm",
    austraits_leaf_width_mm          = "leaf_width_mm",
    austraits_leaf_area_mm2          = "leaf_area_mm2",
    austraits_leaf_mass_per_area     = "leaf_mass_per_area",
    austraits_leaf_n_per_dry_mass    = "leaf_n_per_dry_mass",
    austraits_leaf_p_per_dry_mass    = "leaf_p_per_dry_mass",
    austraits_seed_dry_mass_mg       = "seed_dry_mass_mg",
    austraits_wood_density_g_cm3     = "wood_density_g_cm3"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("austraits_plant_growth_form", "austraits_life_history",
             "austraits_woodiness", "austraits_photosynthetic_pathway",
             "austraits_dispersal_syndrome", "austraits_resprouting_capacity",
             "austraits_flowering_time")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "austraits",
    col_map         = col_map,
    source_label    = "AusTraits",
    na_types        = na_types,
    verbose         = verbose
  )
}

# Trait columns served by the floraweb enrichment .vtr. The .vtr column names
# are identical to the output column names, so the enrich_simple() col_map is
# the identity map over this vector (single source of truth).
.floraweb_cols <- c(
  # morphology
  "height_de", "life_form_de", "leaf_shape_de", "leaf_anatomy_de",
  "leaf_persistence_de", "storage_organs_de", "flowering_months_de",
  "flowering_months_biolflor_de", "flowering_phase_de",
  "phenological_season_de", "description_de",
  # reproductive biology
  "pollination_vector_de", "pollinator_de", "pollinator_reward_de",
  "flower_type_de", "flower_class_de", "dispersal_type_de", "diaspore_type_de",
  "germinule_type_de", "reproduction_type_de", "vegetative_spread_de",
  "fertilization_type_de", "apomixis_de", "dicliny_de", "dichogamy_de",
  "self_incompatibility_de", "si_mechanism_de", "ploidy_de",
  "chromosome_number_de", "chromosome_freq_de", "chromosomes_de",
  # ecology (Ellenberg indicator values + community bindings)
  "ell_light_de", "ell_temperature_de", "ell_continentality_de",
  "ell_moisture_de", "ell_moisture_variability_de", "ell_reaction_de",
  "ell_nitrogen_de", "ell_salt_de", "heavy_metal_resistance_de",
  "strategy_type_de", "habitat_site_de", "formation_de", "plant_community_de",
  "biotope_type_de", "forest_binding_de", "hemeroby_de", "urbanity_de",
  # chorological distribution
  "floristic_zones_de", "areal_formula_de", "areal_type_de", "oceanity_de",
  "range_centre_de", "world_range_size_de", "world_range_frequency_de",
  "world_range_position_de", "world_range_hazard_de", "germany_range_share_de",
  "germany_responsibility_de"
)


#' Add German plant traits from FloraWeb
#'
#' Joins traits from FloraWeb (Bundesamt fuer Naturschutz) to a [taxify()]
#' result by looking up `accepted_name`. FloraWeb is the live national portal
#' carrying the BiolFlor trait data (Klotz, Kuehn & Durka 2002) together with
#' Rothmaler morphology and Ellenberg indicator values. This enrichment covers
#' the full per-species trait profile scraped from the four FloraWeb trait
#' pages: morphology, reproductive biology, the nine Ellenberg indicator
#' values, ploidy and chromosome number, and chorological distribution. Every
#' column carries a `_de` suffix to mark the German-flora calibration and to
#' avoid collisions when chained with other plant-trait enrichments
#' (e.g. [add_ecoflora()] for Britain, [add_baseflor()] for France).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with German trait columns (all suffixed `_de`),
#'   grouped as:
#' \describe{
#'   \item{Morphology}{`height_de`, `life_form_de`, `leaf_shape_de`,
#'     `leaf_anatomy_de`, `leaf_persistence_de`, `storage_organs_de`,
#'     `flowering_months_de`, `flowering_months_biolflor_de`,
#'     `flowering_phase_de`, `phenological_season_de`, `description_de`.}
#'   \item{Reproductive biology}{`pollination_vector_de`, `pollinator_de`,
#'     `pollinator_reward_de`, `flower_type_de`, `flower_class_de`,
#'     `dispersal_type_de`, `diaspore_type_de`, `germinule_type_de`,
#'     `reproduction_type_de`, `vegetative_spread_de`, `fertilization_type_de`,
#'     `apomixis_de`, `dicliny_de`, `dichogamy_de`, `self_incompatibility_de`,
#'     `si_mechanism_de`, `ploidy_de`, `chromosome_number_de`,
#'     `chromosome_freq_de`, `chromosomes_de`.}
#'   \item{Ecology}{the nine Ellenberg indicator values `ell_light_de`,
#'     `ell_temperature_de`, `ell_continentality_de`, `ell_moisture_de`,
#'     `ell_moisture_variability_de`, `ell_reaction_de`, `ell_nitrogen_de`,
#'     `ell_salt_de`, `heavy_metal_resistance_de`, plus `strategy_type_de`
#'     (Grime CSR), `habitat_site_de`, `formation_de`, `plant_community_de`,
#'     `biotope_type_de`, `forest_binding_de`, `hemeroby_de`, `urbanity_de`.}
#'   \item{Distribution}{`floristic_zones_de`, `areal_formula_de`,
#'     `areal_type_de`, `oceanity_de`, `range_centre_de`, `world_range_size_de`,
#'     `world_range_frequency_de`, `world_range_position_de`,
#'     `world_range_hazard_de`, `germany_range_share_de`,
#'     `germany_responsibility_de`.}
#' }
#'   Categorical traits with several applicable values are joined with "; ".
#'   Trait values are German (as published by FloraWeb / BiolFlor).
#'
#' @details
#' Source: FloraWeb (<https://www.floraweb.de/>), Bundesamt fuer Naturschutz,
#' Bonn. FloraWeb has no bulk export or API; the bundled dataset was scraped
#' per species (accessed 2026-06-24) and that access date is the dataset
#' version. The trait data largely derive from BiolFlor, which per the BioFresh
#' metadata statement is publicly available and may be used without
#' restrictions provided it is acknowledged and cited correctly. The `.vtr` is
#' downloaded from the taxify release on first use and cached.
#'
#' For British-flora traits see [add_ecoflora()]; for French-flora traits see
#' [add_baseflor()]; for European-calibration indicator values see [add_eive()].
#'
#' @references
#' Klotz S, Kuehn I, Durka W (2002) BIOLFLOR - Eine Datenbank zu
#' biologisch-oekologischen Merkmalen der Gefaesspflanzen in Deutschland.
#' Schriftenreihe fuer Vegetationskunde 38. Bundesamt fuer Naturschutz, Bonn.
#'
#' @examples
#' \dontrun{
#' taxify("Bellis perennis") |>
#'   add_floraweb()
#' }
#'
#' @export
add_floraweb <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "floraweb",
    col_map         = stats::setNames(.floraweb_cols, .floraweb_cols),
    source_label    = "FloraWeb (BfN; BiolFlor data, Klotz, Kuehn & Durka 2002)",
    verbose         = verbose
  )
}


#' Add German plant traits from BiolFlor (deprecated alias for add_floraweb)
#'
#' `add_biolflor()` is deprecated. Use [add_floraweb()], which joins the same
#' BiolFlor trait data (now bundled from FloraWeb, the live BfN portal that
#' carries it) plus the full FloraWeb trait profile, and works offline. This
#' alias forwards to [add_floraweb()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The result of [add_floraweb()].
#'
#' @seealso [add_floraweb()]
#' @keywords internal
#' @export
add_biolflor <- function(x, verbose = TRUE) {
  .Deprecated("add_floraweb", package = "taxify")
  add_floraweb(x, verbose = verbose)
}

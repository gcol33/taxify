#' Add plant traits from LEDA Traitbase
#'
#' Joins LEDA Traitbase (Kleyer et al. 2008) plant functional traits to a
#' [taxify()] result by looking up `accepted_name`. LEDA provides species-level
#' trait data for NW European plant species, covering life form, dispersal,
#' seed, leaf, and clonality traits.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{raunkiaer_life_form}{Primary Raunkiaer life form classification
#'     (phanerophyte, chamaephyte, hemicryptophyte, geophyte, therophyte,
#'     helophyte, hydrophyte).}
#'   \item{raunkiaer_variable}{1 if species assigned to multiple Raunkiaer
#'     forms, 0 otherwise.}
#'   \item{dispersal_type}{Primary dispersal type (anemochory, zoochory,
#'     hydrochory, autochory, barochory, dysochory).}
#'   \item{terminal_velocity_ms}{Seed terminal velocity in m/s (species
#'     median).}
#'   \item{seed_mass_mg}{Seed mass in mg (species median). Prefixed with
#'     \code{leda_} in the .vtr to avoid collision with Diaz traits.}
#'   \item{canopy_height_m}{Canopy height in meters (species median).}
#'   \item{leaf_mass_mg}{Leaf dry mass in mg (species median).}
#'   \item{sla_mm2_mg}{Specific leaf area in mm\eqn{^2}/mg (species median).}
#'   \item{clonal_growth}{Capable of clonal growth (1 = yes, 0 = no).}
#'   \item{buoyancy}{Seed buoyancy classification.}
#' }
#'
#' @details
#' Source: LEDA Traitbase (Kleyer et al. 2008).
#' Coverage: ~8,000 NW European plant species.
#'
#' The Raunkiaer life form is a bud-position classification system:
#' phanerophyte = buds >25 cm above soil, chamaephyte = buds near soil surface,
#' hemicryptophyte = buds at soil surface, geophyte (cryptophyte) = buds below
#' soil, therophyte = annual that survives as seed.
#'
#' @references
#' Kleyer M et al. (2008) The LEDA Traitbase: a database of life-history
#' traits of the Northwest European flora. Journal of Ecology 96:1266-1274.
#'
#' @examples
#' \dontrun{
#' taxify("Arrhenatherum elatius") |>
#'   add_leda()
#' }
#'
#' @export
add_leda <- function(x, verbose = TRUE) {
  col_map <- c(
    raunkiaer_life_form  = "raunkiaer_life_form",
    raunkiaer_variable   = "raunkiaer_variable",
    dispersal_type       = "dispersal_type",
    terminal_velocity_ms = "terminal_velocity_ms",
    seed_mass_mg         = "leda_seed_mass_mg",
    canopy_height_m      = "canopy_height_m",
    leaf_mass_mg         = "leaf_mass_mg",
    sla_mm2_mg           = "sla_mm2_mg",
    clonal_growth        = "clonal_growth",
    buoyancy             = "buoyancy"
  )
  na_types <- list(
    raunkiaer_life_form  = NA_character_,
    raunkiaer_variable   = NA_integer_,
    dispersal_type       = NA_character_,
    terminal_velocity_ms = NA_real_,
    seed_mass_mg         = NA_real_,
    canopy_height_m      = NA_real_,
    leaf_mass_mg         = NA_real_,
    sla_mm2_mg           = NA_real_,
    clonal_growth        = NA_integer_,
    buoyancy             = NA_character_
  )
  enrich_simple(
    x,
    enrichment_name = "leda",
    col_map         = col_map,
    source_label    = "LEDA Traitbase",
    na_types        = na_types,
    verbose         = verbose
  )
}

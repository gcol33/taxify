#' Add plant traits from LEDA Traitbase
#'
#' Joins LEDA Traitbase (Kleyer et al. 2008) plant functional traits to a
#' [taxify()] result by looking up `accepted_name`. LEDA provides species-level
#' trait data for NW European plant species, covering life form, dispersal,
#' seed, leaf, and clonality traits.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{raunkiaer_life_form}{Most frequent LEDA plant growth form: the
#'     Raunkiaer classes (Phanerophyte, Chamaephyte, Hemicryptophyte, Geophyte,
#'     Therophyte, Hydrophyte) plus Liana, Vascular semi-parasite and Vascular
#'     parasite.}
#'   \item{raunkiaer_variable}{1 if the species' records name more than one
#'     growth form, 0 otherwise.}
#'   \item{dispersal_type}{Most frequent dispersal type, as LEDA's -chor term
#'     (meteorochor, epizoochor, nautochor, ...).}
#'   \item{terminal_velocity_ms}{Diaspore terminal velocity in m/s (species
#'     median).}
#'   \item{seed_mass_mg}{Seed mass in mg (species median). Prefixed with
#'     \code{leda_} in the .vtr to avoid collision with Diaz traits.}
#'   \item{canopy_height_m}{Canopy height in metres (species median): the
#'     height of the highest photosynthetic tissue, which LEDA distinguishes from
#'     plant height.}
#'   \item{leaf_mass_mg}{Leaf dry mass in mg (species median).}
#'   \item{sla_mm2_mg}{Specific leaf area in mm\eqn{^2}/mg (species median).}
#'   \item{clonal_growth_organ}{Most frequent primary clonal growth organ
#'     (epigeogeneous stems, root-splitters, bulbs, ...).}
#'   \item{floating_capacity_1week_pct}{Percentage of diaspores still floating
#'     after one week (species median).}
#' }
#'
#' @details
#' Source: LEDA Traitbase (Kleyer et al. 2008).
#' Coverage: ~12,500 NW European plant taxa. `cols = "all"` adds the remaining
#' LEDA traits and, for each, a `<col>_source` column of the references behind
#' the value (resolve with [cite()] and `source = "leda"`).
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
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Arrhenatherum elatius") |>
#'   add_leda()
#'
#' options(old)
#'
#' @export
add_leda <- function(x, cols = NULL, verbose = TRUE) {
  col_map <- c(
    raunkiaer_life_form  = "raunkiaer_life_form",
    raunkiaer_variable   = "raunkiaer_variable",
    dispersal_type       = "dispersal_type",
    terminal_velocity_ms = "terminal_velocity_ms",
    seed_mass_mg         = "leda_seed_mass_mg",
    canopy_height_m      = "canopy_height_m",
    leaf_mass_mg         = "leaf_mass_mg",
    sla_mm2_mg           = "sla_mm2_mg",
    clonal_growth_organ  = "clonal_growth_organ",
    floating_capacity_1week_pct = "floating_capacity_1week_pct"
  )
  enrich_simple(
    x,
    enrichment_name = "leda",
    col_map         = col_map,
    source_label    = "LEDA Traitbase",
    cols            = cols,
    verbose         = verbose
  )
}

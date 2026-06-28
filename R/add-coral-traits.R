#' Add scleractinian coral traits (Coral Trait Database)
#'
#' Joins species-level coral functional traits to a [taxify()] result by looking
#' up `accepted_name`. Values are aggregated from the long-format Coral Trait
#' Database (numeric traits by median, categorical traits by mode).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{coral_symbiotic_state}{Zooxanthellate / azooxanthellate.}
#'   \item{coral_growth_form}{Typical growth form (massive/branching/...).}
#'   \item{coral_coloniality}{Colonial / solitary.}
#'   \item{coral_substrate_attachment}{Attached / unattached.}
#'   \item{coral_sexual_system}{Hermaphrodite / gonochore.}
#'   \item{coral_larval_development_mode}{Spawner / brooder.}
#'   \item{coral_symbiont_clade}{Symbiodinium clade.}
#'   \item{coral_corallite_width_max_mm}{Maximum corallite width (mm).}
#'   \item{coral_colony_max_diameter_cm}{Maximum colony diameter (cm).}
#'   \item{coral_growth_rate_mm_yr}{Linear extension rate (mm/year).}
#'   \item{coral_depth_lower_m}{Lower depth limit (m).}
#'   \item{coral_depth_upper_m}{Upper depth limit (m).}
#'   \item{coral_skeletal_density_g_cm3}{Skeletal density (g/cm3).}
#' }
#'
#' @details
#' Source: Coral Trait Database (Madin et al. 2016, Scientific Data, CC BY 4.0).
#' Coverage: ~1.5k coral species.
#'
#' @references
#' Madin JS et al. (2016) The Coral Trait Database, a curated database of trait
#' information for coral species from the global oceans. Scientific Data
#' 3:160017. \doi{10.1038/sdata.2016.17}
#'
#' @examples
#' \donttest{
#' taxify("Acropora millepora", backend = "gbif") |>
#'   add_coral_traits()
#' }
#'
#' @export
add_coral_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    coral_symbiotic_state         = "symbiotic_state",
    coral_growth_form             = "growth_form",
    coral_coloniality             = "coloniality",
    coral_substrate_attachment    = "substrate_attachment",
    coral_sexual_system           = "sexual_system",
    coral_larval_development_mode = "larval_development_mode",
    coral_symbiont_clade          = "symbiont_clade",
    coral_corallite_width_max_mm  = "corallite_width_max_mm",
    coral_colony_max_diameter_cm  = "colony_max_diameter_cm",
    coral_growth_rate_mm_yr       = "growth_rate_mm_yr",
    coral_depth_lower_m           = "depth_lower_m",
    coral_depth_upper_m           = "depth_upper_m",
    coral_skeletal_density_g_cm3  = "skeletal_density_g_cm3"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  na_types[c("coral_corallite_width_max_mm", "coral_colony_max_diameter_cm",
             "coral_growth_rate_mm_yr", "coral_depth_lower_m",
             "coral_depth_upper_m", "coral_skeletal_density_g_cm3")] <-
    list(NA_real_)
  enrich_simple(
    x,
    enrichment_name = "coral_traits",
    col_map         = col_map,
    source_label    = "Coral Trait Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

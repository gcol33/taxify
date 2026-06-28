#' Add plant traits (BIEN)
#'
#' Joins BIEN plant functional traits to a [taxify()] result by looking up
#' `accepted_name`. Values are species-level aggregates of public-access BIEN
#' records (numeric by median, categorical by mode).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{bien_plant_height_m}{Whole-plant height (m).}
#'   \item{bien_max_plant_height_m}{Maximum whole-plant height (m).}
#'   \item{bien_dbh_cm}{Diameter at breast height (cm).}
#'   \item{bien_sla_mm2_mg}{Leaf area per leaf dry mass (SLA).}
#'   \item{bien_leaf_area_mm2}{Leaf area.}
#'   \item{bien_leaf_dry_mass_mg}{Leaf dry mass.}
#'   \item{bien_leaf_n_per_dry_mass}{Leaf nitrogen per dry mass.}
#'   \item{bien_leaf_p_per_dry_mass}{Leaf phosphorus per dry mass.}
#'   \item{bien_leaf_thickness_mm}{Leaf thickness.}
#'   \item{bien_seed_mass_mg}{Seed mass.}
#'   \item{bien_wood_density_g_cm3}{Stem wood density (g/cm3).}
#'   \item{bien_leaf_lifespan}{Leaf life span.}
#'   \item{bien_growth_form}{Whole-plant growth form.}
#'   \item{bien_woodiness}{Whole-plant woodiness.}
#'   \item{bien_dispersal_syndrome}{Whole-plant dispersal syndrome.}
#'   \item{bien_flower_color}{Flower colour.}
#' }
#'
#' @details
#' Source: BIEN (Botanical Information and Ecology Network; Maitner et al. 2018,
#' Methods Ecol Evol, CC BY). Coverage: tens of thousands of vascular plant
#' species.
#'
#' @references
#' Maitner BS et al. (2018) The BIEN R package: A tool to access the Botanical
#' Information and Ecology Network (BIEN) database. Methods in Ecology and
#' Evolution 9:373-379. \doi{10.1111/2041-210X.12861}
#'
#' @examples
#' \donttest{
#' taxify("Quercus alba", backend = "gbif") |>
#'   add_bien()
#' }
#'
#' @export
add_bien <- function(x, verbose = TRUE) {
  col_map <- c(
    bien_plant_height_m      = "plant_height_m",
    bien_max_plant_height_m  = "max_plant_height_m",
    bien_dbh_cm              = "dbh_cm",
    bien_sla_mm2_mg          = "sla_mm2_mg",
    bien_leaf_area_mm2       = "leaf_area_mm2",
    bien_leaf_dry_mass_mg    = "leaf_dry_mass_mg",
    bien_leaf_n_per_dry_mass = "leaf_n_per_dry_mass",
    bien_leaf_p_per_dry_mass = "leaf_p_per_dry_mass",
    bien_leaf_thickness_mm   = "leaf_thickness_mm",
    bien_seed_mass_mg        = "seed_mass_mg",
    bien_wood_density_g_cm3   = "wood_density_g_cm3",
    bien_leaf_lifespan       = "leaf_lifespan",
    bien_growth_form         = "growth_form",
    bien_woodiness           = "woodiness",
    bien_dispersal_syndrome  = "dispersal_syndrome",
    bien_flower_color        = "flower_color"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("bien_growth_form", "bien_woodiness", "bien_dispersal_syndrome",
             "bien_flower_color")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "bien",
    col_map         = col_map,
    source_label    = "BIEN",
    na_types        = na_types,
    verbose         = verbose
  )
}

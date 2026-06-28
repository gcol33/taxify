#' Add turtle traits (CheloniansTraits)
#'
#' Joins species-level turtle and tortoise traits to a [taxify()] result by
#' looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{chelonian_carapace_length_mm}{Maximum straight-line carapace length
#'     (mm).}
#'   \item{chelonian_max_mass_g}{Maximum body mass (g).}
#'   \item{chelonian_clutch_size_mean}{Mean clutch size (count).}
#'   \item{chelonian_clutch_size_max}{Maximum clutch size (count).}
#'   \item{chelonian_clutches_per_year}{Clutches per year (count).}
#'   \item{chelonian_incubation_d}{Incubation period (days).}
#'   \item{chelonian_age_maturity_y}{Age at sexual maturity (years).}
#'   \item{chelonian_max_lifespan_y}{Maximum lifespan (years).}
#'   \item{chelonian_range_size_km2}{Range size (km2).}
#'   \item{chelonian_diet}{Diet (herbivorous/carnivorous/omnivorous).}
#'   \item{chelonian_activity_time}{Activity time.}
#'   \item{chelonian_microhabitat}{Microhabitat (aquatic/terrestrial/...).}
#'   \item{chelonian_habitat_type}{Habitat type.}
#'   \item{chelonian_shell_type}{Shell type (hardshell/softshell).}
#' }
#'
#' @details
#' Source: CheloniansTraits (Wang et al. 2025, figshare, CC BY 4.0).
#' Coverage: 358 turtle and tortoise species. Numeric values reported as
#' "min-max" ranges in the source are reduced to their midpoint.
#'
#' @references
#' Wang Y et al. (2025) CheloniansTraits: a comprehensive trait database of
#' global turtles and tortoises. figshare.
#' \doi{10.6084/m9.figshare.28828241}
#'
#' @examples
#' \donttest{
#' taxify("Chelonia mydas", backend = "gbif") |>
#'   add_chelonians()
#' }
#'
#' @export
add_chelonians <- function(x, verbose = TRUE) {
  col_map <- c(
    chelonian_carapace_length_mm = "carapace_length_mm",
    chelonian_max_mass_g         = "max_mass_g",
    chelonian_clutch_size_mean   = "clutch_size_mean",
    chelonian_clutch_size_max    = "clutch_size_max",
    chelonian_clutches_per_year  = "clutches_per_year",
    chelonian_incubation_d       = "incubation_d",
    chelonian_age_maturity_y     = "age_maturity_y",
    chelonian_max_lifespan_y     = "max_lifespan_y",
    chelonian_range_size_km2     = "range_size_km2",
    chelonian_diet               = "diet",
    chelonian_activity_time      = "activity_time",
    chelonian_microhabitat       = "microhabitat",
    chelonian_habitat_type       = "habitat_type",
    chelonian_shell_type         = "shell_type"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("chelonian_diet", "chelonian_activity_time",
             "chelonian_microhabitat", "chelonian_habitat_type",
             "chelonian_shell_type")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "chelonians",
    col_map         = col_map,
    source_label    = "CheloniansTraits",
    na_types        = na_types,
    verbose         = verbose
  )
}

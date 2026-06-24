#' Add mammal life-history traits (PanTHERIA)
#'
#' Joins PanTHERIA mammal life-history and ecological traits to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{pantheria_body_mass_g}{Adult body mass in grams.}
#'   \item{longevity_mo}{Maximum longevity in months.}
#'   \item{litter_size}{Litter size (mean).}
#'   \item{gestation_d}{Gestation length in days.}
#'   \item{weaning_d}{Weaning age in days.}
#'   \item{home_range_km2}{Home range size in km\eqn{^2}.}
#'   \item{diet_breadth}{Diet breadth (number of diet categories).}
#'   \item{habitat_breadth}{Habitat breadth (number of habitat types).}
#' }
#'
#' @details
#' Source: PanTHERIA (Jones et al. 2009, Ecological Archives, CC0).
#' Coverage: ~5.4k mammal species. Mammals only.
#'
#' @references
#' Jones KE et al. (2009) PanTHERIA: a species-level database of life
#' history, ecology, and geography of extant and recently extinct mammals.
#' Ecology 90:2648.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Vulpes vulpes", backend = "gbif") |>
#'   add_pantheria()
#'
#' options(old)
#'
#' @export
add_pantheria <- function(x, verbose = TRUE) {
  col_map <- c(
    pantheria_body_mass_g = "body_mass_g",
    longevity_mo          = "longevity_mo",
    litter_size           = "litter_size",
    gestation_d           = "gestation_d",
    weaning_d             = "weaning_d",
    home_range_km2        = "home_range_km2",
    diet_breadth          = "diet_breadth",
    habitat_breadth       = "habitat_breadth"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "pantheria",
    col_map         = col_map,
    source_label    = "PanTHERIA",
    na_types        = na_types,
    verbose         = verbose
  )
}

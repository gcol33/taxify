#' Add bird traits (BIRDBASE)
#'
#' Joins BIRDBASE biogeography, conservation and life-history traits to a
#' [taxify()] result by looking up `accepted_name`. Traits redundant with
#' [add_avonet()] morphology are not carried.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{birdbase_iucn_status}{IUCN Red List category.}
#'   \item{birdbase_realm}{Biogeographic realm.}
#'   \item{birdbase_latitudinal_zone}{Latitudinal zone (1 tropical to 5).}
#'   \item{birdbase_island_endemic}{Island-restricted breeding (0/1).}
#'   \item{birdbase_restricted_range}{Restricted-range species (0/1).}
#'   \item{birdbase_elevation_min_m}{Lower elevation limit (m).}
#'   \item{birdbase_elevation_max_m}{Upper elevation limit (m).}
#'   \item{birdbase_elevation_range_m}{Elevational breadth (m).}
#'   \item{birdbase_primary_habitat}{Primary habitat.}
#'   \item{birdbase_habitat_breadth}{Habitat breadth (number of habitats).}
#'   \item{birdbase_primary_diet}{Primary diet.}
#'   \item{birdbase_diet_breadth}{Diet breadth (number of food types).}
#'   \item{birdbase_specialization_esi}{Ecological specialization index.}
#'   \item{birdbase_clutch_min}{Minimum clutch size (eggs).}
#'   \item{birdbase_clutch_max}{Maximum clutch size (eggs).}
#'   \item{birdbase_nest_type}{Nest architecture.}
#'   \item{birdbase_flightlessness}{Volancy (yes/no/partial).}
#' }
#'
#' @details
#' Source: BIRDBASE (Sekercioglu et al. 2025, figshare, CC BY 4.0).
#' Coverage: ~11.6k bird species.
#'
#' @references
#' Sekercioglu CH et al. (2025) BIRDBASE: a global database of bird ecological
#' and life-history traits. Scientific Data.
#' \doi{10.1038/s41597-025-05615-3}
#'
#' @examples
#' \donttest{
#' taxify("Struthio camelus", backend = "gbif") |>
#'   add_birdbase()
#' }
#'
#' @export
add_birdbase <- function(x, verbose = TRUE) {
  col_map <- c(
    birdbase_iucn_status        = "iucn_status",
    birdbase_realm              = "realm",
    birdbase_latitudinal_zone   = "latitudinal_zone",
    birdbase_island_endemic     = "island_endemic",
    birdbase_restricted_range   = "restricted_range",
    birdbase_elevation_min_m    = "elevation_min_m",
    birdbase_elevation_max_m    = "elevation_max_m",
    birdbase_elevation_range_m  = "elevation_range_m",
    birdbase_primary_habitat    = "primary_habitat",
    birdbase_habitat_breadth    = "habitat_breadth",
    birdbase_primary_diet       = "primary_diet",
    birdbase_diet_breadth       = "diet_breadth",
    birdbase_specialization_esi = "specialization_esi",
    birdbase_clutch_min         = "clutch_min",
    birdbase_clutch_max         = "clutch_max",
    birdbase_nest_type          = "nest_type",
    birdbase_flightlessness     = "flightlessness"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("birdbase_iucn_status", "birdbase_realm",
             "birdbase_primary_habitat", "birdbase_primary_diet",
             "birdbase_nest_type", "birdbase_flightlessness")] <-
    list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "birdbase",
    col_map         = col_map,
    source_label    = "BIRDBASE",
    na_types        = na_types,
    verbose         = verbose
  )
}

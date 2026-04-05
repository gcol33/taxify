#' Add arthropod life-history traits (NW European Arthropods)
#'
#' Joins the Northwestern European Arthropod Life Histories dataset to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{arthropod_body_size_mm}{Body size in mm.}
#'   \item{arthropod_dispersal}{Dispersal ability (0--1 ratio within order).}
#'   \item{arthropod_voltinism}{Mean number of generations per year.}
#'   \item{arthropod_fecundity}{Fecundity (number of eggs/offspring).}
#'   \item{arthropod_development_d}{Development time in days.}
#'   \item{arthropod_lifespan_d}{Adult lifespan in days.}
#'   \item{arthropod_thermal_mean}{Mean thermal niche (degrees C).}
#'   \item{arthropod_diurnality}{Activity period (diurnal/nocturnal/both).}
#'   \item{arthropod_feeding_guild}{Feeding guild of adult.}
#'   \item{arthropod_trophic_range}{Trophic range of adult (specialist/generalist).}
#' }
#'
#' @details
#' Source: Logghe et al. (2025, CC BY-NC). Coverage: ~4.9k arthropod
#' species from NW Europe across 10 orders (Coleoptera, Hemiptera,
#' Orthoptera, Araneae, Diptera, Hymenoptera, Lepidoptera, etc.).
#'
#' @references
#' Logghe A et al. (2025) An in-depth dataset of northwestern European
#' arthropod life histories and ecological traits. Biodiversity Data
#' Journal 13:e146785.
#'
#' @examples
#' \dontrun{
#' taxify("Abax parallelepipedus") |>
#'   add_arthropod_traits()
#' }
#'
#' @export
add_arthropod_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    arthropod_body_size_mm  = "body_size_mm",
    arthropod_dispersal     = "dispersal",
    arthropod_voltinism     = "voltinism",
    arthropod_fecundity     = "fecundity",
    arthropod_development_d = "development_d",
    arthropod_lifespan_d    = "lifespan_d",
    arthropod_thermal_mean  = "thermal_mean",
    arthropod_diurnality    = "diurnality",
    arthropod_feeding_guild = "feeding_guild",
    arthropod_trophic_range = "trophic_range"
  )
  na_types <- list(
    arthropod_body_size_mm  = NA_real_,
    arthropod_dispersal     = NA_real_,
    arthropod_voltinism     = NA_real_,
    arthropod_fecundity     = NA_real_,
    arthropod_development_d = NA_real_,
    arthropod_lifespan_d    = NA_real_,
    arthropod_thermal_mean  = NA_real_,
    arthropod_diurnality    = NA_character_,
    arthropod_feeding_guild = NA_character_,
    arthropod_trophic_range = NA_character_
  )
  enrich_simple(
    x,
    enrichment_name = "arthropod_traits",
    col_map         = col_map,
    source_label    = "NW European Arthropods",
    na_types        = na_types,
    verbose         = verbose
  )
}

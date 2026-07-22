#' Add arthropod life-history traits (NW European Arthropods)
#'
#' Joins the Northwestern European Arthropod Life Histories dataset to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
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
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Abax parallelepipedus", backbone = "gbif") |>
#'   add_arthropod_traits()
#'
#' options(old)
#'
#' @export
add_arthropod_traits <- function(x, cols = NULL, verbose = TRUE) {
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
  enrich_simple(
    x,
    enrichment_name = "arthropod_traits",
    col_map         = col_map,
    source_label    = "NW European Arthropods",
    cols            = cols,
    verbose         = verbose
  )
}

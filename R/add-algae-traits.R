#' Add macroalgal functional traits (AlgaeTraits)
#'
#' Joins AlgaeTraits (Vranken et al. 2023) macroalgal functional traits to a
#' [taxify()] result by looking up `accepted_name`. AlgaeTraits provides
#' morphological, ecological, and life-history traits for European seaweeds.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{algae_body_size_cm}{Maximum body size in centimetres.}
#'   \item{algae_growth_form}{Growth form / body shape (e.g., filamentous,
#'     foliose, crustose).}
#'   \item{algae_calcification}{Calcification type (e.g., uncalcified,
#'     articulated, encrusting).}
#'   \item{algae_life_span}{Life span category (annual, perennial, etc.).}
#'   \item{algae_tidal_zone}{Tidal zonation (e.g., supralittoral, eulittoral,
#'     sublittoral).}
#'   \item{algae_wave_exposure}{Wave exposure tolerance (sheltered, moderately
#'     exposed, exposed).}
#'   \item{algae_environment}{Habitat environment (marine, brackish, freshwater).}
#'   \item{algae_substrate}{Environmental position / substrate type.}
#' }
#'
#' @details
#' Source: AlgaeTraits (Vranken et al. 2023, VLIZ Marine Data Archive,
#' CC BY 4.0). Coverage: ~1,745 European macroalgae species.
#'
#' @references
#' Vranken S et al. (2023) AlgaeTraits: a trait database for (European)
#' seaweeds. Earth System Science Data 15:2711-2754.
#' doi:10.5194/essd-15-2711-2023
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Fucus vesiculosus", backend = "gbif") |>
#'   add_algae_traits()
#'
#' options(old)
#'
#' @export
add_algae_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    algae_body_size_cm  = "body_size_cm",
    algae_growth_form   = "growth_form",
    algae_calcification = "calcification",
    algae_life_span     = "life_span",
    algae_tidal_zone    = "tidal_zone",
    algae_wave_exposure = "wave_exposure",
    algae_environment   = "environment",
    algae_substrate     = "substrate"
  )
  na_types <- list(
    algae_body_size_cm  = NA_real_,
    algae_growth_form   = NA_character_,
    algae_calcification = NA_character_,
    algae_life_span     = NA_character_,
    algae_tidal_zone    = NA_character_,
    algae_wave_exposure = NA_character_,
    algae_environment   = NA_character_,
    algae_substrate     = NA_character_
  )
  enrich_simple(
    x,
    enrichment_name = "algae_traits",
    col_map         = col_map,
    source_label    = "AlgaeTraits",
    na_types        = na_types,
    verbose         = verbose
  )
}

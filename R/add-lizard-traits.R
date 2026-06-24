#' Add lizard life-history and ecological traits (Meiri 2018)
#'
#' Joins lizard trait data from Meiri (2018) to a [taxify()] result by
#' looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{lizard_body_mass_g}{Body mass in grams.}
#'   \item{lizard_svl_mm}{Snout-vent length in mm.}
#'   \item{lizard_tail_length_mm}{Tail length in mm.}
#'   \item{lizard_clutch_size}{Clutch size.}
#'   \item{lizard_clutch_frequency}{Clutches per year.}
#'   \item{lizard_longevity_yr}{Maximum longevity in years.}
#'   \item{lizard_diet}{Diet category.}
#'   \item{lizard_habitat}{Habitat type.}
#'   \item{lizard_activity_time}{Activity time (diurnal/nocturnal/crepuscular).}
#'   \item{lizard_foraging_mode}{Foraging mode (sit-and-wait/active).}
#' }
#'
#' @details
#' Source: Meiri (2018, Global Ecology and Biogeography, CC BY 4.0).
#' Coverage: ~6,600 lizard species. Lizards only.
#'
#' @references
#' Meiri S (2018) Traits of lizards of the world: Variation around a
#' successful evolutionary design. Global Ecology and Biogeography
#' 27:1168-1172.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Pogona vitticeps", backend = "gbif") |>
#'   add_lizard_traits()
#'
#' options(old)
#'
#' @export
add_lizard_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    lizard_body_mass_g      = "body_mass_g",
    lizard_svl_mm           = "svl_mm",
    lizard_tail_length_mm   = "tail_length_mm",
    lizard_clutch_size      = "clutch_size",
    lizard_clutch_frequency = "clutch_frequency",
    lizard_longevity_yr     = "longevity_yr",
    lizard_diet             = "diet",
    lizard_habitat          = "habitat",
    lizard_activity_time    = "activity_time",
    lizard_foraging_mode    = "foraging_mode"
  )
  na_types <- list(
    lizard_body_mass_g      = NA_real_,
    lizard_svl_mm           = NA_real_,
    lizard_tail_length_mm   = NA_real_,
    lizard_clutch_size      = NA_real_,
    lizard_clutch_frequency = NA_real_,
    lizard_longevity_yr     = NA_real_,
    lizard_diet             = NA_character_,
    lizard_habitat          = NA_character_,
    lizard_activity_time    = NA_character_,
    lizard_foraging_mode    = NA_character_
  )
  enrich_simple(
    x,
    enrichment_name = "lizard_traits",
    col_map         = col_map,
    source_label    = "Meiri (2018) lizard traits",
    na_types        = na_types,
    verbose         = verbose
  )
}

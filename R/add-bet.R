#' Add bryophyte traits (Bryophytes of Europe Traits)
#'
#' Joins species-level bryophyte traits to a [taxify()] result by looking up
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{bet_growth_form}{Growth form (acrocarpous/pleurocarpous/thalloid/...).}
#'   \item{bet_life_form}{Life form (cushion/mat/turf/weft/...).}
#'   \item{bet_life_strategy}{Life strategy (During).}
#'   \item{bet_sexual_condition}{Sexual condition (monoicous/dioicous).}
#'   \item{bet_shoot_size_mm}{Mean shoot size (mm).}
#'   \item{bet_generation_length_y}{Generation length (years).}
#'   \item{bet_spore_diameter_um}{Mean spore diameter (micrometres).}
#'   \item{bet_ind_light}{Ellenberg light indicator value.}
#'   \item{bet_ind_temperature}{Ellenberg temperature indicator value.}
#'   \item{bet_ind_moisture}{Ellenberg moisture indicator value.}
#'   \item{bet_ind_reaction_ph}{Ellenberg reaction (pH) indicator value.}
#'   \item{bet_ind_nitrogen}{Ellenberg nitrogen indicator value.}
#'   \item{bet_substrate_soil}{Occurs on soil (0/1).}
#'   \item{bet_substrate_rock}{Occurs on rock (0/1).}
#'   \item{bet_substrate_bark}{Occurs on bark (0/1).}
#'   \item{bet_substrate_deadwood}{Occurs on deadwood (0/1).}
#'   \item{bet_epiphyte}{Epiphytic (0/1).}
#'   \item{bet_redlist_category}{IUCN European Red List category.}
#' }
#'
#' @details
#' Source: Bryophytes of Europe Traits (van Zuijlen et al. 2023, EnviDat,
#' CC BY-SA 4.0). Coverage: ~1.8k bryophyte species.
#'
#' @references
#' van Zuijlen K et al. (2023) Bryophytes of Europe Traits (BET): a fundamental
#' dataset for European bryophyte ecology. EnviDat.
#' \doi{10.16904/envidat.348}
#'
#' @examples
#' \donttest{
#' taxify("Abietinella abietina", backend = "gbif") |>
#'   add_bet()
#' }
#'
#' @export
add_bet <- function(x, verbose = TRUE) {
  col_map <- c(
    bet_growth_form         = "growth_form",
    bet_life_form           = "life_form",
    bet_life_strategy       = "life_strategy",
    bet_sexual_condition    = "sexual_condition",
    bet_shoot_size_mm       = "shoot_size_mm",
    bet_generation_length_y = "generation_length_y",
    bet_spore_diameter_um   = "spore_diameter_um",
    bet_ind_light           = "ind_light",
    bet_ind_temperature     = "ind_temperature",
    bet_ind_moisture        = "ind_moisture",
    bet_ind_reaction_ph     = "ind_reaction_ph",
    bet_ind_nitrogen        = "ind_nitrogen",
    bet_substrate_soil      = "substrate_soil",
    bet_substrate_rock      = "substrate_rock",
    bet_substrate_bark      = "substrate_bark",
    bet_substrate_deadwood  = "substrate_deadwood",
    bet_epiphyte            = "epiphyte",
    bet_redlist_category    = "redlist_category"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("bet_growth_form", "bet_life_form", "bet_life_strategy",
             "bet_sexual_condition", "bet_redlist_category")] <-
    list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "bet",
    col_map         = col_map,
    source_label    = "Bryophytes of Europe Traits",
    na_types        = na_types,
    verbose         = verbose
  )
}

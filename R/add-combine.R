#' Add mammal traits (COMBINE)
#'
#' Joins COMBINE mammal traits to a [taxify()] result by looking up
#' `accepted_name`. COMBINE is a separate, coalesced mammal trait source; it is
#' offered alongside [add_pantheria()], not as a replacement. Reported (not
#' phylogenetically imputed) values are used.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{combine_adult_mass_g}{Adult body mass (g).}
#'   \item{combine_adult_body_length_mm}{Adult head-body length (mm).}
#'   \item{combine_litter_size_n}{Litter size (count).}
#'   \item{combine_litters_per_year_n}{Litters per year (count).}
#'   \item{combine_max_longevity_d}{Maximum longevity (days).}
#'   \item{combine_gestation_length_d}{Gestation length (days).}
#'   \item{combine_weaning_age_d}{Weaning age (days).}
#'   \item{combine_generation_length_d}{Generation length (days).}
#'   \item{combine_dispersal_km}{Natal dispersal distance (km).}
#'   \item{combine_habitat_breadth_n}{Number of IUCN habitats (count).}
#'   \item{combine_diet_breadth_n}{Number of diet categories (count).}
#'   \item{combine_trophic_level}{Trophic level (1 herbivore, 2 omnivore,
#'     3 carnivore).}
#'   \item{combine_activity_cycle}{Activity cycle (1 nocturnal, 2 cathemeral,
#'     3 diurnal).}
#'   \item{combine_foraging_stratum}{Foraging stratum (G/Ar/A/S/M).}
#'   \item{combine_biogeographical_realm}{Biogeographical realm(s).}
#' }
#'
#' @details
#' Source: COMBINE (Soria et al. 2021, Ecology, CC0). Coverage: ~6.2k mammal
#' species. Keyed on the IUCN 2020 binomial.
#'
#' @references
#' Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic and
#' extrinsic traits. Ecology 102:e03344. \doi{10.1002/ecy.3344}
#'
#' @examples
#' \donttest{
#' taxify("Vulpes vulpes", backend = "gbif") |>
#'   add_combine()
#' }
#'
#' @export
add_combine <- function(x, verbose = TRUE) {
  col_map <- c(
    combine_adult_mass_g         = "adult_mass_g",
    combine_adult_body_length_mm = "adult_body_length_mm",
    combine_litter_size_n        = "litter_size_n",
    combine_litters_per_year_n   = "litters_per_year_n",
    combine_max_longevity_d      = "max_longevity_d",
    combine_gestation_length_d   = "gestation_length_d",
    combine_weaning_age_d        = "weaning_age_d",
    combine_generation_length_d  = "generation_length_d",
    combine_dispersal_km         = "dispersal_km",
    combine_habitat_breadth_n    = "habitat_breadth_n",
    combine_diet_breadth_n       = "diet_breadth_n",
    combine_trophic_level        = "trophic_level",
    combine_activity_cycle       = "activity_cycle",
    combine_foraging_stratum     = "foraging_stratum",
    combine_biogeographical_realm = "biogeographical_realm"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("combine_foraging_stratum",
             "combine_biogeographical_realm")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "combine",
    col_map         = col_map,
    source_label    = "COMBINE",
    na_types        = na_types,
    verbose         = verbose
  )
}

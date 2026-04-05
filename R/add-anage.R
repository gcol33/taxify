#' Add longevity and life-history traits (AnAge)
#'
#' Joins AnAge (Animal Ageing and Longevity Database) traits to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{max_longevity_yr}{Maximum longevity in years.}
#'   \item{anage_body_mass_g}{Adult body mass in grams.}
#'   \item{metabolic_rate_w}{Basal metabolic rate in watts.}
#'   \item{female_maturity_d}{Female age at sexual maturity in days.}
#'   \item{male_maturity_d}{Male age at sexual maturity in days.}
#'   \item{gestation_incubation_d}{Gestation or incubation length in days.}
#'   \item{anage_litter_size}{Litter or clutch size.}
#'   \item{birth_mass_g}{Mass at birth in grams.}
#'   \item{growth_rate}{Growth rate (1/days).}
#'   \item{temperature_k}{Body temperature in Kelvin.}
#' }
#'
#' @details
#' Source: AnAge (de Magalhaes & Costa 2009, CC BY). Coverage: ~4.7k
#' vertebrate species (mammals, birds, reptiles, amphibians, fish).
#'
#' @references
#' de Magalhaes JP, Costa J (2009) A database of vertebrate longevity
#' records and their relation to other life-history traits. Journal of
#' Evolutionary Biology 22:1770-1774.
#'
#' @examples
#' \dontrun{
#' taxify("Vulpes vulpes") |>
#'   add_anage()
#' }
#'
#' @export
add_anage <- function(x, verbose = TRUE) {
  col_map <- c(
    max_longevity_yr       = "max_longevity_yr",
    anage_body_mass_g      = "body_mass_g",
    metabolic_rate_w       = "metabolic_rate_w",
    female_maturity_d      = "female_maturity_d",
    male_maturity_d        = "male_maturity_d",
    gestation_incubation_d = "gestation_incubation_d",
    anage_litter_size      = "litter_size",
    birth_mass_g           = "birth_mass_g",
    growth_rate            = "growth_rate",
    temperature_k          = "temperature_k"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "anage",
    col_map         = col_map,
    source_label    = "AnAge",
    na_types        = na_types,
    verbose         = verbose
  )
}

#' Add amniote life-history traits (Amniote Life History Database)
#'
#' Joins uniform life-history traits for birds, mammals and reptiles to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{amniote_class}{Taxonomic class (Aves/Mammalia/Reptilia).}
#'   \item{amniote_adult_body_mass_g}{Adult body mass (g).}
#'   \item{amniote_no_sex_body_mass_g}{Unsexed adult body mass (g).}
#'   \item{amniote_female_body_mass_g}{Female body mass (g).}
#'   \item{amniote_male_body_mass_g}{Male body mass (g).}
#'   \item{amniote_adult_svl_cm}{Adult snout-vent length (cm).}
#'   \item{amniote_maximum_longevity_y}{Maximum longevity (years).}
#'   \item{amniote_litter_clutch_size}{Litter or clutch size (count).}
#'   \item{amniote_clutches_per_y}{Litters or clutches per year (count).}
#'   \item{amniote_egg_mass_g}{Egg mass (g).}
#'   \item{amniote_incubation_d}{Incubation period (days).}
#'   \item{amniote_female_maturity_d}{Age at female maturity (days).}
#'   \item{amniote_gestation_d}{Gestation length (days).}
#'   \item{amniote_weaning_d}{Weaning age (days).}
#'   \item{amniote_birth_hatching_wt_g}{Birth or hatching weight (g).}
#' }
#'
#' @details
#' Source: Amniote Life History Database (Myhrvold et al. 2015, Ecology, CC0).
#' Coverage: 21,322 species across birds, mammals and reptiles.
#'
#' @references
#' Myhrvold NP et al. (2015) An amniote life-history database to perform
#' comparative analyses with birds, mammals, and reptiles. Ecology 96:3109.
#' \doi{10.1890/15-0846R.1}
#'
#' @examples
#' \donttest{
#' taxify("Accipiter badius", backend = "gbif") |>
#'   add_amniote()
#' }
#'
#' @export
add_amniote <- function(x, verbose = TRUE) {
  col_map <- c(
    amniote_class               = "taxon_class",
    amniote_adult_body_mass_g   = "adult_body_mass_g",
    amniote_no_sex_body_mass_g  = "no_sex_body_mass_g",
    amniote_female_body_mass_g  = "female_body_mass_g",
    amniote_male_body_mass_g    = "male_body_mass_g",
    amniote_adult_svl_cm        = "adult_svl_cm",
    amniote_maximum_longevity_y = "maximum_longevity_y",
    amniote_litter_clutch_size  = "litter_clutch_size",
    amniote_clutches_per_y      = "clutches_per_y",
    amniote_egg_mass_g          = "egg_mass_g",
    amniote_incubation_d        = "incubation_d",
    amniote_female_maturity_d   = "female_maturity_d",
    amniote_gestation_d         = "gestation_d",
    amniote_weaning_d           = "weaning_d",
    amniote_birth_hatching_wt_g = "birth_hatching_wt_g"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[["amniote_class"]] <- NA_character_
  enrich_simple(
    x,
    enrichment_name = "amniote",
    col_map         = col_map,
    source_label    = "Amniote Life History Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

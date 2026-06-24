#' Add diet, foraging, and body mass (EltonTraits 1.0)
#'
#' Joins EltonTraits 1.0 diet composition, foraging strata, body mass,
#' and activity data to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{diet_inv}{Percentage of diet: invertebrates.}
#'   \item{diet_vend}{Percentage of diet: endothermic vertebrates.}
#'   \item{diet_vect}{Percentage of diet: ectothermic vertebrates.}
#'   \item{diet_vfish}{Percentage of diet: fish.}
#'   \item{diet_vunk}{Percentage of diet: unknown vertebrates.}
#'   \item{diet_scav}{Percentage of diet: scavenging.}
#'   \item{diet_fruit}{Percentage of diet: fruit.}
#'   \item{diet_nect}{Percentage of diet: nectar.}
#'   \item{diet_seed}{Percentage of diet: seeds and nuts.}
#'   \item{diet_plantother}{Percentage of diet: other plant material.}
#'   \item{foraging_water}{Percentage of foraging: below water surface.}
#'   \item{foraging_ground}{Percentage of foraging: on ground.}
#'   \item{foraging_understory}{Percentage of foraging: in understory.}
#'   \item{foraging_midhigh}{Percentage of foraging: in mid to high strata.}
#'   \item{foraging_canopy}{Percentage of foraging: in canopy.}
#'   \item{foraging_aerial}{Percentage of foraging: aerial.}
#'   \item{elton_body_mass_g}{Body mass in grams.}
#'   \item{nocturnal}{Nocturnal activity (0 = diurnal, 1 = nocturnal).}
#' }
#'
#' @details
#' Source: EltonTraits 1.0 (Wilman et al. 2014, Figshare, CC0).
#' Coverage: ~15.4k species. Birds and mammals only.
#'
#' @references
#' Wilman H et al. (2014) EltonTraits 1.0: Species-level foraging
#' attributes of the world's birds and mammals. Ecology 95:2027.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Parus major", backend = "gbif") |>
#'   add_elton_traits()
#'
#' options(old)
#'
#' @export
add_elton_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    diet_inv           = "diet_inv",
    diet_vend          = "diet_vend",
    diet_vect          = "diet_vect",
    diet_vfish         = "diet_vfish",
    diet_vunk          = "diet_vunk",
    diet_scav          = "diet_scav",
    diet_fruit         = "diet_fruit",
    diet_nect          = "diet_nect",
    diet_seed          = "diet_seed",
    diet_plantother    = "diet_plantother",
    foraging_water     = "foraging_water",
    foraging_ground    = "foraging_ground",
    foraging_understory = "foraging_understory",
    foraging_midhigh   = "foraging_midhigh",
    foraging_canopy    = "foraging_canopy",
    foraging_aerial    = "foraging_aerial",
    elton_body_mass_g  = "body_mass_g",
    nocturnal          = "nocturnal"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "elton_traits",
    col_map         = col_map,
    source_label    = "EltonTraits 1.0",
    na_types        = na_types,
    verbose         = verbose
  )
}

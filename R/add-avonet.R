#' Add bird morphology and migration (AVONET)
#'
#' Joins AVONET species-level averages for bird morphology, ecology,
#' and migration to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{beak_length}{Beak length in mm (culmen, species mean).}
#'   \item{beak_depth}{Beak depth in mm (species mean).}
#'   \item{wing_length}{Wing length in mm (species mean).}
#'   \item{tail_length}{Tail length in mm (species mean).}
#'   \item{tarsus_length}{Tarsus length in mm (species mean).}
#'   \item{avonet_body_mass_g}{Body mass in grams (species mean).}
#'   \item{hand_wing_index}{Hand-wing index (pointedness, species mean).}
#'   \item{habitat}{Primary habitat classification.}
#'   \item{trophic_level}{Trophic level classification.}
#'   \item{trophic_niche}{Trophic niche classification.}
#'   \item{migration}{Migration strategy: `"sedentary"`, `"partial"`,
#'     or `"full"`.}
#' }
#'
#' @details
#' Source: AVONET (Tobias et al. 2022, Figshare, CC BY 4.0).
#' Coverage: ~11k bird species. Birds only.
#'
#' @references
#' Tobias JA et al. (2022) AVONET: morphological, ecological and
#' geographical data for all birds. Ecology Letters 25:581-597.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Parus major", backend = "gbif") |>
#'   add_avonet()
#'
#' options(old)
#'
#' @export
add_avonet <- function(x, verbose = TRUE) {
  col_map <- c(
    beak_length       = "beak_length",
    beak_depth        = "beak_depth",
    wing_length       = "wing_length",
    tail_length       = "tail_length",
    tarsus_length     = "tarsus_length",
    avonet_body_mass_g = "body_mass_g",
    hand_wing_index   = "hand_wing_index",
    habitat           = "habitat",
    trophic_level     = "trophic_level",
    trophic_niche     = "trophic_niche",
    migration         = "migration"
  )
  na_types <- list(
    beak_length       = NA_real_,
    beak_depth        = NA_real_,
    wing_length       = NA_real_,
    tail_length       = NA_real_,
    tarsus_length     = NA_real_,
    avonet_body_mass_g = NA_real_,
    hand_wing_index   = NA_real_
  )
  enrich_simple(
    x,
    enrichment_name = "avonet",
    col_map         = col_map,
    source_label    = "AVONET",
    na_types        = na_types,
    verbose         = verbose
  )
}

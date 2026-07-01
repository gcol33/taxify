#' Add aquatic-life traits (SeaLifeBase)
#'
#' Joins SeaLifeBase morphological and ecological traits to a [taxify()] result
#' by looking up `accepted_name`. SeaLifeBase is the non-fish companion to
#' FishBase: molluscs, crustaceans, echinoderms, marine mammals, reptiles and
#' other aquatic organisms. For fishes, use [add_fishbase()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{sb_body_length_cm}{Maximum body length in centimetres.}
#'   \item{sb_body_mass_g}{Body mass in grams where available.}
#'   \item{sb_trophic_level}{Trophic level.}
#'   \item{sb_depth_min_m}{Minimum depth in metres.}
#'   \item{sb_depth_max_m}{Maximum depth in metres.}
#'   \item{sb_vulnerability}{Vulnerability index (0--100).}
#'   \item{sb_habitat}{Habitat type (e.g. benthic, pelagic).}
#'   \item{sb_importance}{Commercial importance category.}
#' }
#'
#' @details
#' Source: SeaLifeBase via rfishbase (Palomares & Pauly, CC BY-NC 4.0).
#' Non-fish aquatic life only.
#'
#' The build-from-source fallback requires the \pkg{rfishbase} package
#' (available on CRAN). Pre-built `.vtr` files do not require rfishbase.
#'
#' @references
#' Palomares MLD, Pauly D (eds.) (2024) SeaLifeBase. World Wide Web electronic
#' publication, \url{https://www.sealifebase.org}.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Octopus vulgaris", backend = "gbif") |>
#'   add_sealifebase()
#'
#' options(old)
#'
#' @export
add_sealifebase <- function(x, verbose = TRUE) {
  col_map <- c(
    sb_body_length_cm = "body_length_cm",
    sb_body_mass_g    = "body_mass_g",
    sb_trophic_level  = "trophic_level",
    sb_depth_min_m    = "depth_min_m",
    sb_depth_max_m    = "depth_max_m",
    sb_vulnerability  = "vulnerability",
    sb_habitat        = "habitat",
    sb_importance     = "importance"
  )
  na_types <- stats::setNames(
    c(
      rep(list(NA_real_), 6L),
      list(NA_character_),
      list(NA_character_)
    ),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "sealifebase",
    col_map         = col_map,
    source_label    = "SeaLifeBase",
    na_types        = na_types,
    verbose         = verbose
  )
}

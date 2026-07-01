#' Add fish traits (FishBase)
#'
#' Joins FishBase morphological and ecological traits to a [taxify()] result
#' by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{fb_body_length_cm}{Maximum body length in centimetres.}
#'   \item{fb_body_mass_g}{Body mass in grams (estimated from length-weight
#'     relationships where available).}
#'   \item{fb_trophic_level}{Trophic level.}
#'   \item{fb_depth_min_m}{Minimum depth in metres.}
#'   \item{fb_depth_max_m}{Maximum depth in metres.}
#'   \item{fb_vulnerability}{Vulnerability index (0--100).}
#'   \item{fb_habitat}{Habitat type (e.g. demersal, pelagic).}
#'   \item{fb_importance}{Commercial importance category.}
#' }
#'
#' @details
#' Source: FishBase via rfishbase (Froese & Pauly, CC BY-NC 4.0).
#' Coverage: ~35k fish species. Fishes only.
#'
#' The build-from-source fallback requires the \pkg{rfishbase} package
#' (available on CRAN). Pre-built `.vtr` files do not require rfishbase.
#'
#' @references
#' Froese R, Pauly D (eds.) (2024) FishBase. World Wide Web electronic
#' publication, \url{https://www.fishbase.org}.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Gadus morhua", backend = "gbif") |>
#'   add_fishbase()
#'
#' options(old)
#'
#' @export
add_fishbase <- function(x, verbose = TRUE) {
  col_map <- c(
    fb_body_length_cm = "body_length_cm",
    fb_body_mass_g    = "body_mass_g",
    fb_trophic_level  = "trophic_level",
    fb_depth_min_m    = "depth_min_m",
    fb_depth_max_m    = "depth_max_m",
    fb_vulnerability  = "vulnerability",
    fb_habitat        = "habitat",
    fb_importance     = "importance"
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
    enrichment_name = "fishbase",
    col_map         = col_map,
    source_label    = "FishBase",
    na_types        = na_types,
    verbose         = verbose
  )
}

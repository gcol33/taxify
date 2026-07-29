#' Add fish traits (FishBase)
#'
#' Joins FishBase morphological and ecological traits to a [taxify()] result
#' by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{fb_body_length_cm}{Maximum body length in centimetres.}
#'   \item{fb_body_mass_g}{Maximum published weight in grams (FishBase
#'     \code{SPECIES.Weight}). This is a record maximum, not a typical or
#'     adult-mean mass.}
#'   \item{fb_trophic_level}{Trophic level.}
#'   \item{fb_depth_min_m}{Minimum depth in metres.}
#'   \item{fb_depth_max_m}{Maximum depth in metres.}
#'   \item{fb_vulnerability}{Vulnerability index (0--100).}
#'   \item{fb_habitat}{Habitat type (e.g. demersal, pelagic).}
#'   \item{fb_importance}{Commercial importance category.}
#'   \item{fb_lw_a}{Coefficient \code{a} of the length-weight relationship
#'     \code{W = a * L^b} (weight in g, length in cm of type \code{fb_lw_type}),
#'     from FishBase's POPLW table.}
#'   \item{fb_lw_b}{Exponent \code{b} of the length-weight relationship.}
#'   \item{fb_lw_type}{Length convention the coefficients were fitted against
#'     (\code{TL} total, \code{SL} standard, \code{FL} fork, \code{WD} width,
#'     ...). Chosen to match the species' maximum-length type where recorded, so
#'     it applies to \code{fb_body_length_cm}. Applying a coefficient to a
#'     different length type is a silent error.}
#'   \item{fb_lw_method}{How the fit was obtained (e.g. "type I linear
#'     regression", "single L-W pair with b=3").}
#'   \item{fb_lw_sex}{Sex the fit applies to (unsexed, mixed, female, male,
#'     juvenile).}
#'   \item{fb_lw_n}{Sample size the fit was based on.}
#'   \item{fb_lw_r2}{Coefficient of determination (\code{r^2}) of the fit.}
#' }
#'
#' @details
#' Source: FishBase via rfishbase (Froese & Pauly, CC BY-NC 4.0).
#' Coverage: ~35k fish species. Fishes only.
#'
#' The \code{fb_lw_*} columns give one representative length-weight fit per
#' species from the POPLW table, so a length can be converted to a mass where
#' \code{fb_body_mass_g} (a record maximum) is not what you want. FishBase's
#' Bayesian congeneric estimates are not included; \code{fb_lw_*} are measured
#' fits.
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
#' taxify("Gadus morhua", backbone = "gbif") |>
#'   add_fishbase()
#'
#' options(old)
#'
#' @export
add_fishbase <- function(x, cols = NULL, verbose = TRUE) {
  col_map <- c(
    fb_body_length_cm = "body_length_cm",
    fb_body_mass_g    = "body_mass_g",
    fb_trophic_level  = "trophic_level",
    fb_depth_min_m    = "depth_min_m",
    fb_depth_max_m    = "depth_max_m",
    fb_vulnerability  = "vulnerability",
    fb_habitat        = "habitat",
    fb_importance     = "importance",
    fb_lw_a           = "lw_a",
    fb_lw_b           = "lw_b",
    fb_lw_type        = "lw_type",
    fb_lw_method      = "lw_method",
    fb_lw_sex         = "lw_sex",
    fb_lw_n           = "lw_n",
    fb_lw_r2          = "lw_r2"
  )
  enrich_simple(
    x,
    enrichment_name = "fishbase",
    col_map         = col_map,
    source_label    = "FishBase",
    cols            = cols,
    verbose         = verbose
  )
}

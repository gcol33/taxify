#' Add aquatic-life traits (SeaLifeBase)
#'
#' Joins SeaLifeBase morphological and ecological traits to a [taxify()] result
#' by looking up `accepted_name`. SeaLifeBase is the non-fish companion to
#' FishBase: molluscs, crustaceans, echinoderms, marine mammals, reptiles and
#' other aquatic organisms. For fishes, use [add_fishbase()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{sb_body_length_cm}{Maximum body length in centimetres.}
#'   \item{sb_body_mass_g}{Maximum published weight in grams (SeaLifeBase
#'     \code{SPECIES.Weight}). This is a record maximum, not a typical or
#'     adult-mean mass.}
#'   \item{sb_trophic_level}{Trophic level.}
#'   \item{sb_depth_min_m}{Minimum depth in metres.}
#'   \item{sb_depth_max_m}{Maximum depth in metres.}
#'   \item{sb_vulnerability}{Vulnerability index (0--100).}
#'   \item{sb_habitat}{Habitat type (e.g. benthic, pelagic).}
#'   \item{sb_importance}{Commercial importance category.}
#'   \item{sb_lw_a}{Coefficient \code{a} of the length-weight relationship
#'     \code{W = a * L^b} (weight in g, length in cm of type \code{sb_lw_type}),
#'     from SeaLifeBase's POPLW table.}
#'   \item{sb_lw_b}{Exponent \code{b} of the length-weight relationship.}
#'   \item{sb_lw_type}{Length convention the coefficients were fitted against
#'     (\code{TL} total, \code{SL} standard, \code{WD} width, ...). Chosen to
#'     match the species' maximum-length type where recorded, so it applies to
#'     \code{sb_body_length_cm}. Applying a coefficient to a different length
#'     type is a silent error.}
#'   \item{sb_lw_method}{How the fit was obtained (e.g. "type I linear
#'     regression", "single L-W pair with b=3").}
#'   \item{sb_lw_sex}{Sex the fit applies to (unsexed, mixed, female, male,
#'     juvenile).}
#'   \item{sb_lw_n}{Sample size the fit was based on.}
#'   \item{sb_lw_r2}{Coefficient of determination (\code{r^2}) of the fit.}
#' }
#'
#' @details
#' Source: SeaLifeBase via rfishbase (Palomares & Pauly, CC BY-NC 4.0).
#' Non-fish aquatic life only.
#'
#' The \code{sb_lw_*} columns give one representative length-weight fit per
#' species from the POPLW table, so a length can be converted to a mass where
#' \code{sb_body_mass_g} (a record maximum) is not what you want.
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
#' taxify("Octopus vulgaris", backbone = "gbif") |>
#'   add_sealifebase()
#'
#' options(old)
#'
#' @export
add_sealifebase <- function(x, cols = NULL, verbose = TRUE) {
  col_map <- c(
    sb_body_length_cm = "body_length_cm",
    sb_body_mass_g    = "body_mass_g",
    sb_trophic_level  = "trophic_level",
    sb_depth_min_m    = "depth_min_m",
    sb_depth_max_m    = "depth_max_m",
    sb_vulnerability  = "vulnerability",
    sb_habitat        = "habitat",
    sb_importance     = "importance",
    sb_lw_a           = "lw_a",
    sb_lw_b           = "lw_b",
    sb_lw_type        = "lw_type",
    sb_lw_method      = "lw_method",
    sb_lw_sex         = "lw_sex",
    sb_lw_n           = "lw_n",
    sb_lw_r2          = "lw_r2"
  )
  enrich_simple(
    x,
    enrichment_name = "sealifebase",
    col_map         = col_map,
    source_label    = "SeaLifeBase",
    cols            = cols,
    verbose         = verbose
  )
}

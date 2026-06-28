#' Add elasmobranch life-history traits (Sharkipedia)
#'
#' Joins Sharkipedia shark and ray life-history traits to a [taxify()] result by
#' `accepted_name`. Long-format observations are reduced to one value per species
#' (numeric traits by median) at build time.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{sharkipedia_lmax_cm}{Maximum observed length (cm).}
#'   \item{sharkipedia_vbgf_linf_cm}{von Bertalanffy asymptotic length Linf (cm).}
#'   \item{sharkipedia_vbgf_k}{von Bertalanffy growth coefficient k (per year).}
#'   \item{sharkipedia_vbgf_t0}{von Bertalanffy t0 (years).}
#'   \item{sharkipedia_length_first_maturity_cm}{Length at first maturity (cm).}
#'   \item{sharkipedia_length_birth_cm}{Length at birth (cm).}
#'   \item{sharkipedia_amax_observed_yr}{Maximum observed age (years).}
#'   \item{sharkipedia_age_first_maturity_yr}{Age at first maturity (years).}
#'   \item{sharkipedia_uterine_fecundity}{Uterine fecundity.}
#'   \item{sharkipedia_gestation_length}{Gestation length.}
#'   \item{sharkipedia_natural_mortality}{Natural mortality M.}
#' }
#'
#' @details Source: Sharkipedia (Mull et al. 2022, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Mull CG et al. (2022) Sharkipedia: a curated open access database of shark and
#' ray life history traits and abundance time-series. Scientific Data 9:559.
#' \doi{10.1038/s41597-022-01655-1}
#'
#' @examples
#' \donttest{
#' taxify("Carcharodon carcharias", backend = "gbif") |>
#'   add_sharkipedia()
#' }
#'
#' @export
add_sharkipedia <- function(x, verbose = TRUE) {
  col_map <- c(
    sharkipedia_lmax_cm                   = "lmax_cm",
    sharkipedia_vbgf_linf_cm              = "vbgf_linf_cm",
    sharkipedia_vbgf_k                    = "vbgf_k",
    sharkipedia_vbgf_t0                   = "vbgf_t0",
    sharkipedia_length_first_maturity_cm  = "length_first_maturity_cm",
    sharkipedia_length_birth_cm           = "length_birth_cm",
    sharkipedia_amax_observed_yr          = "amax_observed_yr",
    sharkipedia_age_first_maturity_yr     = "age_first_maturity_yr",
    sharkipedia_uterine_fecundity         = "uterine_fecundity",
    sharkipedia_gestation_length          = "gestation_length",
    sharkipedia_natural_mortality         = "natural_mortality"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "sharkipedia",
    col_map         = col_map,
    source_label    = "Sharkipedia",
    na_types        = na_types,
    verbose         = verbose
  )
}

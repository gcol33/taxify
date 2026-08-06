#' Add earthworm traits (Pelosi et al. 2014)
#'
#' Joins fuzzy-coded earthworm functional traits to a [taxify()] result by
#' looking up `accepted_name`. Output columns are prefixed `betsi_ew_`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns, one per modality bin of
#'   seven fuzzy-coded traits: body length, body mass to length ratio, cocoon
#'   diameter, epithelium, typhlosolis, soil carbon preference and vertical
#'   distribution. Each trait is fuzzy coded, so a species' affinities across the
#'   bins of one trait (columns sharing a `betsi_ew_<trait>__` stem) sum to 100.
#'   See \code{\link{enrichment_cols}} for the full column list.
#'
#' @details
#' Source: earthworm functional traits compiled from the BETSI database
#' (Biological and Ecological Traits of Soil Invertebrates) and published in
#' Pelosi et al. (2014), Appendix 1. Coverage: 11 species. Earthworm body length
#' and soil carbon preference are given as fuzzy affinity vectors rather than a
#' single value, so they are not passed to the scalar [add_trait()] verb.
#'
#' @references
#' Pelosi C, Pey B, Hedde M, et al. (2014) Reducing tillage in cultivated fields
#' increases earthworm functional diversity. Applied Soil Ecology 83:79-87.
#' \doi{10.1016/j.apsoil.2013.10.005}
#'
#' @examples
#' \dontrun{
#' taxify("Lumbricus terrestris", backbone = "gbif") |>
#'   add_betsi_earthworm_traits()
#' }
#'
#' @export
add_betsi_earthworm_traits <- function(x, cols = NULL, verbose = TRUE) {
  base <- c(
    "body_length_mm__20_50", "body_length_mm__50_100", "body_length_mm__100_150",
    "body_length_mm__150_200", "body_length_mm__200_400",
    "body_mass_length_ratio__1_7", "body_mass_length_ratio__7_15",
    "body_mass_length_ratio__gt15",
    "cocoon_diameter_mm__1_2", "cocoon_diameter_mm__2_4", "cocoon_diameter_mm__4_6",
    "epithelium__supple", "epithelium__rigid",
    "typhlosolis__simple", "typhlosolis__large_feather",
    "carbon_pref_mgkg__lt20", "carbon_pref_mgkg__20_33_3",
    "carbon_pref_mgkg__33_3_60", "carbon_pref_mgkg__gt60",
    "vertical_distribution_cm__0_5", "vertical_distribution_cm__5_20",
    "vertical_distribution_cm__gt20")
  col_map <- stats::setNames(base, paste0("betsi_ew_", base))
  enrich_simple(
    x,
    enrichment_name = "betsi_earthworm_traits",
    col_map         = col_map,
    source_label    = "Earthworm traits (Pelosi et al. 2014)",
    cols            = cols,
    col_prefix      = "betsi_ew_",
    out_prefix      = "betsi_ew_",
    verbose         = verbose
  )
}

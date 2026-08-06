#' Add Collembola traits (Lu et al. 2025)
#'
#' Joins per-species springtail functional traits to a [taxify()] result by
#' looking up `accepted_name`. Output columns are prefixed `betsi_ct_`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{betsi_ct_body_length_mm}{Maximum body length (mm).}
#'   \item{betsi_ct_antenna_body_ratio}{Antenna to body length ratio.}
#'   \item{betsi_ct_ocelli_number}{Number of ocelli.}
#'   \item{betsi_ct_furca}{Furca (springing organ) development.}
#'   \item{betsi_ct_pigment_scaled}{Pigmentation (scaled).}
#'   \item{betsi_ct_reproduction}{Reproduction mode.}
#'   \item{betsi_ct_stratification_scaled}{Vertical stratification (scaled).}
#'   \item{betsi_ct_trophic_position}{Trophic position.}
#'   \item{betsi_ct_life_form}{Life form (after Potapov et al. 2016).}
#' }
#'
#' @details
#' Source: per-species Collembola traits from Lu et al. (2025), Appendix S1. The
#' morphological traits (body size, antenna/body ratio, furca, pigmentation,
#' ocelli, reproduction) are derived from the BETSI database (Pey et al. 2014);
#' vertical stratification and trophic position were measured in that study and
#' the life form assigned after Potapov et al. (2016). Coverage: 26 species.
#' Body length is also available through [add_trait()]`("body_length")`.
#'
#' @references
#' Lu J-Z et al. (2025) Mixed forests with native species mitigate impacts of
#' introduced Douglas fir on soil decomposers (Collembola). Ecological
#' Applications 35:e70034. \doi{10.1002/eap.70034}
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_betsi_collembola_traits()
#' }
#'
#' @export
add_betsi_collembola_traits <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("body_length_mm", "antenna_body_ratio", "ocelli_number", "furca",
            "pigment_scaled", "reproduction", "stratification_scaled",
            "trophic_position", "life_form")
  col_map <- stats::setNames(base, paste0("betsi_ct_", base))
  enrich_simple(
    x,
    enrichment_name = "betsi_collembola_traits",
    col_map         = col_map,
    source_label    = "Collembola traits (Lu et al. 2025)",
    cols            = cols,
    col_prefix      = "betsi_ct_",
    out_prefix      = "betsi_ct_",
    verbose         = verbose
  )
}

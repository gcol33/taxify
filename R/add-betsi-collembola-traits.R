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
#'   \item{betsi_collembola_traits_betsi_ct_body_length_mm}{Maximum body length (mm).}
#'   \item{betsi_collembola_traits_betsi_ct_antenna_body_ratio}{Antenna to body length ratio.}
#'   \item{betsi_collembola_traits_betsi_ct_ocelli_number}{Number of ocelli.}
#'   \item{betsi_collembola_traits_betsi_ct_furca}{Furca (springing organ) development.}
#'   \item{betsi_collembola_traits_betsi_ct_pigment_scaled}{Pigmentation (scaled).}
#'   \item{betsi_collembola_traits_betsi_ct_reproduction}{Reproduction mode.}
#'   \item{betsi_collembola_traits_betsi_ct_stratification_scaled}{Vertical stratification (scaled).}
#'   \item{betsi_collembola_traits_betsi_ct_trophic_position}{Trophic position.}
#'   \item{betsi_collembola_traits_betsi_ct_life_form}{Life form (after Potapov et al. 2016).}
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
  enrich_door(x, .door_betsi_collembola_traits, cols = cols, verbose = verbose)
}


.door_betsi_collembola_traits <- list(
  enrichment_name = "betsi_collembola_traits",
  col_map = c(
    betsi_ct_body_length_mm = "body_length_mm",
    betsi_ct_antenna_body_ratio = "antenna_body_ratio",
    betsi_ct_ocelli_number = "ocelli_number",
    betsi_ct_furca = "furca",
    betsi_ct_pigment_scaled = "pigment_scaled",
    betsi_ct_reproduction = "reproduction",
    betsi_ct_stratification_scaled = "stratification_scaled",
    betsi_ct_trophic_position = "trophic_position",
    betsi_ct_life_form = "life_form"
  ),
  source_label = "Collembola traits (Lu et al. 2025)"
)

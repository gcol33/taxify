#' Add Collembola traits (Data INRAE deposits)
#'
#' Joins fuzzy-coded springtail functional traits to a [taxify()] result by
#' looking up `accepted_name`. Output columns are prefixed `inrae_`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns, one per modality bin of
#'   seven fuzzy-coded traits: number of ocelli, furca, post-antennal organ,
#'   pigmentation, body shape, scales and reproduction. Each trait is fuzzy
#'   coded, so a species' affinities across the bins of one trait (columns
#'   sharing an `inrae_<trait>__` stem) sum to 100. The source is sparse, so a
#'   trait a species was not scored for is `NA` across its bins. See
#'   \code{\link{enrichment_cols}} for the full column list.
#'
#' @details
#' Source: fuzzy-coded Collembola traits compiled from the BETSI database
#' (Pey et al. 2014) across two Data INRAE deposits, the datasets behind Joimel
#' et al. (2021). Coverage: 135 species. The deposits' species codes carry no
#' published legend and are decoded against a Collembola reference pool; codes
#' that cannot be resolved are dropped, never guessed. The fuzzy affinity vectors
#' are not passed to the scalar [add_trait()] verb.
#'
#' @references
#' Joimel S et al. (2021) Collembola are among the most flexible soil fauna: a
#' comparison across land uses. Frontiers in Ecology and Evolution 9:630919.
#' \doi{10.3389/fevo.2021.630919}
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_inrae_collembola_traits()
#' }
#'
#' @export
add_inrae_collembola_traits <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_inrae_collembola_traits, cols = cols, verbose = verbose)
}


.door_inrae_collembola_traits <- list(
  enrichment_name = "inrae_collembola_traits",
  col_map = c(
    inrae_ocelli__1_3 = "ocelli__1_3",
    inrae_ocelli__4_7 = "ocelli__4_7",
    inrae_ocelli__8 = "ocelli__8",
    inrae_ocelli__absent = "ocelli__absent",
    inrae_furca__present = "furca__present",
    inrae_furca__absent = "furca__absent",
    inrae_post_antennal_organ__present = "post_antennal_organ__present",
    inrae_post_antennal_organ__absent = "post_antennal_organ__absent",
    inrae_pigmentation__present = "pigmentation__present",
    inrae_pigmentation__absent = "pigmentation__absent",
    inrae_body_shape__cylindrical = "body_shape__cylindrical",
    inrae_body_shape__spherical = "body_shape__spherical",
    inrae_scales__present = "scales__present",
    inrae_scales__absent = "scales__absent",
    inrae_reproduction__sexual = "reproduction__sexual",
    inrae_reproduction__asexual = "reproduction__asexual"
  ),
  source_label = "Collembola traits (Data INRAE / Joimel et al. 2021)"
)

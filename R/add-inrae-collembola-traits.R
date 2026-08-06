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
  base <- c(
    "ocelli__1_3", "ocelli__4_7", "ocelli__8", "ocelli__absent",
    "furca__present", "furca__absent",
    "post_antennal_organ__present", "post_antennal_organ__absent",
    "pigmentation__present", "pigmentation__absent",
    "body_shape__cylindrical", "body_shape__spherical",
    "scales__present", "scales__absent",
    "reproduction__sexual", "reproduction__asexual")
  col_map <- stats::setNames(base, paste0("inrae_", base))
  enrich_simple(
    x,
    enrichment_name = "inrae_collembola_traits",
    col_map         = col_map,
    source_label    = "Collembola traits (Data INRAE / Joimel et al. 2021)",
    cols            = cols,
    col_prefix      = "inrae_",
    out_prefix      = "inrae_",
    verbose         = verbose
  )
}

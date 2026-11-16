#' Add Alpine ground-beetle traits (Chamberlain et al.)
#'
#' Joins body size and wing morphology for the carabid fauna of the Italian
#' Alps to a [taxify()] result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) both, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `alpine_` columns: numeric
#'   `alpine_carabids_alpine_body_length_mm`, categorical `alpine_carabids_alpine_wing_morph`.
#'
#' @details Source: Chamberlain et al. (2020), 185 species recorded at 416 sites
#'   between 697 and 2840 m in the Italian Alps. CC0.
#'
#'   The widest European carabid trait table after [add_chowdhury()], and the
#'   one that reaches the Alpine fauna the lowland compilations miss. Like every
#'   European carabid source its body sizes trace back to carabids.org, so
#'   agreement with those is not corroboration; it runs 1.03 against them, the
#'   same quantity without being the verbatim copy [add_eberswalde()] is.
#'
#'   `wing_morph` arrives as bare letters with no legend in the file. The codes
#'   were read off the data rather than assumed: crossed against
#'   [add_chowdhury()]'s words, `b` is short-winged, `m` long-winged and `d`
#'   dimorphic.
#'
#' @references
#' Chamberlain D, Gobbi M, Negro M, et al. (2020) Trait-modulated decline of
#' carabid beetle occurrence along elevation gradients across the European Alps.
#' Journal of Biogeography 47:1030-1041. \doi{10.1111/jbi.13792}
#'
#' Data: \doi{10.5061/dryad.fn2z34tq1}
#'
#' @examples
#' \dontrun{
#' taxify(c("Abax exaratus", "Carabus depressus")) |>
#'   add_alpine_carabids()
#' }
#'
#' @export
add_alpine_carabids <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_alpine_carabids, cols = cols, verbose = verbose)
}


.door_alpine_carabids <- list(
  enrichment_name = "alpine_carabids",
  col_map = c(
    alpine_body_length_mm = "body_length_mm",
    alpine_wing_morph = "wing_morph"
  ),
  source_label = "Alpine carabid traits (Chamberlain et al.)"
)

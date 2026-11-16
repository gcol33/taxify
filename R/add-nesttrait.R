#' Add bird nest traits (NestTrait)
#'
#' Joins bird nest-site, nest-structure and nest-attachment indicators to a
#' [taxify()] result by `accepted_name`. Each trait is a 0/1 presence flag; a
#' species may carry several flags within a group.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with three collapsed categorical columns
#'   (`nesttrait_structure`, `nesttrait_site`, `nesttrait_attachment`, each a
#'   pipe-delimited set of modalities for multi-modal species) plus 20 raw 0/1
#'   indicator columns prefixed `nesttrait_`: `nesttrait_brood_parasite`, `nesttrait_mound_builder`,
#'   seven `nestsite_*`, seven `neststr_*` and four `nestatt_*` flags.
#'
#' @details Source: NestTrait v2 (Chia et al. 2023, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Chia SY et al. (2023) A global database of bird nest traits. Scientific Data.
#' \doi{10.1038/s41597-023-02837-1}
#'
#' @examples
#' \dontrun{
#' taxify("Turdus merula", backbone = "gbif") |>
#'   add_nesttrait()
#' }
#'
#' @export
add_nesttrait <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_nesttrait, cols = cols, verbose = verbose)
}


# Collapsed categoricals (pipe-delimited multi-modal) first, then raw flags.
.door_nesttrait <- list(
  enrichment_name = "nesttrait",
  col_map = c(
    nesttrait_structure = "nest_structure",
    nesttrait_site = "nest_site",
    nesttrait_attachment = "nest_attachment",
    nesttrait_brood_parasite = "brood_parasite",
    nesttrait_mound_builder = "mound_builder",
    nesttrait_nestsite_ground = "nestsite_ground",
    nesttrait_nestsite_tree = "nestsite_tree",
    nesttrait_nestsite_nontree = "nestsite_nontree",
    nesttrait_nestsite_cliff_bank = "nestsite_cliff_bank",
    nesttrait_nestsite_underground = "nestsite_underground",
    nesttrait_nestsite_waterbody = "nestsite_waterbody",
    nesttrait_nestsite_termite_ant = "nestsite_termite_ant",
    nesttrait_neststr_scrape = "neststr_scrape",
    nesttrait_neststr_platform = "neststr_platform",
    nesttrait_neststr_cup = "neststr_cup",
    nesttrait_neststr_dome = "neststr_dome",
    nesttrait_neststr_dome_tunnel = "neststr_dome_tunnel",
    nesttrait_neststr_primary_cavity = "neststr_primary_cavity",
    nesttrait_neststr_second_cavity = "neststr_second_cavity",
    nesttrait_nestatt_basal = "nestatt_basal",
    nesttrait_nestatt_forked = "nestatt_forked",
    nesttrait_nestatt_lateral = "nestatt_lateral",
    nesttrait_nestatt_pensile = "nestatt_pensile"
  ),
  source_label = "NestTrait"
)

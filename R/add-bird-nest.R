#' Add bird nest traits (NestTrait)
#'
#' Joins bird nest-site, nest-structure and nest-attachment indicators to a
#' [taxify()] result by `accepted_name`. Each trait is a 0/1 presence flag; a
#' species may carry several flags within a group.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with 20 additional 0/1 indicator columns prefixed
#'   `bird_nest_`: `brood_parasite`, `mound_builder`, seven `nestsite_*`, seven
#'   `neststr_*` and four `nestatt_*` flags.
#'
#' @details Source: NestTrait v2 (Chia et al. 2023, Scientific Data, CC-BY 4.0).
#'
#' @references
#' Chia SY et al. (2023) A global database of bird nest traits. Scientific Data.
#' \doi{10.1038/s41597-023-02837-1}
#'
#' @examples
#' \donttest{
#' taxify("Turdus merula", backend = "gbif") |>
#'   add_bird_nest()
#' }
#'
#' @export
add_bird_nest <- function(x, verbose = TRUE) {
  cols <- c("brood_parasite", "mound_builder", "nestsite_ground",
            "nestsite_tree", "nestsite_nontree", "nestsite_cliff_bank",
            "nestsite_underground", "nestsite_waterbody", "nestsite_termite_ant",
            "neststr_scrape", "neststr_platform", "neststr_cup", "neststr_dome",
            "neststr_dome_tunnel", "neststr_primary_cavity",
            "neststr_second_cavity", "nestatt_basal", "nestatt_forked",
            "nestatt_lateral", "nestatt_pensile")
  col_map <- stats::setNames(cols, paste0("bird_nest_", cols))
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "bird_nest",
    col_map         = col_map,
    source_label    = "Bird Nest Traits",
    na_types        = na_types,
    verbose         = verbose
  )
}

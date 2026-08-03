#' Add Eberswalde long-term carabid monitoring traits and trends
#'
#' Joins ground-beetle traits and 24-year local population trends to a
#' [taxify()] result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all of them, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `eberswalde_` columns: numeric
#'   `body_length_mm`, `humidity_pref`, `range_centre_lat`, `abundance_total`;
#'   categorical `wing_morph`, `feeding_guild`, `abundance_trend`,
#'   `drought_effect`.
#'
#' @details Source: Weiss, von Wehrden & Linde (2024), 27 species pitfall-trapped
#'   on 13 forest plots near Eberswalde between 1999 and 2022.
#'
#'   `body_length_mm`, `wing_morph` and `range_centre_lat` are carabids.org
#'   (Homburg et al. 2014) verbatim, which the deposit's README states and the
#'   data confirm: over the 19 species shared with [add_chowdhury()] every size
#'   is exactly equal and every wing class agrees. They are surfaced here
#'   because a door should show what its source carries, and they are kept out
#'   of [add_trait()], where they would double-count one lineage.
#'
#'   What belongs to this deposit alone is the monitoring result:
#'   `abundance_trend` over the 24 years, `drought_effect` against the 72-month
#'   SPEI index, and a `feeding_guild` refined by the authors' field
#'   observations to name the prey. `humidity_pref` is Sustek's (2004) 1-8
#'   scale, 1 dry to 8 humid.
#'
#' @references
#' Weiss F, von Wehrden H, Linde A (2024) Eberswalde Carabid Monitoring
#' 1999-2022 - Full Data. PubData Leuphana. \doi{10.48548/pubdata-46}
#'
#' Weiss F, von Wehrden H, Linde A (2024) Long-term drought triggers severe
#' declines in carabid beetles in a temperate forest. Ecography 2024(4):e07020.
#' \doi{10.1111/ecog.07020}
#'
#' @examples
#' \dontrun{
#' taxify(c("Carabus coriaceus", "Nebria brevicollis")) |>
#'   add_eberswalde()
#' }
#'
#' @export
add_eberswalde <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("body_length_mm", "wing_morph", "feeding_guild",
                "humidity_pref", "range_centre_lat", "abundance_total",
                "abundance_trend", "drought_effect")
  col_map <- stats::setNames(all_cols, paste0("eberswalde_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "eberswalde",
    col_map         = col_map,
    source_label    = "Eberswalde carabid monitoring",
    cols            = cols,
    verbose         = verbose
  )
}

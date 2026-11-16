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
#'   `eberswalde_body_length_mm`, `eberswalde_humidity_pref`, `eberswalde_range_centre_lat`, `eberswalde_abundance_total`;
#'   categorical `eberswalde_wing_morph`, `eberswalde_feeding_guild`, `eberswalde_abundance_trend`,
#'   `eberswalde_drought_effect`.
#'
#' @details Source: Weiss, von Wehrden & Linde (2024), 27 species pitfall-trapped
#'   on 13 forest plots near Eberswalde between 1999 and 2022.
#'
#'   `body_length_mm`, `wing_morph` and `range_centre_lat` are carabids.org
#'   (Homburg et al. 2014) verbatim, which the deposit's README states and the
#'   data confirm: over the 19 species shared with [add_chowdhury()] every size
#'   is exactly equal and every wing class agrees. They are surfaced here
#'   because each `add_<source>()` function shows what its source carries, and they are kept out
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
  enrich_door(x, .door_eberswalde, cols = cols, verbose = verbose)
}


.door_eberswalde <- list(
  enrichment_name = "eberswalde",
  col_map = c(
    eberswalde_body_length_mm = "body_length_mm",
    eberswalde_wing_morph = "wing_morph",
    eberswalde_feeding_guild = "feeding_guild",
    eberswalde_humidity_pref = "humidity_pref",
    eberswalde_range_centre_lat = "range_centre_lat",
    eberswalde_abundance_total = "abundance_total",
    eberswalde_abundance_trend = "abundance_trend",
    eberswalde_drought_effect = "drought_effect"
  ),
  source_label = "Eberswalde carabid monitoring"
)

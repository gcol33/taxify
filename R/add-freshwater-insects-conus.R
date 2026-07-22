#' Add freshwater-insect genus traits (Freshwater Insects CONUS)
#'
#' Joins genus-level ecological and life-history trait modalities of North
#' American freshwater insects to a [taxify()] result by looking up `genus`, so
#' any species in a covered genus is annotated. The modalities are the source's
#' own abbreviation codes, kept verbatim.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The curated set:
#' \describe{
#'   \item{fwinsect_thermal_pref}{Thermal preference class.}
#'   \item{fwinsect_feed_prim}{Primary functional feeding group code.}
#'   \item{fwinsect_habit_prim}{Primary habit (swimmer, clinger, burrower, ...).}
#'   \item{fwinsect_rheophily}{Rheophily (current preference) code.}
#'   \item{fwinsect_voltinism}{Voltinism (generations per year) code.}
#'   \item{fwinsect_max_body_size}{Maximum body size class.}
#' }
#' With `cols = "all"` the remaining trait groups (emergence, dispersal,
#' respiration, ...) are attached under their source names.
#'
#' @details Source: Twardochleb et al. (2021, Environmental Data Initiative,
#'   CC BY 4.0), the Freshwater Insects CONUS genus trait table. Traits are
#'   genus-level categorical modalities.
#'
#' @references
#' Twardochleb LA et al. (2021) Freshwater insect occurrences and traits for the
#' contiguous United States, 2001-2018. Environmental Data Initiative.
#' \doi{10.6073/pasta/8238ea9bc15840844b3a023b6b6ed158}
#'
#' @examples
#' \dontrun{
#' taxify("Baetis", backbone = "gbif") |>
#'   add_freshwater_insects_conus()
#' }
#'
#' @export
add_freshwater_insects_conus <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c(
    fwinsect_thermal_pref   = "thermal_pref",
    fwinsect_feed_prim      = "feed_prim_abbrev",
    fwinsect_habit_prim     = "habit_prim",
    fwinsect_rheophily      = "rheophily_abbrev",
    fwinsect_voltinism      = "voltinism_abbrev",
    fwinsect_max_body_size  = "max_body_size_abbrev"
  )
  enrich_simple(
    x,
    enrichment_name = "freshwater_insects_conus",
    col_map         = cat_cols,
    source_label    = "Freshwater Insects CONUS genus traits",
    join_col        = "genus",
    cols            = cols,
    verbose         = verbose
  )
}

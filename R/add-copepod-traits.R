#' Add copepod traits (Brun et al. 2017)
#'
#' Joins marine-copepod traits from the trait database of Brun et al. (2017) to a
#' [taxify()] result by looking up `accepted_name`. Records are reduced to
#' per-species values (numeric by median, categorical by mode).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{cop_body_length_mm}{Body length (mm).}
#'   \item{cop_egg_diameter_um}{Egg outer diameter (micrometres).}
#'   \item{cop_clutch_size}{Clutch size.}
#'   \item{cop_feeding_mode}{Feeding mode.}
#'   \item{cop_spawning_strategy}{Spawning strategy.}
#' }
#' `cols = "all"` also attaches feeder type, myelination, resting-egg presence,
#' and the per-species min/max/n spread of the numeric values.
#'
#' @details
#' Source: A trait database for marine copepods (Brun et al. 2017), PANGAEA,
#' CC BY 3.0.
#'
#' @references
#' Brun P, Payne MR, Kiorboe T (2017) A trait database for marine copepods.
#' Earth System Science Data 9:99-113. \doi{10.5194/essd-9-99-2017}
#'
#' @examples
#' \dontrun{
#' # Downloads the enrichment on first use.
#' taxify("Calanus finmarchicus", backbone = "gbif") |>
#'   add_copepod_traits()
#' }
#'
#' @export
add_copepod_traits <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("body_length_mm", "egg_diameter_um", "clutch_size",
            "feeding_mode", "spawning_strategy")
  col_map <- stats::setNames(base, paste0("cop_", base))
  enrich_simple(
    x, enrichment_name = "copepod_traits", col_map = col_map,
    source_label = "Copepod traits (Brun et al. 2017)",
    cols = cols, col_prefix = "cop_", out_prefix = "cop_", verbose = verbose
  )
}

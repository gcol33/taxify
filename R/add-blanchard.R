#' Add ant genus defensive traits (Blanchard & Moreau)
#'
#' Joins genus-level ant defensive and ecological traits to a [taxify()] result
#' by `genus`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `blanchard_` columns: categorical
#'   `blanchard_subfamily`, `blanchard_spines`, `blanchard_sting`, `blanchard_diet`, `blanchard_nesting`, `blanchard_foraging`; numeric
#'   `blanchard_colony_size_workers` (joined on genus).
#'
#' @details Source: Blanchard & Moreau (2017) ant defensive traits (Dryad, CC0).
#'   Joins on genus because the database is genus-resolved.
#'
#' @references
#' Blanchard BD, Moreau CS (2017) Defensive traits in the ant genera database.
#' Dryad. \doi{10.5061/dryad.st6sc}
#'
#' @examples
#' \dontrun{
#' taxify("Camponotus pennsylvanicus", backbone = "gbif") |>
#'   add_blanchard()
#' }
#'
#' @export
add_blanchard <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_blanchard, cols = cols, verbose = verbose)
}


.door_blanchard <- list(
  enrichment_name = "blanchard",
  col_map = c(
    blanchard_subfamily = "subfamily",
    blanchard_spines = "spines",
    blanchard_sting = "sting",
    blanchard_diet = "diet",
    blanchard_nesting = "nesting",
    blanchard_foraging = "foraging",
    blanchard_colony_size_workers = "colony_size_workers"
  ),
  source_label = "Blanchard ant traits",
  join_col = "genus"
)

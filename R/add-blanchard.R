#' Add ant genus defensive traits (Blanchard & Moreau)
#'
#' Joins genus-level ant defensive and ecological traits to a [taxify()] result
#' by `genus`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `blanchard_` columns: categorical
#'   `subfamily`, `spines`, `sting`, `diet`, `nesting`, `foraging`; numeric
#'   `colony_size_workers` (joined on genus).
#'
#' @details Source: Blanchard & Moreau (2017) ant defensive traits (Dryad, CC0).
#'   Joins on genus because the database is genus-resolved.
#'
#' @references
#' Blanchard BD, Moreau CS (2017) Defensive traits in the ant genera database.
#' Dryad. \doi{10.5061/dryad.st6sc}
#'
#' @examples
#' \donttest{
#' taxify("Camponotus pennsylvanicus", backend = "gbif") |>
#'   add_blanchard()
#' }
#'
#' @export
add_blanchard <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c("subfamily", "spines", "sting", "diet", "nesting", "foraging")
  num_cols <- c("colony_size_workers")
  all_cols <- c(cat_cols, num_cols)
  col_map <- stats::setNames(all_cols, paste0("blanchard_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "blanchard",
    col_map         = col_map,
    source_label    = "Blanchard ant traits",
    join_col        = "genus",
    cols            = cols,
    verbose         = verbose
  )
}

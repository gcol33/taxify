#' Add ant genus defensive traits (Blanchard & Moreau)
#'
#' Joins genus-level ant defensive and ecological traits to a [taxify()] result
#' by `genus`.
#'
#' @param x A data.frame returned by [taxify()].
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
add_blanchard <- function(x, verbose = TRUE) {
  cat_cols <- c("subfamily", "spines", "sting", "diet", "nesting", "foraging")
  num_cols <- c("colony_size_workers")
  all_cols <- c(cat_cols, num_cols)
  col_map <- stats::setNames(all_cols, paste0("blanchard_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_character_), length(cat_cols)),
      rep(list(NA_real_), length(num_cols))),
    paste0("blanchard_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "blanchard",
    col_map         = col_map,
    source_label    = "Blanchard ant traits",
    na_types        = na_types,
    join_col        = "genus",
    verbose         = verbose
  )
}

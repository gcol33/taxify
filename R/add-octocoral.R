#' Add octocoral traits (Octocoral Trait Database)
#'
#' Joins soft-coral (octocoral) colony, polyp, skeleton, symbiosis and feeding
#' traits to a [taxify()] result by `accepted_name`. Built from long-format
#' records reduced to one value per species.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `octocoral_` columns: numeric
#'   `colony_height`, `colony_width`, `tentacles_per_polyp`; categorical
#'   `growth_form`, `type_of_growth`, `type_of_skeleton`, `polyp_retractability`,
#'   `polyp_dimorphism`, `zooxanthellate`, `axis_presence`, `feeding_mechanism`,
#'   `coloniality`, `skeletal_rigidity`, `calcareous_sclerites_presence`.
#'
#' @details Source: Octocoral Trait Database v2.2 (Gomez-Gras et al., CC-BY 4.0).
#'
#' @references
#' Octocoral Trait Database v2.2. Zenodo. \doi{10.5281/zenodo.14228404}
#'
#' @examples
#' \donttest{
#' taxify("Gorgonia ventalina", backend = "gbif") |>
#'   add_octocoral()
#' }
#'
#' @export
add_octocoral <- function(x, verbose = TRUE) {
  num_cols <- c("colony_height", "colony_width", "tentacles_per_polyp")
  cat_cols <- c("growth_form", "type_of_growth", "type_of_skeleton",
                "polyp_retractability", "polyp_dimorphism", "zooxanthellate",
                "axis_presence", "feeding_mechanism", "coloniality",
                "skeletal_rigidity", "calcareous_sclerites_presence")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("octocoral_", all_cols))
  na_types <- stats::setNames(
    c(rep(list(NA_real_), length(num_cols)),
      rep(list(NA_character_), length(cat_cols))),
    paste0("octocoral_", all_cols)
  )
  enrich_simple(
    x,
    enrichment_name = "octocoral",
    col_map         = col_map,
    source_label    = "Octocoral Trait Database",
    na_types        = na_types,
    verbose         = verbose
  )
}

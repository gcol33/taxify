#' Add octocoral traits (Octocoral Trait Database)
#'
#' Joins soft-coral (octocoral) colony, polyp, skeleton, symbiosis and feeding
#' traits to a [taxify()] result by `accepted_name`. Built from long-format
#' records reduced to one value per species.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `octocoral_` columns: numeric
#'   `octocoral_colony_height`, `octocoral_colony_width`, `octocoral_tentacles_per_polyp`; categorical
#'   `octocoral_growth_form`, `octocoral_type_of_growth`, `octocoral_type_of_skeleton`, `octocoral_polyp_retractability`,
#'   `octocoral_polyp_dimorphism`, `octocoral_zooxanthellate`, `octocoral_axis_presence`, `octocoral_feeding_mechanism`,
#'   `octocoral_coloniality`, `octocoral_skeletal_rigidity`, `octocoral_calcareous_sclerites_presence`.
#'
#' @details Source: Octocoral Trait Database v2.2 (Gomez-Gras et al., CC-BY 4.0).
#'
#' @references
#' Octocoral Trait Database v2.2. Zenodo. \doi{10.5281/zenodo.14228404}
#'
#' @examples
#' \dontrun{
#' taxify("Gorgonia ventalina", backbone = "gbif") |>
#'   add_octocoral()
#' }
#'
#' @export
add_octocoral <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_octocoral, cols = cols, verbose = verbose)
}


.door_octocoral <- list(
  enrichment_name = "octocoral",
  col_map = c(
    octocoral_colony_height = "colony_height",
    octocoral_colony_width = "colony_width",
    octocoral_tentacles_per_polyp = "tentacles_per_polyp",
    octocoral_growth_form = "growth_form",
    octocoral_type_of_growth = "type_of_growth",
    octocoral_type_of_skeleton = "type_of_skeleton",
    octocoral_polyp_retractability = "polyp_retractability",
    octocoral_polyp_dimorphism = "polyp_dimorphism",
    octocoral_zooxanthellate = "zooxanthellate",
    octocoral_axis_presence = "axis_presence",
    octocoral_feeding_mechanism = "feeding_mechanism",
    octocoral_coloniality = "coloniality",
    octocoral_skeletal_rigidity = "skeletal_rigidity",
    octocoral_calcareous_sclerites_presence = "calcareous_sclerites_presence"
  ),
  source_label = "Octocoral Trait Database"
)

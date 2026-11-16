#' Add bacterial and archaeal strain phenotypes (BacDive)
#'
#' Joins per-species microbial phenotype and growth-condition traits from
#' BacDive, the Bacterial Diversity Metadatabase (DSMZ), to a [taxify()] result
#' by looking up `accepted_name`. Strain-level records are aggregated to one row
#' per species (categorical traits by mode, numeric by median); temperature and
#' pH prefer the optimum measurement, falling back to the growth measurement.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{bacdive_gram_stain}{Gram reaction (positive / negative / variable).}
#'   \item{bacdive_cell_shape}{Cell morphology (rod, coccus, ...).}
#'   \item{bacdive_motility}{motile / non-motile.}
#'   \item{bacdive_oxygen_metabolism}{Oxygen tolerance (aerobe, anaerobe, facultative
#'     anaerobe, microaerophile, ...).}
#'   \item{bacdive_cell_length_um, bacdive_cell_width_um}{Cell dimensions in micrometres.}
#'   \item{bacdive_optimal_growth_temp_c}{Optimal (or reported growth) temperature, C.}
#'   \item{bacdive_optimal_growth_ph}{Optimal (or reported growth) pH.}
#' }
#'
#' @details
#' Source: BacDive (Reimer et al.), DSMZ, CC BY 4.0. ~18.6k bacterial and
#' archaeal species with at least one phenotypic trait.
#'
#' @references
#' Reimer LC et al. (2022) BacDive in 2022: the knowledge base for standardized
#' bacterial and archaeal data. Nucleic Acids Research 50:D741-D746.
#' doi:10.1093/nar/gkab961
#'
#' @examples
#' \dontrun{
#' taxify("Escherichia coli", backbone = "gbif") |>
#'   add_bacdive()
#' }
#'
#' @export
add_bacdive <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_bacdive, cols = cols, verbose = verbose)
}


.door_bacdive <- list(
  enrichment_name = "bacdive",
  col_map = c(
    gram_stain = "gram_stain",
    cell_shape = "cell_shape",
    motility = "motility",
    oxygen_metabolism = "oxygen_metabolism",
    cell_length_um = "cell_length_um",
    cell_width_um = "cell_width_um",
    optimal_growth_temp_c = "optimal_growth_temp_c",
    optimal_growth_ph = "optimal_growth_ph"
  ),
  source_label = "BacDive (DSMZ)"
)

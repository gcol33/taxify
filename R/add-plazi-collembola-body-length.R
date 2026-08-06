#' Add Collembola body length (Plazi treatments)
#'
#' Joins per-species springtail body length to a [taxify()] result by looking up
#' `accepted_name`. The value is mined from Plazi taxonomic treatments and
#' aggregated per species: the median, with the observed range and the
#' measurement and treatment-paper counts.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{plazi_body_length_mm}{Body length (mm), median of the mined
#'     measurements.}
#'   \item{plazi_body_length_min_mm}{Smallest measurement (mm).}
#'   \item{plazi_body_length_max_mm}{Largest measurement (mm).}
#'   \item{plazi_body_length_n}{Number of measurements aggregated.}
#'   \item{plazi_body_length_sources}{Number of distinct treatment papers.}
#' }
#'
#' @details
#' Source: Plazi TreatmentBank (plazi.org), taxonomic treatments republished as
#' Darwin Core Archives through GBIF, CC0 1.0. Coverage: 998 species from 1,117
#' measurements. On the 35 species it shares with the BETSI body-length floor the
#' mined values track BETSI at Pearson r = 0.906 (Spearman 0.955), and it adds
#' 963 species BETSI does not cover. Cite the individual treatments for any
#' species-level use. Body length is also available through
#' [add_trait()]`("body_length")`.
#'
#' @references
#' Plazi TreatmentBank. \url{https://www.plazi.org}
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_plazi_collembola_body_length()
#' }
#'
#' @export
add_plazi_collembola_body_length <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("plazi_body_length_mm", "plazi_body_length_min_mm",
                "plazi_body_length_max_mm", "plazi_body_length_n",
                "plazi_body_length_sources")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "plazi_collembola_body_length",
    col_map         = col_map,
    source_label    = "Plazi Collembola body length",
    cols            = cols,
    verbose         = verbose
  )
}

#' Add Collembola body length (monographs)
#'
#' Joins per-species springtail body length to a [taxify()] result by looking up
#' `accepted_name`. The value is mined from three primary Collembola monographs
#' and aggregated per species: the median of the per-monograph medians, with the
#' observed range and the measurement and monograph counts.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{monograph_body_length_mm}{Body length (mm), median of the
#'     per-monograph medians.}
#'   \item{monograph_body_length_min_mm}{Smallest measurement (mm).}
#'   \item{monograph_body_length_max_mm}{Largest measurement (mm).}
#'   \item{monograph_body_length_n}{Number of measurements aggregated.}
#'   \item{monograph_body_length_sources}{Number of monographs contributing.}
#' }
#'
#' @details
#' Source: body length mined from three primary Collembola monographs, Stach
#' (1957, Neelidae and Dicyrtomidae), Hopkin (2007, Britain and Ireland) and
#' Bretfeld (1999, Symphypleona). The source monographs are copyright their
#' publishers; only the extracted measurements are redistributed, for
#' non-commercial scientific use. Coverage: 481 species from 679 measurements. A
#' re-extraction independent of BETSI, more complete than BETSI on the shared
#' books (210 vs 145 species from Bretfeld 1999) and reaching Stach's Neelidae
#' and Dicyrtomidae, which fall outside BETSI's Collembola coverage. Body length
#' is also available through [add_trait()]`("body_length")`.
#'
#' @references
#' Hopkin SP (2007) A Key to the Collembola (Springtails) of Britain and Ireland.
#' FSC Publications, Shrewsbury.
#'
#' @examples
#' \dontrun{
#' taxify("Isotoma viridis", backbone = "gbif") |>
#'   add_monograph_collembola_body_length()
#' }
#'
#' @export
add_monograph_collembola_body_length <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("monograph_body_length_mm", "monograph_body_length_min_mm",
                "monograph_body_length_max_mm", "monograph_body_length_n",
                "monograph_body_length_sources")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "monograph_collembola_body_length",
    col_map         = col_map,
    source_label    = "Collembola monograph body length",
    cols            = cols,
    verbose         = verbose
  )
}

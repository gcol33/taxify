#' Add plant genome size (Kew Plant DNA C-values)
#'
#' Joins plant genome-size data from the Kew Plant DNA C-values database
#' (Pellicer & Leitch 2020) to a [taxify()] result by looking up `accepted_name`.
#' Records are reduced to per-species medians.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{cval_genome_size_1c_pg}{Genome size (1C DNA amount, picograms).}
#'   \item{cval_chromosome_2n}{Somatic chromosome number (2n).}
#'   \item{cval_ploidy_x}{Ploidy level.}
#' }
#' `cols = "all"` also attaches the per-species min/max/n spread of each value.
#'
#' @details
#' Source: Kew Plant DNA C-values database, release 7.1 (Royal Botanic Gardens
#' Kew), CC BY. Vascular plants.
#'
#' @references
#' Pellicer J, Leitch IJ (2020) The Plant DNA C-values database (release 7.1):
#' an updated online repository of plant genome size data for comparative
#' studies. New Phytologist 226:301-305.
#'
#' @examples
#' \dontrun{
#' # Downloads the enrichment on first use.
#' taxify("Zea mays", backend = "gbif") |>
#'   add_kew_cvalues()
#' }
#'
#' @export
add_kew_cvalues <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("genome_size_1c_pg", "chromosome_2n", "ploidy_x")
  col_map <- stats::setNames(base, paste0("cval_", base))
  enrich_simple(
    x, enrichment_name = "kew_cvalues", col_map = col_map,
    source_label = "Kew Plant DNA C-values (Pellicer & Leitch 2020)",
    cols = cols, col_prefix = "cval_", out_prefix = "cval_", verbose = verbose
  )
}

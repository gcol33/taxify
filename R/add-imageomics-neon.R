#' Add North American ground-beetle elytra measurements (Imageomics / NEON)
#'
#' Joins per-species elytra measurements, taken from images of pinned NEON
#' specimens, to a [taxify()] result by accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all of them, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `neon_` columns: numeric
#'   `elytra_length_mm`, `elytra_width_mm`, and `measurement_n` (the number of
#'   individual measurements behind the median).
#'
#' @details Source: the Imageomics `2018-NEON-beetles` dataset, 39,064
#'   measurements of pinned individuals across 30 NEON sites, reduced to a
#'   per-species median over 75 named species.
#'
#'   This is the only North American ground-beetle morphometry taxify carries,
#'   and the only carabid measurement source independent of carabids.org, whose
#'   values every European carabid table inherits.
#'
#'   The source measures the elytron rather than the whole animal, in
#'   centimetres; values here are millimetres. Measurements of specimens
#'   photographed at an angle (`lying_flat = "No"`) are excluded, since a
#'   projected length is foreshortened. The length-to-width ratio has a median
#'   of 1.79 across species, the shape of a carabid elytron, and *Carabus
#'   nemoralis* reads 14.87 mm against the 23.4 mm body length that
#'   [add_finand()] measured on European specimens.
#'
#' @references
#' Imageomics Institute. 2018-NEON-beetles. Hugging Face.
#' \url{https://huggingface.co/datasets/imageomics/2018-NEON-beetles}
#'
#' @examples
#' \dontrun{
#' taxify(c("Carabus nemoralis", "Pasimachus californicus")) |>
#'   add_imageomics_neon()
#' }
#'
#' @export
add_imageomics_neon <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("elytra_length_mm", "elytra_width_mm", "measurement_n")
  col_map <- stats::setNames(all_cols, paste0("neon_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "imageomics_neon",
    col_map         = col_map,
    source_label    = "Imageomics NEON beetle measurements",
    cols            = cols,
    verbose         = verbose
  )
}

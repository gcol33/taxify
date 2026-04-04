#' Add qualifier information
#'
#' Parses the `input_name` column from a [taxify()] result to extract
#' taxonomic qualifiers (cf., aff., s.l., etc.) and their positions.
#'
#' @param x A data.frame returned by [taxify()].
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{qualifier}{The qualifier found (e.g., `"cf."`, `"aff."`),
#'     or `NA` if none.}
#'   \item{qualifier_position}{Integer position (character index) of the
#'     qualifier in the original name, or `NA` if none.}
#' }
#'
#' @examples
#' \dontrun{
#' taxify("Pinus cf. sylvestris") |>
#'   add_qualifier_info()
#' }
#'
#' @export
add_qualifier_info <- function(x) {
  if (!"input_name" %in% names(x)) {
    stop("x must be a data.frame with an 'input_name' column (from taxify())",
         call. = FALSE)
  }

  quals <- vapply(x$input_name, function(nm) {
    if (is.na(nm)) return(NA_character_)
    extract_qualifier(nm)
  }, character(1L), USE.NAMES = FALSE)

  positions <- vapply(x$input_name, function(nm) {
    if (is.na(nm)) return(NA_integer_)
    m <- regexpr(.qualifier_pattern, nm, perl = TRUE)
    if (m == -1L) NA_integer_ else as.integer(m)
  }, integer(1L), USE.NAMES = FALSE)

  x$qualifier <- quals
  x$qualifier_position <- positions

  n_enriched <- sum(!is.na(x$qualifier))
  register_enrichment(x, "qualifier_info", "taxify", NA_character_, n_enriched)
}

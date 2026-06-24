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
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Pinus cf. sylvestris") |>
#'   add_qualifier_info()
#'
#' options(old)
#'
#' @export
add_qualifier_info <- function(x) {
  if (!"input_name" %in% names(x)) {
    stop("x must be a data.frame with an 'input_name' column (from taxify())",
         call. = FALSE)
  }

  matches <- lapply(x$input_name, qualifier_match)

  x$qualifier <- vapply(matches, `[[`, character(1L), "qualifier",
                        USE.NAMES = FALSE)
  x$qualifier_position <- vapply(matches, `[[`, integer(1L), "position",
                                 USE.NAMES = FALSE)

  n_enriched <- sum(!is.na(x$qualifier))
  register_enrichment(x, "qualifier_info", "taxify", NA_character_, n_enriched)
}

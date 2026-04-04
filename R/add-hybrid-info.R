#' Add hybrid parent and type information
#'
#' Parses the `input_name` column from a [taxify()] result to extract
#' hybrid parent names and classify the hybrid type.
#'
#' @param x A data.frame returned by [taxify()].
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{hybrid_parent_1}{First parent (full binomial), `NA` if not a
#'     hybrid formula.}
#'   \item{hybrid_parent_2}{Second parent (full binomial, abbreviated
#'     genus expanded), `NA` if not a hybrid formula.}
#'   \item{hybrid_type}{One of `"nothogenus"`, `"nothospecies"`,
#'     `"formula"`, or `NA` if not a hybrid.}
#' }
#'
#' @examples
#' \dontrun{
#' taxify("Quercus pyrenaica x Q. petraea") |>
#'   add_hybrid_info()
#' }
#'
#' @export
add_hybrid_info <- function(x) {
  if (!"input_name" %in% names(x)) {
    stop("x must be a data.frame with an 'input_name' column (from taxify())",
         call. = FALSE)
  }

  parsed <- lapply(x$input_name, function(nm) {
    if (is.na(nm)) {
      return(list(parent_1 = NA_character_, parent_2 = NA_character_,
                  hybrid_type = NA_character_))
    }
    parse_hybrid_formula(nm)
  })

  x$hybrid_parent_1 <- vapply(parsed, `[[`, character(1L), "parent_1")
  x$hybrid_parent_2 <- vapply(parsed, `[[`, character(1L), "parent_2")
  x$hybrid_type <- vapply(parsed, `[[`, character(1L), "hybrid_type")

  n_enriched <- sum(!is.na(x$hybrid_type))
  register_enrichment(x, "hybrid_info", "taxify", NA_character_, n_enriched)
}

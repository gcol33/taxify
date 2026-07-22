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
#'   \item{hybrid_parent_2}{Second parent (full binomial, abbreviated or omitted
#'     genus expanded), `NA` if not a hybrid formula.}
#'   \item{hybrid_parent_1_accepted, hybrid_parent_2_accepted}{The accepted
#'     name each parent resolves to against the backbone(s) used for `x` (from
#'     the result's metadata), or `NA` if the parent did not match.}
#'   \item{hybrid_type}{One of `"nothogenus"`, `"nothospecies"`,
#'     `"formula"`, or `NA` if not a hybrid (same value as the `hybrid_type`
#'     column already on a [taxify()] result).}
#' }
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus pyrenaica x Q. petraea") |>
#'   add_hybrid_info()
#'
#' options(old)
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
  x$hybrid_type     <- vapply(parsed, `[[`, character(1L), "hybrid_type")

  # Resolve each parent to its accepted name against the backbone(s) used for x.
  x$hybrid_parent_1_accepted <- NA_character_
  x$hybrid_parent_2_accepted <- NA_character_
  parents <- unique(c(x$hybrid_parent_1, x$hybrid_parent_2))
  parents <- parents[!is.na(parents) & nzchar(parents)]
  if (length(parents) > 0L) {
    meta    <- attr(x, "taxify_meta")
    backbone <- if (!is.null(meta$backbone)) meta$backbone else "wfo"
    acc <- .resolve_parents_accepted(parents, backbone)
    x$hybrid_parent_1_accepted <- unname(acc[x$hybrid_parent_1])
    x$hybrid_parent_2_accepted <- unname(acc[x$hybrid_parent_2])
  }

  n_enriched <- sum(!is.na(x$hybrid_type))
  register_enrichment(x, "hybrid_info", "taxify", NA_character_, n_enriched)
}

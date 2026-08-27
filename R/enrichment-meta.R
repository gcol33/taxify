# ---- Enrichment metadata tracking ----
#
# Internal helper called by add_*_info() functions to record what enrichment
# layers have been applied. The summary method reads this to report enrichments.

#' Register an enrichment layer in taxify_meta
#'
#' @param result A taxify_result data.frame.
#' @param name Character. Short label for the enrichment (e.g., "wfo_info").
#' @param source_label Character. Human-readable description of the source
#'   (e.g., "WFO 2024-12"). The enrichment *key* is `name`; this is the text
#'   `summary()` and `cite()` display.
#' @param version Character. Version string, or NA if unknown.
#' @param n_matched Integer. Number of rows that received non-NA values.
#' @param license Character. License string (e.g., `"CC0"`, `"CC BY 4.0"`),
#'   or `NA_character_` if unknown or not applicable.
#' @param n_recovered Integer. Of `n_matched`, how many rows were filled by
#'   cross-backbone recovery -- the source had no row under the accepted name
#'   the query was matched to, and one under another backbone's accepted name
#'   for the same concept.
#' @return The modified result with updated taxify_meta attribute.
#' @noRd
register_enrichment <- function(result, name, source_label, version,
                                n_matched,
                                license = NA_character_,
                                n_recovered = 0L) {
  meta <- attr(result, "taxify_meta")
  if (is.null(meta)) meta <- list()
  if (is.null(meta$enrichments)) meta$enrichments <- list()

  n_total <- sum(!is.na(result$matched_name))

  meta$enrichments <- c(meta$enrichments, list(list(
    name      = name,
    source    = source_label,
    version   = version,
    license   = license,
    n_matched = as.integer(n_matched),
    n_total   = as.integer(n_total),
    n_recovered = as.integer(n_recovered)
  )))

  attr(result, "taxify_meta") <- meta
  result
}

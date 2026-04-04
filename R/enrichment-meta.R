# ---- Enrichment metadata tracking ----
#
# Internal helper called by add_*_info() functions to record what enrichment
# layers have been applied. The summary method reads this to report enrichments.

#' Register an enrichment layer in taxify_meta
#'
#' @param result A taxify_result data.frame.
#' @param name Character. Short label for the enrichment (e.g., "wfo_info").
#' @param source Character. Data source description (e.g., "WFO 2024-12").
#' @param version Character. Version string, or NA if unknown.
#' @param n_matched Integer. Number of rows that received non-NA values.
#' @param license Character. License string (e.g., `"CC0"`, `"CC BY 4.0"`),
#'   or `NA_character_` if unknown or not applicable.
#' @return The modified result with updated taxify_meta attribute.
#' @noRd
register_enrichment <- function(result, name, source, version, n_matched,
                                license = NA_character_) {
  meta <- attr(result, "taxify_meta")
  if (is.null(meta)) meta <- list()
  if (is.null(meta$enrichments)) meta$enrichments <- list()

  n_total <- sum(!is.na(result$matched_name))

  meta$enrichments <- c(meta$enrichments, list(list(
    name      = name,
    source    = source,
    version   = version,
    license   = license,
    n_matched = as.integer(n_matched),
    n_total   = as.integer(n_total)
  )))

  attr(result, "taxify_meta") <- meta
  result
}

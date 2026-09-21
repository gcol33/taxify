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
#' @param refused A data.frame of recovery alternatives refused as lying
#'   outside the matched taxon where the source holds values for them in a
#'   group the output left empty (`.refused_report()`), or `NULL`. Stored as
#'   `refused`, with its count of distinct rows as `n_refused`.
#' @return The modified result with updated taxify_meta attribute.
#'
#' @details
#' The version and content id of the installed build are read here, at join
#' time, and recorded alongside. That is what lets [taxify_lock()] pin the build
#' a result was produced from rather than the one installed when the lock is
#' written -- a later refresh or restore moves the second, never the first.
#' A caller that already knows them passes them in.
#' @noRd
register_enrichment <- function(result, name, source_label, version,
                                n_matched,
                                license = NA_character_,
                                n_recovered = 0L,
                                content_id = NULL,
                                refused = NULL) {
  meta <- attr(result, "taxify_meta")
  if (is.null(meta)) meta <- list()
  if (is.null(meta$enrichments)) meta$enrichments <- list()

  n_total <- sum(!is.na(result$matched_name))

  blank <- function(v) {
    length(v) == 0L || is.null(v) || is.na(v[[1L]])
  }
  if (blank(version) || blank(content_id)) {
    id <- enrichment_identity(name)
    if (blank(version))    version    <- id$version
    if (blank(content_id)) content_id <- id$content_id
  }

  meta$enrichments <- c(meta$enrichments, list(list(
    name      = name,
    source    = source_label,
    version   = version,
    content_id = content_id,
    license   = license,
    n_matched = as.integer(n_matched),
    n_total   = as.integer(n_total),
    n_recovered = as.integer(n_recovered),
    n_refused = if (is.null(refused)) 0L else length(unique(refused$row)),
    refused   = refused
  )))

  attr(result, "taxify_meta") <- meta
  result
}


#' Did a registered enrichment layer contribute a value?
#'
#' A source queried but matching no rows -- a bird trait layer on a plant, an
#' [add_trait()] source with no data for these species -- was consulted but is
#' not part of what produced the result. [cite()] does not credit it and
#' [taxify_lock()] does not pin it; both ask here, so the two agree on what
#' "used" means.
#'
#' @param e One entry of `taxify_meta$enrichments`.
#' @return Logical.
#' @noRd
enrichment_contributed <- function(e) {
  n <- e$n_matched %||% NA_integer_
  length(n) == 1L && !is.na(n) && n > 0L
}

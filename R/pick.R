# ---- Best-match selection ----
#
# When multiple backbone rows match a single input name, pick the best one.
# Priority: ACCEPTED > SYNONYM, SPECIES > higher ranks, smallest taxonID.

#' Select the best match from a set of candidates
#'
#' @param candidates A data.frame with at least columns `taxonomicStatus`,
#'   `taxonRank`, and `taxonID`.
#' @return A single-row data.frame (the best candidate).
#' @noRd
pick_best <- function(candidates) {
  if (nrow(candidates) <= 1L) return(candidates)

  # Score: lower is better
  status_score <- ifelse(candidates$taxonomicStatus == "ACCEPTED", 0L, 1L)
  rank_score <- ifelse(toupper(candidates$taxonRank) == "SPECIES", 0L, 1L)

  ord <- order(status_score, rank_score, candidates$taxonID)
  candidates[ord[1L], , drop = FALSE]
}

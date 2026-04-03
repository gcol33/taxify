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


#' Vectorized best-match selection: one best row per group
#'
#' Replaces the pattern of looping `for (ri in unique(matches$row_idx))`
#' with a single sort + dedup. Returns one row per unique value of
#' `group_col`, choosing the best candidate by the same priority as
#' `pick_best()`.
#'
#' @param matches A data.frame with at least `taxonomicStatus`, `taxonRank`,
#'   `taxonID`, and the grouping column.
#' @param group_col Character. Column name to group by (default `"row_idx"`).
#' @return A data.frame with one row per unique group value.
#' @noRd
pick_best_vec <- function(matches, group_col = "row_idx") {
  nr <- nrow(matches)
  if (nr == 0L) return(matches[0L, , drop = FALSE])
  if (nr == 1L) return(matches)

  grp <- matches[[group_col]]

  # Fast path: if all groups are singletons, no sorting needed
  if (!anyDuplicated(grp)) return(matches)

  status_score <- ifelse(matches$taxonomicStatus == "ACCEPTED", 0L, 1L)
  rank_score <- ifelse(toupper(matches$taxonRank) == "SPECIES", 0L, 1L)

  ord <- order(grp, status_score, rank_score, matches$taxonID)
  sorted <- matches[ord, , drop = FALSE]
  sorted[!duplicated(sorted[[group_col]]), , drop = FALSE]
}

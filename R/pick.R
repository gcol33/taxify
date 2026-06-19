# ---- Best-match selection ----
#
# When multiple backbone rows match a single input name, pick the best one.
#
# Priority (smaller score = better):
#   1. ACCEPTED > SYNONYM           (case-tolerant: works for "Accepted"/"ACCEPTED")
#   2. SPECIES  > higher ranks      (case-tolerant)
#   3. nomenclaturalStatus = Valid  (when the column is present in the .vtr)
#   4. epithet-preserving accepted  (the candidate whose accepted name keeps the
#                                    matched name's specific epithet — the
#                                    homotypic basionym among same-name homonym
#                                    synonyms, e.g. `Pinus abies` L. -> `Picea
#                                    abies` rather than the later homonyms
#                                    `Pinus abies` Thunb. -> `Picea polita` etc.)
#   5. lowest taxonID               (deterministic tiebreaker)
#
# When multiple rows share the same top tier (same status_score + rank_score +
# valid_score + epithet_score within a group) AND disagree on
# `accepted_taxon_id`, the pick is genuinely ambiguous: we set
# `is_ambiguous = TRUE` and report the conflicting accepted IDs in
# `ambiguous_targets` so callers can detect the case. Because the epithet score
# enters the tier signature, a single epithet-preserving candidate resolves the
# group cleanly (`is_ambiguous = FALSE`).


#' Extract the normalized specific epithet from a binomial name
#'
#' Applies the same orthographic normalization as the matcher
#' ([normalize_epithets()]) and returns the second token (the specific
#' epithet). Returns `NA` for genus-only names or `NA` input.
#'
#' @param names Character vector of taxonomic names.
#' @return Character vector of normalized epithets (or `NA`).
#' @noRd
epithet_key <- function(names) {
  if (is.null(names)) return(NULL)
  norm <- normalize_epithets(names)
  ep <- sub("^\\S+\\s+(\\S+).*$", "\\1", norm)
  no_ep <- is.na(norm) | !grepl("\\s", norm)
  ep[no_ep] <- NA_character_
  ep
}

#' Score match candidates by resolution priority
#'
#' Computes the per-row priority scores used to rank backbone candidates for a
#' name (smaller is better): ACCEPTED over SYNONYM (`status_score`), SPECIES
#' over higher ranks (`rank_score`), nomenclaturally Valid (`valid_score`),
#' and epithet-preserving accepted target (`epithet_score`, the homotypic
#' basionym among same-name homonym synonyms, e.g. `Pinus abies` ->
#' `Picea abies`). Used by the matching engine's best-match selection and, in
#' the `taxifydb` build pipeline, to collapse each backbone key to the single
#' accepted name `taxify()` resolves it to.
#'
#' @param candidates A data.frame with `taxonomicStatus` and `taxonRank`, and
#'   optionally `nomenclaturalStatus` (validity), plus `matched_name_std` and
#'   `accepted_name` (epithet preservation).
#' @return A list with integer vectors `status_score`, `rank_score`,
#'   `valid_score`, `epithet_score`, and the character `tier` signature
#'   (`"status/rank/valid/epithet"`) per row, in input order.
#' @keywords internal
#' @export
score_candidates <- function(candidates) {
  status_score <- ifelse(toupper(candidates$taxonomicStatus) == "ACCEPTED",
                          0L, 1L)
  rank_score   <- ifelse(toupper(candidates$taxonRank) == "SPECIES",
                          0L, 1L)

  has_nom <- "nomenclaturalStatus" %in% names(candidates)
  if (has_nom) {
    valid_score <- ifelse(candidates$nomenclaturalStatus == "Valid", 0L, 1L)
    valid_score[is.na(valid_score)] <- 1L
  } else {
    valid_score <- integer(nrow(candidates))
  }

  # Epithet-preservation score: among same-name homonym synonyms pointing to
  # different accepted taxa, the homotypic basionym keeps the specific epithet
  # (e.g. `Pinus abies` -> `Picea abies`). Score 0 when the matched name's
  # epithet equals the accepted name's epithet, else 1. Requires both the
  # matched name (`matched_name_std`, set by the matching engine) and
  # `accepted_name`; absent either, the score is uniformly 0 (no effect).
  mat <- candidates$matched_name_std
  acc <- candidates$accepted_name
  if (!is.null(mat) && !is.null(acc)) {
    mat_ep <- epithet_key(mat)
    acc_ep <- epithet_key(acc)
    epithet_score <- ifelse(!is.na(mat_ep) & !is.na(acc_ep) &
                            nzchar(acc_ep) & mat_ep == acc_ep, 0L, 1L)
  } else {
    epithet_score <- integer(nrow(candidates))
  }

  tier <- paste(status_score, rank_score, valid_score, epithet_score,
                sep = "/")
  list(status_score  = status_score,
       rank_score    = rank_score,
       valid_score   = valid_score,
       epithet_score = epithet_score,
       tier          = tier)
}


#' Select the best match from a set of candidates
#'
#' @param candidates A data.frame with at least columns `taxonomicStatus`,
#'   `taxonRank`, and `taxonID`. May optionally include `nomenclaturalStatus`
#'   (used to disambiguate homonym synonyms) and `accepted_taxon_id` (used to
#'   detect ambiguous picks).
#' @return A single-row data.frame (the best candidate), with added columns
#'   `is_ambiguous` (logical) and `ambiguous_targets` (`|`-joined accepted IDs
#'   when ambiguous, otherwise `NA`).
#' @noRd
pick_best <- function(candidates) {
  if (nrow(candidates) == 0L) {
    candidates$is_ambiguous <- logical(0L)
    candidates$ambiguous_targets <- character(0L)
    return(candidates)
  }
  if (nrow(candidates) == 1L) {
    candidates$is_ambiguous <- FALSE
    candidates$ambiguous_targets <- NA_character_
    return(candidates)
  }

  s <- score_candidates(candidates)
  ord <- order(s$status_score, s$rank_score, s$valid_score, s$epithet_score,
               candidates$taxonID)
  best_idx <- ord[1L]

  # Tier-level ambiguity: rows in the same tier as the best, disagreeing on
  # accepted_taxon_id.
  ambig_targets <- NA_character_
  if ("accepted_taxon_id" %in% names(candidates)) {
    same_tier <- s$tier == s$tier[best_idx]
    ids <- unique(candidates$accepted_taxon_id[same_tier])
    ids <- ids[!is.na(ids)]
    if (length(ids) >= 2L) {
      ambig_targets <- paste(sort(ids), collapse = "|")
    }
  }

  out <- candidates[best_idx, , drop = FALSE]
  out$is_ambiguous <- !is.na(ambig_targets)
  out$ambiguous_targets <- ambig_targets
  out
}


#' Vectorized best-match selection: one best row per group
#'
#' Replaces the per-group loop with a single sort + dedup. Honours the same
#' priority as `pick_best()` and reports tier-level ambiguity per group:
#' ACCEPTED > SYNONYM, SPECIES > higher ranks, nomenclaturally Valid, then the
#' epithet-preserving accepted target (homotypic basionym), then lowest
#' `taxonID`.
#'
#' @param matches A data.frame with at least `taxonomicStatus`, `taxonRank`,
#'   `taxonID`, and the grouping column. May optionally include
#'   `nomenclaturalStatus` (validity tiebreak), `matched_name_std` plus
#'   `accepted_name` (epithet-preservation tiebreak), and `accepted_taxon_id`
#'   (ambiguity detection).
#' @param group_col Character. Column name to group by (default `"row_idx"`).
#' @return A data.frame with one row per unique group value, with added
#'   `is_ambiguous` and `ambiguous_targets` columns.
#' @noRd
pick_best_vec <- function(matches, group_col = "row_idx") {
  nr <- nrow(matches)
  if (nr == 0L) {
    matches$is_ambiguous <- logical(0L)
    matches$ambiguous_targets <- character(0L)
    return(matches)
  }
  if (nr == 1L) {
    matches$is_ambiguous <- FALSE
    matches$ambiguous_targets <- NA_character_
    return(matches)
  }

  s <- score_candidates(matches)
  ord <- order(matches[[group_col]], s$status_score, s$rank_score,
               s$valid_score, s$epithet_score, matches$taxonID)
  sorted <- matches[ord, , drop = FALSE]
  sorted_tier <- s$tier[ord]

  is_first <- !duplicated(sorted[[group_col]])

  sorted$is_ambiguous <- FALSE
  sorted$ambiguous_targets <- NA_character_

  if ("accepted_taxon_id" %in% names(sorted)) {
    # Per-group best tier signature, broadcast to every row of the group.
    grp_vec   <- sorted[[group_col]]
    best_pos  <- which(is_first)
    grp_best  <- match(grp_vec, grp_vec[is_first])
    same_tier <- sorted_tier == sorted_tier[best_pos][grp_best]

    if (any(same_tier)) {
      tier_grp <- ifelse(same_tier, as.character(grp_vec), NA_character_)
      tier_acc <- split(sorted$accepted_taxon_id, tier_grp)

      for (g_str in names(tier_acc)) {
        ids <- unique(tier_acc[[g_str]])
        ids <- ids[!is.na(ids)]
        if (length(ids) >= 2L) {
          # Find the first (best) row for this group and flag it.
          g_first <- best_pos[grp_vec[is_first] == g_str |
                              as.character(grp_vec[is_first]) == g_str][1L]
          if (!is.na(g_first)) {
            sorted$is_ambiguous[g_first] <- TRUE
            sorted$ambiguous_targets[g_first] <- paste(sort(ids), collapse = "|")
          }
        }
      }
    }
  }

  sorted[is_first, , drop = FALSE]
}


#' Enforce one-target-per-query uniqueness for fuzzy matches
#'
#' When multiple distinct queries fuzzy-match the same backbone row (e.g. five
#' different `Cherleria` species all fuzzy-match `Cherleria bisulca`), only the
#' query with the smallest fuzzy distance is genuinely close to that target.
#' The others are spurious collapses and should fall through to unmatched
#' rather than fabricate a cross-species match.
#'
#' Operates on the per-query `best` data.frame returned by `pick_best_vec()`.
#' For each duplicated target taxonID at fuzzy_dist > 0, keeps the smallest-
#' distance row and drops the rest (so the caller's `result[idx, ...] <- ...`
#' assignment simply skips them).
#'
#' @param best A data.frame with one row per query, including `row_idx`,
#'   `fuzzy_dist`, and a column matching `id_col`.
#' @param id_col Character. Name of the backbone-row ID column.
#' @return The filtered data.frame.
#' @noRd
dedup_fuzzy_targets <- function(best, id_col) {
  if (nrow(best) <= 1L) return(best)
  if (!id_col %in% names(best))     return(best)
  if (!"fuzzy_dist" %in% names(best)) return(best)

  ids <- best[[id_col]]
  d   <- best$fuzzy_dist

  keep <- rep(TRUE, nrow(best))
  # Only fight over rows with non-NA target and non-zero (truly fuzzy) distance.
  candidate <- !is.na(ids) & !is.na(d) & d > 0
  if (!any(candidate)) return(best)

  ord <- order(ids, d, na.last = TRUE)
  ord_keep <- candidate[ord]
  dup_after_first <- duplicated(ids[ord]) & ord_keep
  if (any(dup_after_first)) {
    keep[ord[dup_after_first]] <- FALSE
  }

  best[keep, , drop = FALSE]
}

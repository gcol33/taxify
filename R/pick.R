# ---- Best-match selection ----
#
# When multiple backbone rows match a single input name, pick the best one.
#
# Two kinds of criterion, and the split matters:
#
# CONCEPT SCORES say which taxonomic concept the name denotes. Together they
# form the `tier` signature (smaller = better):
#   0. smallest fuzzy distance      (fuzzy matches only; decides which backbone
#                                    name the input meant, before the scores
#                                    below decide which row of that name to take)
#   1. status                       (accepted > unreviewed > synonym >
#                                    misapplied; see `.status_rank`)
#   2. SPECIES  > higher ranks      (case-tolerant)
#   3. epithet-preserving accepted  (the candidate whose accepted name keeps the
#                                    matched name's specific epithet — the
#                                    homotypic basionym among same-name homonym
#                                    synonyms, e.g. `Pinus abies` L. -> `Picea
#                                    abies` rather than the later homonyms
#                                    `Pinus abies` Thunb. -> `Picea polita` etc.)
#
# ORDERING TIEBREAKS then choose one row inside the best tier, deterministically:
#   4. nomenclaturalStatus = Valid  (when the column is present in the .vtr)
#   5. lowest taxonID
#
# When multiple rows share the best `tier` AND disagree on `accepted_taxon_id`,
# the pick is genuinely ambiguous: we set `is_ambiguous = TRUE` and report the
# conflicting accepted IDs in `ambiguous_targets` so callers can detect the case.
# The ordering tiebreaks stay out of that signature on purpose: nomenclatural
# validity is a statement about how a name was published, not about which taxon
# it denotes, so it may order the pick but must never make a conflict between
# two different accepted taxa disappear. `Rubus laciniatus` in WFO is the case —
# a Valid record sinking it into `Rubus ulmifolius` and an Illegitimate one into
# `Rubus nemoralis` — where letting validity settle the tier returned a different
# species with `is_ambiguous = FALSE` (#53).
#
# One tier gap does not settle a conflict either: a best row that is only
# *unplaced* is a non-decision by the backbone, so a lower-tier record that does
# place the name elsewhere still counts. See `in_conflict_scope()`.


# Ordered vocabulary for `taxonomicStatus`, smaller = better. Backbones spell
# their status differently and several ship values on neither side of the
# accepted/synonym split: WFO writes `UNCHECKED` for a name it has not reviewed,
# COL `PROVISIONALLY ACCEPTED`, and both keep the name as its own accepted
# concept. Scoring those with the synonyms let a synonym of a *different* species
# outrank the record that keeps the name (#53). A misapplied or ambiguous
# synonym ranks below a plain one: it is a wrong usage, not a nomenclatural act.
# Unlisted spellings fall through to `is_synonym`, so a new backbone vocabulary
# still lands on the right side of the split without an entry here.
.status_rank <- c(
  "ACCEPTED"               = 0L,
  "VALID"                  = 0L,
  "PROVISIONALLY ACCEPTED" = 1L,
  "UNCHECKED"              = 1L,
  "DOUBTFUL"               = 1L,
  "SYNONYM"                = 2L,
  "HOMOTYPIC SYNONYM"      = 2L,
  "HETEROTYPIC SYNONYM"    = 2L,
  "AMBIGUOUS SYNONYM"      = 3L,
  "MISAPPLIED"             = 3L
)

#' Score a taxonomic status string against the ordered status vocabulary
#'
#' Looks each status up in `.status_rank`, then lets the backbone's own
#' normalized `is_synonym` flag clamp the result: a row flagged a synonym can
#' never score better than synonym grade, and a row that is its own accepted
#' concept can never score worse than the unreviewed grade. An unrecognized
#' status is decided by `is_synonym` alone.
#'
#' @param status Character vector of `taxonomicStatus` values.
#' @param is_synonym Logical vector, or `NULL` when the column is absent.
#' @return Integer vector of status scores (smaller is better).
#' @noRd
status_score_vec <- function(status, is_synonym = NULL) {
  key <- toupper(trimws(as.character(status)))
  key <- gsub("[_-]+", " ", key)
  key <- gsub("\\s+", " ", key)
  score <- unname(.status_rank[key])

  if (!is.null(is_synonym)) {
    syn      <- as.logical(is_synonym)
    known    <- !is.na(syn)
    unlisted <- is.na(score) & known
    score[unlisted] <- ifelse(syn[unlisted], 2L, 1L)
    score[known & syn]  <- pmax(score[known & syn],  2L)
    score[known & !syn] <- pmin(score[known & !syn], 1L)
  }
  score[is.na(score)] <- 1L
  as.integer(score)
}


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
#' name (smaller is better): smallest fuzzy distance (`dist_score`), then
#' taxonomic status (`status_score`: accepted, then a name the backbone keeps
#' but has not reviewed, then a synonym, then a misapplication), SPECIES over
#' higher ranks (`rank_score`), the epithet-preserving accepted target
#' (`epithet_score`, the homotypic basionym among same-name homonym synonyms,
#' e.g. `Pinus abies` -> `Picea abies`), and finally nomenclatural validity
#' (`valid_score`). Used by the matching engine's best-match selection and, in
#' the `taxifydb` build pipeline, to collapse each backbone key to the single
#' accepted name `taxify()` resolves it to.
#'
#' `dist_score` orders first because candidates for a fuzzy query are different
#' backbone names: the closest one is the best reading of the input, and the
#' remaining scores then choose among the rows carrying that name. It is 0
#' throughout when `fuzzy_dist` is absent, which is every exact-match path.
#'
#' The returned `tier` covers the four concept scores only. `valid_score` orders
#' the pick but stays out of the tier: a nomenclaturally valid name can be a
#' synonym of a different species than an illegitimate one carrying the same
#' string, so validity must not make that conflict look resolved. Sort with
#' [candidate_order()] rather than re-listing the columns.
#'
#' @param candidates A data.frame with `taxonomicStatus` and `taxonRank`, and
#'   optionally `is_synonym` (the backbone's normalized synonym flag),
#'   `fuzzy_dist` (fuzzy proximity), `nomenclaturalStatus` (validity), plus
#'   `matched_name_std` and `accepted_name` (epithet preservation).
#' @return A list with the numeric vector `dist_score`, integer vectors
#'   `status_score`, `rank_score`, `valid_score`, `epithet_score`, and the
#'   character `tier` signature (`"dist/status/rank/epithet"`) per row, in input
#'   order.
#' @keywords internal
#' @export
score_candidates <- function(candidates) {
  status_score <- status_score_vec(candidates$taxonomicStatus,
                                   candidates$is_synonym)
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

  # Fuzzy distance, when the matcher supplied one. Candidates for a fuzzy query
  # are different backbone names at different edit distances, so the closer name
  # is the better reading of the input and outranks every taxonomic tiebreak:
  # those decide which row of a name to take, not which name was meant. Absent
  # or NA (every exact-match path) the score is uniformly 0 and has no effect.
  fd <- candidates$fuzzy_dist
  if (!is.null(fd)) {
    dist_score <- as.numeric(fd)
    dist_score[is.na(dist_score)] <- 0
  } else {
    dist_score <- numeric(nrow(candidates))
  }

  tier <- paste(dist_score, status_score, rank_score, epithet_score, sep = "/")
  list(dist_score    = dist_score,
       status_score  = status_score,
       rank_score    = rank_score,
       valid_score   = valid_score,
       epithet_score = epithet_score,
       tier          = tier)
}


#' Order match candidates by resolution priority
#'
#' The single source of truth for the candidate sort: the four concept scores of
#' [score_candidates()] in tier order, then the nomenclatural-validity tiebreak,
#' then the lowest `taxonID`. Pass `group_col` to sort within groups first, so
#' the first row of each group is that group's best candidate.
#'
#' @param candidates A data.frame accepted by [score_candidates()], carrying a
#'   `taxonID` column and, when `group_col` is given, that column too.
#' @param scores The [score_candidates()] output for `candidates`, when it has
#'   already been computed; recomputed when `NULL`.
#' @param group_col Character or `NULL`. Column to sort by ahead of the scores.
#' @return An integer permutation of `seq_len(nrow(candidates))`.
#' @keywords internal
#' @export
candidate_order <- function(candidates, scores = NULL, group_col = NULL) {
  s <- scores %||% score_candidates(candidates)
  keys <- list(s$dist_score, s$status_score, s$rank_score, s$epithet_score,
               s$valid_score, candidates$taxonID)
  if (!is.null(group_col)) keys <- c(list(candidates[[group_col]]), keys)
  do.call(order, keys)
}


# Status grade of a name the backbone keeps as its own concept but has not
# placed: WFO's `UNCHECKED`, COL's `PROVISIONALLY ACCEPTED`.
.status_unplaced <- 1L

#' Which candidates count when looking for a conflicting accepted target
#'
#' Normally the rows sharing the best row's `tier`: below that tier the backbone
#' has ranked the candidate lower and the pick is settled.
#'
#' The exception is a best row that is only *unplaced* -- a name the backbone
#' lists but has not placed in its taxonomy. That is a non-decision, not a
#' resolution, so a lower-tier record that does place the name somewhere else is
#' a real disagreement and the whole candidate set counts. `Abies douglasii` var.
#' `taxifolia` in WFO is the case: an unplaced record keeping the name and a
#' synonym record sinking it into `Pseudotsuga menziesii`. Preferring the
#' unplaced record keeps the queried plant's name, but the synonymy is the only
#' actual placement on offer, so the caller has to be told it exists (#53).
#'
#' @param tier Character tier signature per row, from [score_candidates()].
#' @param status_score Integer status score per row, from [score_candidates()].
#' @param best_idx Integer position of the best row.
#' @return Logical vector along `tier`.
#' @noRd
in_conflict_scope <- function(tier, status_score, best_idx) {
  if (status_score[best_idx] == .status_unplaced) return(rep(TRUE, length(tier)))
  tier == tier[best_idx]
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
  best_idx <- candidate_order(candidates, s)[1L]

  # Tier-level ambiguity: rows in the same tier as the best, disagreeing on
  # accepted_taxon_id. Widened to the whole candidate set when the best row is
  # only unplaced (see `in_conflict_scope`).
  ambig_targets <- NA_character_
  if ("accepted_taxon_id" %in% names(candidates)) {
    same_tier <- in_conflict_scope(s$tier, s$status_score, best_idx)
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
#' accepted before unreviewed before synonym, SPECIES > higher ranks, then the
#' epithet-preserving accepted target (homotypic basionym), then the
#' nomenclatural-validity and lowest-`taxonID` tiebreaks.
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
  ord <- candidate_order(matches, s, group_col = group_col)
  sorted <- matches[ord, , drop = FALSE]
  sorted_tier   <- s$tier[ord]
  sorted_status <- s$status_score[ord]

  is_first <- !duplicated(sorted[[group_col]])

  sorted$is_ambiguous <- FALSE
  sorted$ambiguous_targets <- NA_character_

  if ("accepted_taxon_id" %in% names(sorted)) {
    # Per-group best tier signature, broadcast to every row of the group. Same
    # scope rule as pick_best(), vectorized: a group whose best row is only
    # unplaced puts its whole candidate set in scope.
    grp_vec   <- sorted[[group_col]]
    best_pos  <- which(is_first)
    grp_best  <- match(grp_vec, grp_vec[is_first])
    same_tier <- sorted_tier == sorted_tier[best_pos][grp_best] |
      sorted_status[best_pos][grp_best] == .status_unplaced

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
#' @param taken Character vector of backbone-row IDs already claimed by an
#'   earlier fuzzy pass. Matching is run in passes (the join pass, then the
#'   prefix-blocked fallback over what it left), and deduplicating within a pass
#'   only would let the runner-up claim its own copy of a row the previous pass
#'   already took.
#' @return The filtered data.frame.
#' @noRd
dedup_fuzzy_targets <- function(best, id_col, taken = character(0L)) {
  if (nrow(best) == 0L)             return(best)
  if (!id_col %in% names(best))     return(best)
  if (!"fuzzy_dist" %in% names(best)) return(best)

  ids <- best[[id_col]]
  d   <- best$fuzzy_dist

  keep <- rep(TRUE, nrow(best))
  # Only fight over rows with non-NA target and non-zero (truly fuzzy) distance.
  candidate <- !is.na(ids) & !is.na(d) & d > 0

  if (length(taken)) {
    already <- candidate & ids %in% taken
    if (any(already)) {
      keep[already] <- FALSE
      candidate     <- candidate & !already
    }
  }

  if (!any(candidate) || nrow(best) == 1L) return(best[keep, , drop = FALSE])

  ord <- order(ids, d, na.last = TRUE)
  ord_keep <- candidate[ord]
  dup_after_first <- duplicated(ids[ord]) & ord_keep
  if (any(dup_after_first)) {
    keep[ord[dup_after_first]] <- FALSE
  }

  best[keep, , drop = FALSE]
}

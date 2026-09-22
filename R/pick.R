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
#   1. status                      (accepted > homotypic placement >
#                                    unreviewed > synonym > misapplied; see
#                                    `.status_rank` and `homotypic_placement()`)
#   2. SPECIES  > higher ranks      (case-tolerant)
#   3. epithet-preserving accepted  (the candidate whose accepted name keeps the
#                                    matched name's specific epithet — the
#                                    homotypic basionym among same-name homonym
#                                    synonyms, e.g. `Pinus abies` L. -> `Picea
#                                    abies` rather than the later homonyms
#                                    `Pinus abies` Thunb. -> `Picea polita` etc.)
#
# OCCURRENCE RECORDS enter twice, on a backbone whose `.vtr` carries an
# `n_occurrences` column (GBIF: the records the data provider files under each
# candidate's key). Between 0 and 1, among the records that keep the name as
# their own concept (accepted, doubtful, unplaced), a key with any records
# beats a key with none: a name GBIF holds as ACCEPTED with no records beside a
# DOUBTFUL record carrying the data is a key nobody can request anything with.
# A synonym record never takes part in that step: its accepted ID is another
# taxon, and a download by it returns that taxon's data, not the name's. Between
# keys that both have records, or both have none, status decides as usual, and
# the count only breaks a tie left after 3 (more records first). A count of 1
# against 5,000 says nothing about which taxon the name denotes, so it never
# overrides status. A missing count is treated as no records at the
# first step and sorts after every known count at the second; a backbone
# without the column scores every row alike.
#
# PUBLICATION YEAR orders after 3 and before the occurrence count: among records
# the concept scores leave level, typically one name published by several
# authors, the earliest is the name itself and the later ones are homonyms,
# which the codes of nomenclature treat as illegitimate. `Absinthium vulgare`
# Lam. (1779, a synonym of `Artemisia absinthium`) outranks the Dulac homonym
# (1867) even though GBIF files more records under the latter. The year is the
# backbone's `year`, else the first year in `name_published_in`; a missing year
# sorts last. Priority decides between homonyms under the botanical code, so the
# year orders only records that share one ICN kingdom; where they span kingdoms
# (`Padia`, a plant and an animal genus) or are animals, whose code protects
# prevailing usage instead, the year is silent and the count decides
# (`year_within_kingdom()`, `.priority_kingdoms`).
#
# ORDERING TIEBREAKS then choose one row inside the best tier, deterministically:
#   4. nomenclaturalStatus = Valid  (when the column is present in the .vtr)
#   5. lowest taxonID
#
# Every distinct accepted ID among the candidates is reported with the pick, in
# candidate order (`accepted_ids`, `n_ids`), whatever tier it sits in, as long
# as it is at the pick's fuzzy distance (see `at_best_distance()`): a name
# the backbone files under several accepted taxa has several keys, and a caller
# requesting data by key needs all of them.
#
# When multiple rows share the best `tier` AND disagree on `accepted_taxon_id`,
# the pick is genuinely ambiguous: the pick carries `is_ambiguous = TRUE` and the
# conflicting accepted IDs in `ambiguous_targets`, which is what the
# abbreviated-genus stage reads to leave a row unresolved rather than guess a
# genus. Neither reaches the `taxify()` output, which reports `accepted_ids`.
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
# place the name elsewhere still counts; and a best row that won only as a
# homotypic placement leaves the unplaced homonym it outranked in the conflict.
# See `in_conflict_scope()`.


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


# Status grade of a name the backbone keeps as its own concept but has not
# placed: WFO's `UNCHECKED`, COL's `PROVISIONALLY ACCEPTED`.
.status_unplaced <- 1L

# Status grade of a synonym record that is homotypic with the accepted name it
# points to (see `homotypic_placement()`). It sits between an accepted record
# and an unplaced one: a record carrying the queried string that the backbone
# places, by its type, under a combination built on it.
.status_homotypic <- 0.5

#' Last epithet of a name, orthographically normalized
#'
#' The epithet that travels with the type when a name is recombined or moved in
#' rank: `orientalis` in both `Lycopsis orientalis` and `Anchusa arvensis subsp.
#' orientalis`. `NA` for a genus-only name or `NA` input.
#'
#' @param names Character vector of taxonomic names.
#' @return Character vector of normalized terminal epithets (or `NA`).
#' @noRd
terminal_epithet_key <- function(names) {
  norm <- normalize_epithets(names)
  ep <- sub("^.*\\s(\\S+)$", "\\1", norm)
  ep[is.na(norm) | !grepl("\\s", norm)] <- NA_character_
  ep
}

#' Is a synonym record homotypic with the accepted name it points to?
#'
#' A recombination cites the author of its basionym in parentheses
#' (`Anchusa arvensis subsp. orientalis (L.) Nordh.`, based on `Lycopsis
#' orientalis L.`) and keeps the basionym's final epithet. A synonym record whose
#' own basionym author -- its parenthetical author, or its whole authorship when
#' it has none -- is the accepted name's parenthetical author, and whose final
#' epithet the accepted name keeps, shares the accepted name's type: the
#' backbone's placement of it is a placement of the name itself, not of a
#' different plant that happens to carry the same string.
#'
#' @param candidates A data.frame carrying `matched_name_std`, `accepted_name`,
#'   `authorship` and `accepted_authorship`.
#' @return Logical vector along the rows, `FALSE` wherever the evidence is
#'   missing.
#' @noRd
homotypic_placement <- function(candidates) {
  n <- nrow(candidates)
  out <- rep(FALSE, n)
  cols <- c("matched_name_std", "accepted_name", "authorship",
            "accepted_authorship")
  if (!all(cols %in% names(candidates))) return(out)
  matched_name        <- as.character(candidates$matched_name_std)
  accepted_name       <- as.character(candidates$accepted_name)
  authorship          <- as.character(candidates$authorship)
  accepted_authorship <- as.character(candidates$accepted_authorship)

  cand <- which(!is.na(authorship) & !is.na(accepted_authorship) &
                  startsWith(trimws(accepted_authorship), "(") &
                  !is.na(matched_name) & !is.na(accepted_name) &
                  matched_name != accepted_name)
  if (length(cand) == 0L) return(out)

  s <- author_key_parts(authorship[cand])
  t <- author_key_parts(accepted_authorship[cand])
  s_basionym <- ifelse(nzchar(s$paren), s$paren, s$terminal)
  ep_s <- terminal_epithet_key(matched_name[cand])
  ep_t <- terminal_epithet_key(accepted_name[cand])

  out[cand] <- !is.na(s_basionym) & nzchar(s_basionym) &
    !is.na(t$paren) & nzchar(t$paren) & s_basionym == t$paren &
    !is.na(ep_s) & !is.na(ep_t) & ep_s == ep_t
  out
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

#' Year a name was published
#'
#' A backbone that records the basionym's year separately (GBIF `bracket_year`,
#' filled for 14% of its records) is read first, since the epithet dates from
#' there; then the record's own year; then the first four-digit year between
#' 1500 and 2099 in the publication reference (`name_published_in`, "Lam.
#' (1779). In: Fl. Franc. 2: 45.").
#'
#' @param year Vector of years (character or numeric), or `NULL`.
#' @param published_in Character vector of publication references, or `NULL`.
#' @param bracket_year Vector of basionym years, or `NULL`.
#' @return Integer vector (`NA` where none gives a year), or `NULL` when every
#'   input is `NULL`.
#' @seealso `year_within_kingdom()`, which decides when the years may order.
#' @noRd
publication_year <- function(year, published_in, bracket_year = NULL) {
  if (is.null(year) && is.null(published_in) && is.null(bracket_year)) {
    return(NULL)
  }
  n <- length(bracket_year %||% year %||% published_in)
  if (!is.null(bracket_year)) {
    basionym <- suppressWarnings(as.integer(substr(as.character(bracket_year),
                                                   1L, 4L)))
  } else {
    basionym <- rep(NA_integer_, n)
  }
  out <- if (is.null(year)) rep(NA_integer_, n) else
    suppressWarnings(as.integer(substr(as.character(year), 1L, 4L)))
  pat <- "(1[5-9][0-9]{2}|20[0-9]{2})"
  fill <- function(out, src) {
    if (is.null(src)) return(out)
    src <- as.character(src)
    need <- is.na(out) & !is.na(src) & grepl(pat, src)
    out[need] <- as.integer(regmatches(src[need], regexpr(pat, src[need])))
    out
  }
  out <- fill(out, published_in)
  out <- ifelse(is.na(basionym), out, basionym)
  out
}


#' Score match candidates by resolution priority
#'
#' Computes the per-row priority scores used to rank backbone candidates for a
#' name (smaller is better): smallest fuzzy distance (`dist_score`), then
#' taxonomic status (`status_score`: accepted, then a synonym homotypic with its
#' accepted name, then a name the backbone keeps but has not reviewed, then any
#' other synonym, then a misapplication), SPECIES over
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
#' A synonym counts as homotypic when its own basionym author is the accepted
#' name's parenthetical author and the accepted name keeps its final epithet
#' (`Lycopsis orientalis` L. -> `Anchusa arvensis subsp. orientalis` (L.)
#' Nordh.). That outranks a record the backbone keeps unplaced under the same
#' string, which is a different type: a homonym, not the name the placed
#' record carries (#81).
#'
#' @param candidates A data.frame with `taxonomicStatus` and `taxonRank`, and
#'   optionally `is_synonym` (the backbone's normalized synonym flag),
#'   `fuzzy_dist` (fuzzy proximity), `nomenclaturalStatus` (validity),
#'   `matched_name_std` and `accepted_name` (epithet preservation), plus
#'   `authorship` and `accepted_authorship` (homotypy).
#' Two scores read the candidate's `n_occurrences` (records filed under its
#' key, a column only the GBIF backbone carries), both 0 throughout when the
#' column is absent and both outside the tier: which key holds the data is not
#' a statement about which taxon the name denotes. `data_score` is 0 for a key
#' with at least one record that keeps the name as its own concept (accepted,
#' doubtful or unplaced; never a synonym, whose accepted ID is another taxon)
#' and 1 otherwise (no records, no count, or a synonym); it orders
#' after `dist_score` and before `status_score`. `occ_score` is minus the count,
#' `Inf` where it is missing; it orders after `epithet_score`, so it only
#' separates keys the concept scores leave level. `year_score` is the year the
#' name was published (the `year` column, else the first year in
#' `name_published_in`; `Inf` where unknown, 0 throughout when both columns are
#' absent); it orders after `epithet_score` and before `occ_score`, so the
#' earliest of several same-name homonyms wins before the count is read.
#'
#' @return A list with the numeric vectors `dist_score`, `data_score`,
#'   `year_score`, `occ_score` and
#'   `status_score`, integer vectors `rank_score`, `valid_score`, `epithet_score`, and the
#'   character `tier` signature (`"dist/status/rank/epithet"`) per row, in input
#'   order.
#' @keywords internal
#' @export
score_candidates <- function(candidates) {
  status_score <- as.numeric(status_score_vec(candidates$taxonomicStatus,
                                              candidates$is_synonym))
  homotypic <- status_score == 2 & homotypic_placement(candidates)
  status_score[homotypic] <- .status_homotypic
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

  # Occurrence records filed under the candidate's key. `data_score` separates
  # a key with records from one without, among the records that keep the name
  # as their own concept (accepted, doubtful, unplaced); a synonym record
  # points to another taxon, whose key would fetch that taxon's data, so it
  # never scores as holding the name's records. `occ_score` (more first) orders keys
  # the concept scores leave level. A missing count is a key the count was not
  # taken for: no evidence of data, and after every known count. Absent column:
  # both uniformly 0.
  occ <- candidates$n_occurrences
  if (!is.null(occ)) {
    occ <- as.numeric(occ)
    own <- status_score <= .status_unplaced & status_score != .status_homotypic
    data_score <- ifelse(own & !is.na(occ) & occ > 0, 0L, 1L)
    occ_score <- -occ
    occ_score[is.na(occ_score)] <- Inf
  } else {
    data_score <- integer(nrow(candidates))
    occ_score <- numeric(nrow(candidates))
  }

  # Priority of publication: among records the concept scores leave level
  # (same-name homonyms by different authors), the earliest-published one is
  # the name itself and a later one a homonym. Unknown year sorts last; absent
  # columns: uniformly 0.
  year_score <- publication_year(candidates$year, candidates$name_published_in,
                                 candidates$bracket_year)
  year_score <- if (is.null(year_score)) {
    numeric(nrow(candidates))
  } else {
    ifelse(is.na(year_score), Inf, as.numeric(year_score))
  }

  tier <- paste(dist_score, status_score, rank_score, epithet_score, sep = "/")
  list(dist_score    = dist_score,
       data_score    = data_score,
       year_score    = year_score,
       occ_score     = occ_score,
       status_score  = status_score,
       rank_score    = rank_score,
       valid_score   = valid_score,
       epithet_score = epithet_score,
       tier          = tier)
}


#' Order match candidates by resolution priority
#'
#' The single source of truth for the candidate sort: the fuzzy distance,
#' whether the key has occurrence records, the remaining concept scores of
#' [score_candidates()] in tier order, the occurrence count, then the
#' nomenclatural-validity tiebreak, then the lowest `taxonID`. Pass `group_col` to sort within groups first, so
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
  grp <- if (is.null(group_col)) NULL else candidates[[group_col]]
  year <- year_within_kingdom(s, candidates$kingdom, grp)
  keys <- list(s$dist_score, s$data_score, s$status_score, s$rank_score,
               s$epithet_score, year, s$occ_score, s$valid_score,
               candidates$taxonID)
  if (!is.null(grp)) keys <- c(list(grp), keys)
  do.call(order, keys)
}


# Kingdoms whose names are governed by the botanical code (ICN), where priority
# of publication decides between homonyms. The zoological code instead protects
# prevailing usage over strict priority (reversal of precedence), and measuring
# bears that out: among animal names where the publication year and the
# occurrence count disagree and a reference backbone names one of the two, the
# count is right 69% of the time against ITIS and 60% against WoRMS, while for
# plants the year wins by 10-17 points against WFO, WCVP and COL. So the year
# orders ICN names only, and animal (and unplaced) names fall to the count.
.priority_kingdoms <- c("PLANTAE", "FUNGI", "CHROMISTA", "PROTOZOA")

#' Publication years, silenced where priority does not decide
#'
#' Priority of publication holds within one code of nomenclature: a plant genus
#' and an animal genus of the same spelling are both legitimate, whichever came
#' first (`Padia` Moritzi, a synonym of `Oryza`, beside `Padia` Gistl). Among
#' the candidates of a group that the preceding scores leave level, the year
#' therefore only orders when they all sit in one kingdom governed by the
#' botanical code (`.priority_kingdoms`); otherwise it is 0 for every one of
#' them and the occurrence count decides.
#'
#' @param s The [score_candidates()] output.
#' @param kingdom Character vector along the candidates, or `NULL`.
#' @param grp Grouping vector along the candidates, or `NULL` for one group.
#' @return Numeric vector: `s$year_score` with the cross-kingdom levels zeroed.
#' @noRd
year_within_kingdom <- function(s, kingdom, grp = NULL) {
  year <- s$year_score
  if (is.null(kingdom) || length(year) == 0L) return(year)
  level <- paste(grp %||% "", s$dist_score, s$data_score, s$status_score,
                 s$rank_score, s$epithet_score, sep = "\r")
  k <- toupper(trimws(as.character(kingdom)))
  ok <- tapply(k, level, function(v) {
    v <- unique(v[!is.na(v) & nzchar(v)])
    length(v) == 1L && v %in% .priority_kingdoms
  })
  year[!ok[level]] <- 0
  year
}


#' Which candidates count when looking for a conflicting accepted target
#'
#' Normally the rows sharing the best row's `tier`: below that tier the backbone
#' has ranked the candidate lower and the pick is settled.
#'
#' Two exceptions. A best row that is only *unplaced* -- a name the backbone
#' lists but has not placed in its taxonomy -- is a non-decision, not a
#' resolution, so a lower-tier record that does place the name somewhere else is
#' a real disagreement and the whole candidate set counts. `Abies douglasii` var.
#' `taxifolia` in WFO is the case: an unplaced record keeping the name and a
#' synonym record sinking it into `Pseudotsuga menziesii`. Preferring the
#' unplaced record keeps the queried plant's name, but the synonymy is the only
#' actual placement on offer, so the caller has to be told it exists (#53).
#'
#' The mirror case is a best row that won as a homotypic placement over an
#' unplaced record of the same string (`Lycopsis orientalis` L. over `Lycopsis
#' orientalis` Steph.). The unplaced record is a different type the backbone
#' keeps, so it stays in the conflict and the caller is told both exist (#81).
#'
#' Vectorized: `best_tier` and `best_status` are the best row's values,
#' broadcast along the candidates they are compared with.
#'
#' @param tier Character tier signature per row, from [score_candidates()].
#' @param status_score Numeric status score per row, from [score_candidates()].
#' @param best_tier,best_status The best row's tier and status score, recycled
#'   along `tier`.
#' @return Logical vector along `tier`.
#' @noRd
in_conflict_scope <- function(tier, status_score, best_tier, best_status) {
  tier == best_tier |
    best_status == .status_unplaced |
    (best_status == .status_homotypic & status_score == .status_unplaced)
}


#' Every distinct accepted ID among each group's candidates, best first
#'
#' @param id Accepted taxon IDs along the candidate rows, already in candidate
#'   order within each group, or `NULL` when the backbone carries none.
#' @param grp Group of each row, in the same order.
#' @return A list of `n_ids` (integer) and `accepted_ids` (`|`-joined,
#'   `NA` where a group has none), both aligned with `unique(grp)`.
#' @noRd
candidate_id_sets <- function(id, grp) {
  ug <- unique(grp)
  if (is.null(id)) {
    return(list(n_ids = rep(NA_integer_, length(ug)),
                accepted_ids = rep(NA_character_, length(ug))))
  }
  id <- as.character(id)
  keep <- !is.na(id) & nzchar(id) &
    !duplicated(data.frame(grp, id, stringsAsFactors = FALSE))
  n <- tabulate(match(grp[keep], ug), length(ug))
  joined <- vapply(split(id[keep], factor(grp[keep], levels = ug)),
                   paste, character(1L), collapse = "|")
  joined[n == 0L] <- NA_character_
  list(n_ids = as.integer(n), accepted_ids = unname(joined))
}


#' Accepted IDs of the candidates at the pick's fuzzy distance
#'
#' The candidates of a fuzzy query are different backbone names; one farther
#' from the input than the pick is a worse reading of it, not another taxon the
#' input names, so its ID is left out of `accepted_ids`. Names at the same
#' distance are equally good readings and stay in. On an exact pass every
#' distance is 0 and nothing is dropped.
#'
#' @param id Accepted IDs along the candidates.
#' @param dist,best_dist Each candidate's distance score and its group's best,
#'   recycled along `id`.
#' @return `id`, `NA` where the candidate is farther than the best, or `NULL`
#'   when `id` is.
#' @noRd
at_best_distance <- function(id, dist, best_dist) {
  if (is.null(id)) return(NULL)
  id[dist != best_dist] <- NA
  id
}


#' Rewrite the pick's position in a result's `accepted_ids`
#'
#' A stage after the pick that moves a row to another accepted taxon (the
#' authorship tiebreak, the basionym resolution) puts that taxon first in the
#' row's `accepted_ids` and recounts `n_ids`, so the set still leads with the
#' `accepted_id` the row reports.
#'
#' @param result The match result data.frame.
#' @param rows Integer rows rewritten.
#' @param new The new accepted ID of each row.
#' @param old The accepted ID each row held before, removed from the set when
#'   `drop_old` is `TRUE`: the basionym stage replaces the unplaced record's own
#'   ID, which no longer names a target, where the authorship tiebreak leaves the
#'   rejected homonym's target in the set as an alternative.
#' @param drop_old Logical.
#' @return `result` with `accepted_ids` and `n_ids` updated on `rows`.
#' @noRd
promote_accepted_id <- function(result, rows, new, old = NULL,
                                drop_old = FALSE) {
  if (length(rows) == 0L || !"accepted_ids" %in% names(result)) return(result)
  ids <- result$accepted_ids[rows]
  sets <- lapply(seq_along(rows), function(k) {
    v <- if (is.na(ids[k])) character(0L) else
      strsplit(ids[k], "|", fixed = TRUE)[[1L]]
    if (drop_old && !is.null(old) && !is.na(old[k])) v <- setdiff(v, old[k])
    unique(c(new[k][!is.na(new[k])], v))
  })
  result$accepted_ids[rows] <- vapply(sets, function(v) {
    if (length(v)) paste(v, collapse = "|") else NA_character_
  }, character(1L))
  result$n_ids[rows] <- lengths(sets)
  result
}


#' Select the best match from a set of candidates
#'
#' @param candidates A data.frame with at least columns `taxonomicStatus`,
#'   `taxonRank`, and `taxonID`. May optionally include `nomenclaturalStatus`
#'   (used to disambiguate homonym synonyms) and `accepted_taxon_id` (used to
#'   detect ambiguous picks and to list every accepted target).
#' @return A single-row data.frame (the best candidate), with added columns
#'   `is_ambiguous` (logical: a tie in the best tier), `ambiguous_targets`
#'   (`|`-joined accepted IDs of that tie, otherwise `NA`), `n_ids` (distinct
#'   accepted IDs among all candidates) and `accepted_ids` (those IDs,
#'   `|`-joined, the pick's first).
#' @noRd
pick_best <- function(candidates) {
  if (nrow(candidates) == 0L) {
    candidates$is_ambiguous <- logical(0L)
    candidates$ambiguous_targets <- character(0L)
    candidates$n_ids <- integer(0L)
    candidates$accepted_ids <- character(0L)
    return(candidates)
  }
  if (nrow(candidates) == 1L) {
    sets <- candidate_id_sets(candidates$accepted_taxon_id, 1L)
    candidates$is_ambiguous <- FALSE
    candidates$ambiguous_targets <- NA_character_
    candidates$n_ids <- sets$n_ids
    candidates$accepted_ids <- sets$accepted_ids
    return(candidates)
  }

  s <- score_candidates(candidates)
  ord <- candidate_order(candidates, s)
  best_idx <- ord[1L]
  sets <- candidate_id_sets(
    at_best_distance(candidates$accepted_taxon_id[ord], s$dist_score[ord],
                     s$dist_score[best_idx]),
    rep(1L, length(ord)))

  # Tier-level ambiguity: rows in the same tier as the best, disagreeing on
  # accepted_taxon_id, widened around unplaced records (see
  # `in_conflict_scope`).
  ambig_targets <- NA_character_
  if ("accepted_taxon_id" %in% names(candidates)) {
    same_tier <- in_conflict_scope(s$tier, s$status_score, s$tier[best_idx],
                                   s$status_score[best_idx])
    ids <- unique(candidates$accepted_taxon_id[same_tier])
    ids <- ids[!is.na(ids)]
    if (length(ids) >= 2L) {
      ambig_targets <- paste(sort(ids), collapse = "|")
    }
  }

  out <- candidates[best_idx, , drop = FALSE]
  out$is_ambiguous <- !is.na(ambig_targets)
  out$ambiguous_targets <- ambig_targets
  out$n_ids <- sets$n_ids
  out$accepted_ids <- sets$accepted_ids
  out
}


#' Vectorized best-match selection: one best row per group
#'
#' Replaces the per-group loop with a single sort + dedup. Honours the same
#' priority as `pick_best()` and reports tier-level ambiguity per group:
#' accepted before a homotypic synonym before unreviewed before any other
#' synonym, SPECIES > higher ranks, then the
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
#'   `is_ambiguous`, `ambiguous_targets`, `n_ids` and `accepted_ids` columns
#'   (see `pick_best()`).
#' @noRd
pick_best_vec <- function(matches, group_col = "row_idx") {
  nr <- nrow(matches)
  if (nr == 0L) {
    matches$is_ambiguous <- logical(0L)
    matches$ambiguous_targets <- character(0L)
    matches$n_ids <- integer(0L)
    matches$accepted_ids <- character(0L)
    return(matches)
  }
  if (nr == 1L) {
    sets <- candidate_id_sets(matches$accepted_taxon_id, 1L)
    matches$is_ambiguous <- FALSE
    matches$ambiguous_targets <- NA_character_
    matches$n_ids <- sets$n_ids
    matches$accepted_ids <- sets$accepted_ids
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

  # Groups come out of candidate_order() contiguous and in first-appearance
  # order of the sorted frame, which is the order `is_first` picks them in.
  sorted_dist <- s$dist_score[ord]
  best_dist <- sorted_dist[is_first][match(sorted[[group_col]],
                                          sorted[[group_col]][is_first])]
  sets <- candidate_id_sets(
    at_best_distance(sorted$accepted_taxon_id, sorted_dist, best_dist),
    sorted[[group_col]])
  sorted$n_ids <- NA_integer_
  sorted$accepted_ids <- NA_character_
  sorted$n_ids[is_first] <- sets$n_ids
  sorted$accepted_ids[is_first] <- sets$accepted_ids

  if ("accepted_taxon_id" %in% names(sorted)) {
    # Per-group best tier signature and status, broadcast to every row of the
    # group, under the same scope rule as pick_best().
    grp_vec   <- sorted[[group_col]]
    best_pos  <- which(is_first)
    grp_best  <- match(grp_vec, grp_vec[is_first])
    same_tier <- in_conflict_scope(sorted_tier, sorted_status,
                                   sorted_tier[best_pos][grp_best],
                                   sorted_status[best_pos][grp_best])

    # A group is ambiguous when its in-scope rows name two or more distinct
    # accepted taxa; the flag and the sorted targets go on its best row.
    st <- which(same_tier & !is.na(sorted$accepted_taxon_id))
    if (length(st) > 0L) {
      g  <- as.character(grp_vec[st])
      id <- sorted$accepted_taxon_id[st]
      keep <- !duplicated(data.frame(g, id, stringsAsFactors = FALSE))
      g <- g[keep]
      id <- id[keep]
      ug <- unique(g)
      amb <- ug[tabulate(match(g, ug), length(ug)) >= 2L]
      if (length(amb) > 0L) {
        in_amb <- g %in% amb
        targets <- vapply(
          split(id[in_amb], factor(g[in_amb], levels = amb)),
          function(v) paste(sort(v), collapse = "|"), character(1L))
        pos <- best_pos[match(amb, as.character(grp_vec[best_pos]))]
        sorted$is_ambiguous[pos] <- TRUE
        sorted$ambiguous_targets[pos] <- unname(targets)
      }
    }
  }

  sorted[is_first, , drop = FALSE]
}

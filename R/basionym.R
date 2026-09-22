# ---- Resolving an unplaced record through its basionym ----
#
# A backbone can hold a combination without placing it (WFO `UNCHECKED`) while
# placing its basionym: `Sabulina tenuifolia` (L.) Rchb. unplaced, its basionym
# `Arenaria tenuifolia` L. a synonym of `Minuartia hybrida`. A combination and
# its basionym share one type, so wherever the backbone puts the basionym it has
# put the combination, and taxify() reports that taxon rather than the unplaced
# name as if it were accepted (#81).
#
# The link is the backbone's own `original_name_usage_id` column. A backbone
# built without it, or an unplaced record carrying none, is left as matched.


#' Find the placed basionym of each unplaced backbone record
#'
#' The one definition of when a basionym places a record, shared by the
#' matching engine and taxifydb's name-lookup build. A record qualifies when the
#' backbone keeps it unplaced (the status grade of `.status_unplaced`) and its
#' `original_name_usage_id` names another record that the backbone places:
#' accepted, or a plain synonym, with an accepted taxon other than the record
#' itself. A basionym that is itself unplaced, misapplied or absent settles
#' nothing.
#'
#' @param records Backbone rows (unified schema) with `taxon_id`,
#'   `taxonomic_status`, `original_name_usage_id` and optionally `is_synonym`.
#' @param basionyms Backbone rows to find the basionyms among, with `taxon_id`,
#'   `taxonomic_status`, `accepted_taxon_id` and optionally `is_synonym`.
#' @return Integer vector along `records`: the row of `basionyms` whose accepted
#'   taxon the record belongs to, or `NA`.
#' @keywords internal
#' @export
basionym_placement <- function(records, basionyms) {
  out <- rep(NA_integer_, nrow(records))
  if (!"original_name_usage_id" %in% names(records) || nrow(basionyms) == 0L) {
    return(out)
  }
  link <- as.character(records$original_name_usage_id)
  own  <- as.character(records$taxon_id)
  unplaced <- status_score_vec(records$taxonomic_status, records$is_synonym) ==
    .status_unplaced
  cand <- which(unplaced & !is.na(link) & nzchar(link) & link != own)
  if (length(cand) == 0L) return(out)

  grade  <- status_score_vec(basionyms$taxonomic_status, basionyms$is_synonym)
  target <- as.character(basionyms$accepted_taxon_id)
  placed <- grade %in% c(0L, 2L) & !is.na(target)
  at <- match(link[cand], ifelse(placed, as.character(basionyms$taxon_id),
                                 NA_character_), incomparables = NA)
  ok <- !is.na(at) & target[at] != own[cand]
  out[cand[ok]] <- at[ok]
  out
}


#' Resolve unplaced matches to the taxon their basionym is placed under
#'
#' Rewrites each matched row whose record [basionym_placement()] places: the
#' accepted columns become the basionym's accepted taxon, `is_synonym = TRUE`
#' and `match_type = "basionym"`. The matched record's own columns
#' (`matched_name`, `taxon_id`, `authorship`, `rank`, `taxonomic_status`) and
#' `fuzzy_dist` stay as they were. A `"rank_fallback"` row keeps its label: the
#' rank it did not reach is the more important thing to report.
#'
#' @param result The match result data.frame.
#' @param vtr_path Path to the backbone `.vtr`.
#' @param col_map Named list mapping logical roles to column names.
#' @return `result`, with basionym-resolved rows rewritten.
#' @noRd
resolve_via_basionym <- function(result, vtr_path, col_map) {
  if (is.null(col_map$basionym) || is.null(result$taxonomic_status)) {
    return(result)
  }
  rows <- which(is_backbone_match(result$match_type) &
                  !result$match_type %in% c("rank_fallback", "basionym") &
                  !is.na(result$taxon_id) &
                  status_score_vec(result$taxonomic_status, result$is_synonym) ==
                    .status_unplaced)
  if (length(rows) == 0L) return(result)

  blk <- backbone_block(vtr_path)
  own <- vectra::block_lookup(blk, col_map$id, unique(result$taxon_id[rows]))
  if (nrow(own) == 0L || !col_map$basionym %in% names(own)) return(result)
  own <- own[match(result$taxon_id[rows], own[[col_map$id]]), , drop = FALSE]

  links <- as.character(own[[col_map$basionym]])
  links <- unique(links[!is.na(links) & nzchar(links)])
  if (length(links) == 0L) return(result)
  bas <- vectra::block_lookup(blk, col_map$id, links)

  at  <- basionym_placement(own, bas)
  hit <- !is.na(at)
  if (!any(hit)) return(result)
  rows   <- rows[hit]
  target <- bas[at[hit], , drop = FALSE]

  result <- promote_accepted_id(result, rows, target$accepted_taxon_id,
                                old = result$accepted_id[rows],
                                drop_old = TRUE)
  result$accepted_id[rows]         <- target$accepted_taxon_id
  result$accepted_name[rows]       <- target$accepted_name
  result$accepted_authorship[rows] <- target$accepted_authorship %||%
    NA_character_
  result$family[rows]              <- target$accepted_family
  result$genus[rows]               <- target$accepted_genus
  result$is_synonym[rows]          <- TRUE
  result$match_type[rows]          <- "basionym"
  result
}

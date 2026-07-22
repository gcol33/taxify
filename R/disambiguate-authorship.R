# ---- Authorship-aware homonym disambiguation ----
#
# A name reused by two authors (Pinus abies L. vs Pinus abies Thunb.) is a
# homonym: the same string points to different accepted taxa. Matching alone
# cannot separate them and flags the row `is_ambiguous`. But the query often
# carries the authorship that settles it. This pass runs only over the ambiguous
# rows whose input carried an author, re-reads the backbone rows for that name
# with their authorship, and -- when the author picks out exactly one accepted
# target -- resolves the row. Rows without an input author, and unambiguous
# rows, are never touched, so the fast path and every existing result are
# unchanged.


#' Resolve ambiguous homonyms by matching input authorship
#'
#' For each row flagged `is_ambiguous` whose input name carried an authorship,
#' re-reads the backbone rows sharing the matched name, compares their authorship
#' to the input's, and if exactly one accepted target survives, rewrites the row
#' to that resolution and clears the ambiguity. Rows with no input author, or
#' where the author does not single out one target, are left as they were.
#'
#' @param result The match result data.frame (post `run_match_stages`).
#' @param vtr_path Path to the backbone `.vtr`.
#' @return `result`, with any author-resolved ambiguous rows rewritten.
#' @noRd
disambiguate_by_authorship <- function(result, vtr_path) {
  if (is.null(result$is_ambiguous) || is.null(result$matched_name)) return(result)
  amb <- which(!is.na(result$is_ambiguous) & result$is_ambiguous &
                 !is.na(result$matched_name) & !is.na(result$input_name))
  if (length(amb) == 0L) return(result)

  auth_in <- normalize_authorship(parse_authorship_vec(result$input_name[amb]))
  have_auth <- !is.na(auth_in)
  amb <- amb[have_auth]
  auth_in <- auth_in[have_auth]
  if (length(amb) == 0L) return(result)

  names_to_look <- unique(result$matched_name[amb])
  joined <- tryCatch(
    backbone_join(
      vtr_path, names_to_look, bb_key = "canonical_name",
      select_cols = c("canonical_name", "authorship", "taxon_id",
                      "accepted_taxon_id", "accepted_name", "is_synonym",
                      "taxon_rank", "accepted_family", "accepted_genus")),
    error = function(e) NULL)
  if (is.null(joined) || nrow(joined) == 0L ||
      !"authorship" %in% names(joined)) return(result)
  joined$auth_key <- normalize_authorship(joined$authorship)

  has_col <- function(nm) nm %in% names(result)

  for (k in seq_along(amb)) {
    i  <- amb[k]
    nm <- result$matched_name[i]
    cand <- joined[joined$lookup == nm, , drop = FALSE]
    if (nrow(cand) == 0L) next

    # Exact author match first; fall back to a substring match either way
    # (an abbreviated author against a fuller citation).
    hit <- which(!is.na(cand$auth_key) & cand$auth_key == auth_in[k])
    if (length(hit) == 0L) {
      hit <- which(!is.na(cand$auth_key) &
                     (mapply(grepl, auth_in[k], cand$auth_key, fixed = TRUE) |
                      mapply(grepl, cand$auth_key, auth_in[k], fixed = TRUE)))
    }
    if (length(hit) == 0L) next

    # Only resolve when the surviving rows agree on one accepted target.
    targets <- unique(cand$accepted_taxon_id[hit])
    targets <- targets[!is.na(targets)]
    if (length(targets) != 1L) next

    w <- hit[1L]
    if (has_col("taxon_id"))       result$taxon_id[i]       <- cand$taxon_id[w]
    if (has_col("authorship"))     result$authorship[i]     <- cand$authorship[w]
    if (has_col("accepted_id"))    result$accepted_id[i]    <- cand$accepted_taxon_id[w]
    if (has_col("accepted_name"))  result$accepted_name[i]  <- cand$accepted_name[w]
    if (has_col("is_synonym"))     result$is_synonym[i]     <- cand$is_synonym[w]
    if (has_col("rank") && "taxon_rank" %in% names(cand))
      result$rank[i] <- tolower(cand$taxon_rank[w])
    # Family/genus of the ACCEPTED taxon. `cand`/`w` is the matched synonym row,
    # so its own family/genus belong to the rejected homonym; embed_accepted()
    # carries the accepted taxon's classification on the accepted_* columns.
    if (has_col("family") && "accepted_family" %in% names(cand))
      result$family[i] <- cand$accepted_family[w]
    if (has_col("genus") && "accepted_genus" %in% names(cand))
      result$genus[i] <- cand$accepted_genus[w]
    result$is_ambiguous[i] <- FALSE
    if (has_col("ambiguous_targets")) result$ambiguous_targets[i] <- NA_character_
  }
  result
}

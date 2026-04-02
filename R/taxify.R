#' Match taxonomic names against local backbone databases
#'
#' Matches a vector of taxonomic names against locally stored Darwin Core
#' backbone databases. Returns a data.frame with one row per input name
#' containing the matched name, accepted name, taxonomic hierarchy, and
#' match quality information.
#'
#' When multiple backends are specified, names are matched against each
#' backend in order. Names matched by an earlier backend are not re-matched
#' by later ones (fallback chain).
#'
#' @param x Character vector of taxonomic names.
#' @param backend Character vector of backend names (e.g., `"wfo"`, `"col"`,
#'   `"gbif"`) or a single `taxify_backend` object. When multiple backends
#'   are given, they are tried in order as a fallback chain. Default `"wfo"`.
#' @param fuzzy Logical. Enable fuzzy matching for names that fail exact
#'   match. Default `TRUE`.
#' @param fuzzy_threshold Numeric 0--1. Maximum normalized string distance
#'   for fuzzy matches. Default `0.2` (roughly 1 edit per 5 characters).
#' @param fuzzy_method Character. One of `"dl"` (Damerau-Levenshtein,
#'   default), `"levenshtein"`, or `"jw"` (Jaro-Winkler).
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A data.frame with one row per input name and 16 columns:
#' \describe{
#'   \item{input_name}{The original name as provided.}
#'   \item{matched_name}{Full name in the backbone that matched.}
#'   \item{accepted_name}{Resolved accepted name (equals `matched_name`
#'     if not a synonym).}
#'   \item{taxon_id}{Backend-specific ID of the matched name.}
#'   \item{accepted_id}{ID of the accepted name.}
#'   \item{rank}{Taxonomic rank (species, subspecies, genus, etc.).}
#'   \item{family}{Family name.}
#'   \item{genus}{Genus name.}
#'   \item{epithet}{Specific epithet.}
#'   \item{authorship}{Authorship of the matched name.}
#'   \item{is_synonym}{Logical. Was the match a synonym?}
#'   \item{is_hybrid}{Logical. Was a hybrid marker detected in the input?}
#'   \item{match_type}{One of `"exact"`, `"exact_ci"`, `"fuzzy"`, or
#'     `"none"`.}
#'   \item{fuzzy_dist}{Normalized string distance (0--1), `NA` if exact.}
#'   \item{backend}{Which backend was used (e.g., `"wfo"`, `"col"`,
#'     `"gbif"`).}
#'   \item{backbone_version}{Backend name, version, and download date
#'     (e.g., `"wfo:2024-12 (2026-04-01)"`). Useful for reproducibility.}
#' }
#'
#' @examples
#' \dontrun{
#' # Match a few names (downloads WFO backbone on first use)
#' taxify(c("Quercus robur", "Pinus sylvestris"))
#'
#' # Disable fuzzy matching
#' taxify("Quercus robus", fuzzy = FALSE)
#'
#' # Fallback chain: try WFO first, then COL for unmatched
#' taxify(c("Quercus robur", "Panthera leo"),
#'        backend = c("wfo", "col"))
#' }
#'
#' @export
taxify <- function(x,
                   backend = "wfo",
                   fuzzy = TRUE,
                   fuzzy_threshold = 0.2,
                   fuzzy_method = c("dl", "levenshtein", "jw"),
                   verbose = TRUE) {

  fuzzy_method <- match.arg(fuzzy_method)

  # Validate input
  if (!is.character(x)) {
    stop("x must be a character vector", call. = FALSE)
  }
  if (length(x) == 0L) {
    stop("x must have at least one element", call. = FALSE)
  }

  # Handle single backend object
  if (inherits(backend, "taxify_backend")) {
    ensure_backends_current(backend$name, verbose = verbose)
    return(taxify_single(x, backend, fuzzy, fuzzy_threshold, fuzzy_method,
                         verbose))
  }

  # Handle character vector of backend names
  if (!is.character(backend) || length(backend) == 0L) {
    stop("backend must be a character vector or taxify_backend object",
         call. = FALSE)
  }

  # Once-per-session version check: auto-downloads if any backend is outdated
  ensure_backends_current(backend, verbose = verbose)

  if (length(backend) == 1L) {
    be <- resolve_backend(backend)
    return(taxify_single(x, be, fuzzy, fuzzy_threshold, fuzzy_method, verbose))
  }

  # Multi-backend fallback chain
  if (verbose) message(sprintf("Matching %d names against %d backends: %s",
                                length(x), length(backend),
                                paste(backend, collapse = " -> ")))

  names_df <- clean_names(x)
  result <- NULL

  for (be_name in backend) {
    be <- resolve_backend(be_name)
    bb_path <- ensure_backbone(be, verbose = verbose)

    if (is.null(result)) {
      # First backend: match all names
      if (verbose) message(sprintf("  [%s] Matching %d names...",
                                    be_name, nrow(names_df)))
      result <- match_exact(be, names_df, bb_path)

      n_unmatched <- sum(is.na(result$match_type) & !is.na(names_df$cleaned))
      if (fuzzy && n_unmatched > 0L) {
        if (verbose) message(sprintf("  [%s] Fuzzy matching %d unmatched...",
                                      be_name, n_unmatched))
        result <- match_fuzzy(be, result, bb_path,
                              method = fuzzy_method,
                              threshold = fuzzy_threshold)
      }

      result <- resolve_synonyms(be, result, bb_path)
      matched <- !is.na(result$match_type)
      result$backend <- ifelse(matched, be$name, NA_character_)
      bb_ver <- format_backbone_version(bb_path, be$name, be$version)
      result$backbone_version[matched] <- bb_ver
    } else {
      # Subsequent backends: only try unmatched names
      unmatched_idx <- which(is.na(result$match_type) &
                             !is.na(result$input_name))
      if (length(unmatched_idx) == 0L) {
        if (verbose) message(sprintf("  [%s] Skipped (all names matched)",
                                      be_name))
        next
      }

      if (verbose) message(sprintf("  [%s] Matching %d remaining names...",
                                    be_name, length(unmatched_idx)))

      # Build a names_df subset for unmatched
      sub_names_df <- data.frame(
        original = names_df$original[unmatched_idx],
        cleaned = names_df$cleaned[unmatched_idx],
        is_hybrid = names_df$is_hybrid[unmatched_idx],
        qualifier = names_df$qualifier[unmatched_idx],
        genus_only = names_df$genus_only[unmatched_idx],
        hybrid_name = names_df$hybrid_name[unmatched_idx],
        stringsAsFactors = FALSE
      )

      sub_result <- match_exact(be, sub_names_df, bb_path)

      n_still_unmatched <- sum(is.na(sub_result$match_type) &
                               !is.na(sub_names_df$cleaned))
      if (fuzzy && n_still_unmatched > 0L) {
        if (verbose) message(sprintf("  [%s] Fuzzy matching %d unmatched...",
                                      be_name, n_still_unmatched))
        sub_result <- match_fuzzy(be, sub_result, bb_path,
                                  method = fuzzy_method,
                                  threshold = fuzzy_threshold)
      }

      sub_result <- resolve_synonyms(be, sub_result, bb_path)

      # Merge sub_result back into main result
      matched_in_sub <- which(!is.na(sub_result$match_type))
      for (j in matched_in_sub) {
        i <- unmatched_idx[j]
        result$matched_name[i] <- sub_result$matched_name[j]
        result$accepted_name[i] <- sub_result$accepted_name[j]
        result$taxon_id[i] <- sub_result$taxon_id[j]
        result$accepted_id[i] <- sub_result$accepted_id[j]
        result$rank[i] <- sub_result$rank[j]
        result$family[i] <- sub_result$family[j]
        result$genus[i] <- sub_result$genus[j]
        result$epithet[i] <- sub_result$epithet[j]
        result$authorship[i] <- sub_result$authorship[j]
        result$is_synonym[i] <- sub_result$is_synonym[j]
        result$match_type[i] <- sub_result$match_type[j]
        result$fuzzy_dist[i] <- sub_result$fuzzy_dist[j]
        result$taxonomicStatus[i] <- sub_result$taxonomicStatus[j]
        result$accepted_id_raw[i] <- sub_result$accepted_id_raw[j]
        result$backend[i] <- be$name
        result$backbone_version[i] <- format_backbone_version(
          bb_path, be$name, be$version
        )
      }
    }
  }

  # Set match_type = "none" for still-unmatched
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  # Drop internal columns
  result$taxonomicStatus <- NULL
  result$accepted_id_raw <- NULL

  # Register enrichment: classify unmatched names as out_of_scope when the
  # genus exists in the register but was not covered by any requested backend
  result <- enrich_with_register(result, names_df, backend)

  rownames(result) <- NULL
  result
}


#' Run the full matching pipeline against a single backend
#'
#' @param x Character vector of names.
#' @param be A taxify_backend object.
#' @param fuzzy Logical.
#' @param fuzzy_threshold Numeric.
#' @param fuzzy_method Character.
#' @param verbose Logical.
#' @return A data.frame with the 16-column output schema.
#' @noRd
taxify_single <- function(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                          verbose) {
  bb_path <- ensure_backbone(be, verbose = verbose)

  if (verbose) message(sprintf("Matching %d names...", length(x)))
  names_df <- clean_names(x)

  result <- match_exact(be, names_df, bb_path)

  n_unmatched <- sum(is.na(result$match_type) & !is.na(names_df$cleaned))
  if (fuzzy && n_unmatched > 0L) {
    if (verbose) message(sprintf("  Fuzzy matching %d unmatched names...",
                                  n_unmatched))
    result <- match_fuzzy(be, result, bb_path,
                          method = fuzzy_method,
                          threshold = fuzzy_threshold)
  }

  result <- resolve_synonyms(be, result, bb_path)

  matched <- !is.na(result$match_type)
  result$backend <- ifelse(matched, be$name, NA_character_)
  result$backbone_version[matched] <- format_backbone_version(
    bb_path, be$name, be$version
  )
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  result$taxonomicStatus <- NULL
  result$accepted_id_raw <- NULL

  # Register enrichment: classify unmatched names as out_of_scope when the
  # genus exists in the register but was not covered by the requested backend
  result <- enrich_with_register(result, names_df, be$name)

  rownames(result) <- NULL
  result
}


#' Enrich unmatched names using the unified genus register
#'
#' For names with `match_type = "none"`, extracts the genus from the cleaned
#' name (or the first word of the input), looks it up in the register, and
#' — if found — sets `match_type = "out_of_scope"` and fills the `life_form`
#' column.
#'
#' Silently skips enrichment if the register is not available (no .vtr on disk
#' and not already loaded in `.taxify_env`).
#'
#' @param result The match result data.frame (after match_type = "none" is set).
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param backend Character scalar or vector of backend names that were tried.
#' @return The result data.frame, possibly with `life_form` column added and
#'   some rows promoted to `match_type = "out_of_scope"`.
#' @noRd
enrich_with_register <- function(result, names_df, backend) {
  # Only proceed if register is available
  reg <- tryCatch({
    if (is.null(.taxify_env$register)) {
      path <- register_vtr_path()
      if (!file.exists(path)) return(result)
      taxify_load_register(verbose = FALSE)
    }
    .taxify_env$register
  }, error = function(e) NULL)

  if (is.null(reg) || nrow(reg) == 0L) return(result)

  # Ensure life_form column exists in result
  if (!"life_form" %in% names(result)) {
    result$life_form <- NA_character_
  }

  # Work only on "none" rows
  none_rows <- which(result$match_type == "none" & !is.na(result$input_name))
  if (length(none_rows) == 0L) return(result)

  # Build genus -> register row lookup (fast: register is a data.frame)
  reg_lookup <- stats::setNames(seq_len(nrow(reg)), reg$genus)

  for (i in none_rows) {
    # Extract genus: first word of cleaned name, or first word of original
    cleaned_name <- names_df$cleaned[i]
    if (!is.na(cleaned_name) && nzchar(cleaned_name)) {
      genus_name <- sub(" .*", "", cleaned_name)
    } else {
      raw <- result$input_name[i]
      if (is.na(raw) || !nzchar(raw)) next
      genus_name <- sub(" .*", "", trimws(raw))
    }

    if (!nzchar(genus_name)) next
    reg_idx <- reg_lookup[genus_name]
    if (is.na(reg_idx)) next

    # Genus is in the register — mark as out_of_scope, fill life_form
    result$match_type[i] <- "out_of_scope"
    result$life_form[i]  <- reg$life_form[reg_idx]
  }

  result
}

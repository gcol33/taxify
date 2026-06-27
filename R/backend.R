# ---- S3 backend interface ----
#
# Each backend (WFO, COL, GBIF) implements these generics.
# Adding a new backend is O(1): define the methods, done.

#' Create a new taxify backend object
#'
#' @param name Character string identifying the backend.
#' @param ... Additional backend-specific fields.
#' @param class Character vector of subclasses.
#' @return A taxify_backend S3 object.
#' @noRd
new_backend <- function(name, ..., class = character()) {
  structure(list(name = name, ...), class = c(class, "taxify_backend"))
}


#' Download a backbone database
#'
#' Downloads the latest Darwin Core snapshot for the specified backend and
#' converts it to vectra's `.vtr` format for fast repeated queries.
#'
#' Always re-downloads the latest release, overwriting any existing backbone.
#' Use [taxify()] for day-to-day matching — it auto-downloads on first use
#' and reuses the local copy thereafter.
#'
#' @param backend A `taxify_backend` object or a character string
#'   (e.g., `"wfo"`).
#' @param dest Character. Destination directory. Defaults to
#'   [taxify_data_dir()].
#' @param verbose Logical. Print progress messages.
#' @param ... Additional arguments passed to methods.
#' @return The path to the `.vtr` file (invisibly).
#' @export
taxify_download <- function(backend, dest = NULL, verbose = TRUE, ...) {
  if (is.character(backend)) {
    backend <- resolve_backend(backend)
    return(taxify_download(backend, dest = dest, verbose = verbose, ...))
  }
  UseMethod("taxify_download")
}


#' Load a backbone into memory
#'
#' @param backend A taxify_backend object.
#' @param path Character. Path to the .vtr file. If NULL, uses the default
#'   location from [taxify_data_dir()].
#' @param ... Additional arguments passed to methods.
#' @return A vectra node (lazy handle to the backbone).
#' @noRd
taxify_load <- function(backend, path = NULL, ...) {
  UseMethod("taxify_load")
}


#' Exact matching against a backbone
#'
#' @param backend A taxify_backend object.
#' @param names_df A data.frame with columns `original` and `cleaned`.
#' @param backbone Path to the compiled backbone .vtr file.
#' @param ... Additional arguments passed to methods.
#' @return A data.frame of matches.
#' @noRd
match_exact <- function(backend, names_df, backbone, ...) {
  UseMethod("match_exact")
}


#' Fuzzy matching against a backbone
#'
#' @param backend A taxify_backend object.
#' @param unmatched_df A data.frame of names that failed exact matching.
#' @param backbone Path to backbone .vtr file.
#' @param method Character. Distance algorithm.
#' @param threshold Numeric. Maximum normalized distance.
#' @param names_df Optional data.frame from `clean_names()` with pre-cleaned
#'   names. When provided, avoids redundant per-name `clean_one()` calls.
#' @param ... Additional arguments passed to methods.
#' @return A data.frame of fuzzy matches.
#' @noRd
match_fuzzy <- function(backend, unmatched_df, backbone,
                        method = "dl", threshold = 0.2,
                        names_df = NULL, region = NULL,
                        range_mode = "present", ...) {
  UseMethod("match_fuzzy")
}


# ------------------------------------------------------------------
# Default S3 methods — shared across all backends
# ------------------------------------------------------------------

#' @exportS3Method
taxify_load.taxify_backend <- function(backend, path = NULL, ...) {
  name <- backend$name
  path <- path %||% file.path(taxify_data_dir(), paste0(name, ".vtr"))
  if (!file.exists(path)) {
    stop(sprintf(
      "%s backbone not found at: %s\nRun taxify_download('%s') first.",
      toupper(name), path, name
    ), call. = FALSE)
  }
  path
}


#' @exportS3Method
match_exact.taxify_backend <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, backend$col_map)
}


#' @exportS3Method
match_fuzzy.taxify_backend <- function(backend, unmatched_df, backbone,
                                       method = "dl", threshold = 0.2,
                                       names_df = NULL, region = NULL,
                                       range_mode = "present", ...) {
  bb_path <- backbone
  result  <- unmatched_df
  col_map <- backend$col_map

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw' (Jaro-Winkler range is 0-1)")
  }

  result <- fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                                 col_map, region = region,
                                 range_mode = range_mode)

  if (isTRUE(backend$prefix_fallback)) {
    result <- fuzzy_match_prefix_blocked(result, names_df, bb_path, method,
                                         threshold, col_map, region = region,
                                         range_mode = range_mode)
  }

  result
}


# ------------------------------------------------------------------
# Shared compiled matching engine
# ------------------------------------------------------------------

#' Embed accepted taxon info at build time (synonym self-join)
#'
#' Used by the `taxifydb` build pipeline and by taxify's own test fixtures.
#' For every synonym row, resolves the accepted taxon and embeds its name,
#' family, genus, and (when `authorship_col` is supplied) authorship directly.
#' Handles synonym chains by iterating until stable (max 10 hops).
#'
#' @param df The full backbone data.frame.
#' @param id_col Name of the taxon ID column.
#' @param acc_id_col Name of the accepted name usage ID column.
#' @param name_col Name of the canonical name column.
#' @param family_col Name of the family column.
#' @param genus_col Name of the genus column.
#' @param status_col Name of the taxonomic status column.
#' @param synonym_pattern Regex pattern to detect synonyms in status column.
#' @param authorship_col Optional name of the authorship column. When supplied,
#'   the resolved accepted name's authorship is embedded as
#'   `accepted_authorship` (so a synonym row carries the accepted taxon's
#'   author, not its own). When `NULL`, `accepted_authorship` is filled with
#'   `NA`.
#' @return The data.frame with added columns: accepted_name, accepted_family,
#'   accepted_genus, accepted_taxon_id, accepted_authorship, is_synonym.
#' @keywords internal
#' @export
embed_accepted <- function(df, id_col, acc_id_col, name_col, family_col,
                           genus_col, status_col,
                           synonym_pattern = "SYNONYM",
                           authorship_col = NULL) {
  n <- nrow(df)

  # Detect synonyms
  is_syn <- !is.na(df[[status_col]]) &
    grepl(synonym_pattern, df[[status_col]])

  # Default: accepted = self

  have_auth <- !is.null(authorship_col) && authorship_col %in% names(df)

  df$accepted_name       <- df[[name_col]]
  df$accepted_family     <- df[[family_col]]
  df$accepted_genus      <- df[[genus_col]]
  df$accepted_taxon_id   <- df[[id_col]]
  df$accepted_authorship <- if (have_auth) df[[authorship_col]] else NA_character_
  df$is_synonym          <- FALSE

  # Build ID → row index lookup
  id_to_row <- match(df[[acc_id_col]], df[[id_col]])

  # One-hop resolution
  resolved <- is_syn & !is.na(id_to_row)
  if (any(resolved)) {
    target_rows <- id_to_row[resolved]
    df$accepted_name[resolved]     <- df[[name_col]][target_rows]
    df$accepted_family[resolved]   <- df[[family_col]][target_rows]
    df$accepted_genus[resolved]    <- df[[genus_col]][target_rows]
    df$accepted_taxon_id[resolved] <- df[[id_col]][target_rows]
    if (have_auth)
      df$accepted_authorship[resolved] <- df[[authorship_col]][target_rows]
    df$is_synonym[resolved]        <- TRUE
  }

  # Unresolvable synonyms (accepted ID not found): keep as synonym, self-ref
  unresolved_syn <- is_syn & !resolved
  df$is_synonym[unresolved_syn] <- TRUE

  # Chase synonym chains: if accepted target is itself a synonym, follow
  for (iter in seq_len(10L)) {
    # Find rows where our accepted target is also a synonym
    acc_rows <- match(df$accepted_taxon_id, df[[id_col]])
    chain <- df$is_synonym &
      !is.na(acc_rows) &
      df$is_synonym[acc_rows] &  # target is also a synonym
      df$accepted_taxon_id != df[[id_col]]  # not self-referencing

    # Remove NAs
    chain[is.na(chain)] <- FALSE
    if (!any(chain)) break

    # Follow one more hop via the target's accepted_taxon_id
    chain_target <- acc_rows[chain]
    next_acc_id <- df$accepted_taxon_id[chain_target]
    next_row <- match(next_acc_id, df[[id_col]])
    has_next <- !is.na(next_row)

    if (!any(has_next)) break
    chain_idx <- which(chain)[has_next]
    next_row <- next_row[has_next]

    df$accepted_name[chain_idx]     <- df[[name_col]][next_row]
    df$accepted_family[chain_idx]   <- df[[family_col]][next_row]
    df$accepted_genus[chain_idx]    <- df[[genus_col]][next_row]
    df$accepted_taxon_id[chain_idx] <- df[[id_col]][next_row]
    if (have_auth)
      df$accepted_authorship[chain_idx] <- df[[authorship_col]][next_row]
  }

  df
}


#' Precompute matching keys at build time
#'
#' Used by the `taxifydb` build pipeline and by taxify's own test fixtures.
#' Adds `key_ci`, `key_normalized`, `key_species`, and `fuzzy_block` columns
#' to the backbone data.frame for direct lookup at query time.
#'
#' @param df The backbone data.frame.
#' @param name_col Name of the canonical name column.
#' @param genus_col Name of the genus column.
#' @param epithet_col Name of the specific epithet column.
#' @return The data.frame with added key columns.
#' @keywords internal
#' @export
precompute_keys <- function(df, name_col, genus_col, epithet_col) {
  df$key_ci <- tolower(df[[name_col]])
  df$key_normalized <- normalize_epithets(df[[name_col]])

  # key_species: "Genus epithet" for infraspecific names (3+ words)
  # Allows fallback from "Genus epithet var. foo" to "Genus epithet"
  has_genus <- !is.na(df[[genus_col]]) & nzchar(df[[genus_col]])
  has_epithet <- !is.na(df[[epithet_col]]) & nzchar(df[[epithet_col]])
  df$key_species <- ifelse(
    has_genus & has_epithet,
    paste(df[[genus_col]], df[[epithet_col]]),
    NA_character_
  )

  # Compound fuzzy blocking key: genus + first 2 chars of epithet (lowered).
  # Splits large genera (Hieracium: 31k → ~1k per sub-block) for faster
  # fuzzy_join while preserving full quality via genus-only fallback.
  ep_prefix <- ifelse(has_epithet,
                       tolower(substr(df[[epithet_col]], 1L, 2L)), "")
  df$fuzzy_block <- paste0(tolower(df[[genus_col]]), ":", ep_prefix)

  df
}


#' Shared exact matching against a compiled backbone
#'
#' All backends delegate to this function. Uses inner_join with temp .vtr
#' query tables for index-accelerated matching. Accepted info is read
#' directly from precomputed columns.
#'
#' @param result The match result data.frame (from `empty_match_result()`).
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr.
#' @param col_map Named list mapping logical roles to column names.
#' @return The updated result data.frame.
#' @noRd
match_exact_compiled <- function(result, names_df, bb_path, col_map) {
  cleaned    <- names_df$cleaned
  genus_only <- names_df$genus_only
  has_name   <- !is.na(cleaned)
  hybrid_name <- names_df$hybrid_name
  n <- nrow(names_df)

  if (!any(has_name)) return(result)

  name_col  <- col_map$name
  genus_col <- col_map$genus

  # --- Materialize backbone (cached per session) ---
  cache_key <- paste0(".blk_", basename(bb_path))
  blk <- .taxify_env[[cache_key]]
  if (is.null(blk)) {
    blk <- vectra::materialize(vectra::tbl(bb_path))
    .taxify_env[[cache_key]] <- blk
  }

  # Helper: block_lookup → attach row_idx and feed to fill_compiled_matches
  lookup_and_fill <- function(result, keys, row_indices, column, match_type,
                              ci = FALSE) {
    hits <- vectra::block_lookup(blk, column, keys, ci = ci)
    if (nrow(hits) == 0L) return(result)
    # Map query_idx (1-based into keys) to original row_idx
    hits$row_idx <- row_indices[hits$query_idx]
    hits$query_idx <- NULL
    fill_compiled_matches(result, hits, match_type, col_map)
  }

  # --- Pass A: Aggregate taxon (preserve mode) ---
  # For aggregate-concept inputs, match the dedicated aggregate taxon
  # ("<binomial> aggr.") before falling back to the binomial species. agg_key is
  # populated only in preserve mode; NA (or absent) otherwise, so this pass is a
  # no-op under aggregates = "collapse".
  agg_key <- names_df$agg_key
  if (!is.null(agg_key)) {
    agg_mask <- has_name & !is.na(agg_key) & is.na(result$match_type)
    if (any(agg_mask)) {
      result <- lookup_and_fill(result, agg_key[agg_mask], which(agg_mask),
                                name_col, "exact")
    }
  }

  # --- Pass 0: Genus-only ---
  genus_mask <- has_name & genus_only & is.na(result$match_type)
  if (any(genus_mask)) {
    result <- lookup_and_fill(result, cleaned[genus_mask], which(genus_mask),
                              name_col, "exact")
  }

  # --- Pass 1: Hybrid names (nothospecies form: "Genus × epithet") ---
  hybrid_mask <- has_name & !genus_only & !is.na(hybrid_name) &
    is.na(result$match_type)
  if (any(hybrid_mask)) {
    result <- lookup_and_fill(result, hybrid_name[hybrid_mask],
                              which(hybrid_mask), name_col, "exact")
  }

  # --- Pass 2: Exact (case-sensitive) ---
  exact_mask <- has_name & !genus_only & is.na(result$match_type)
  if (any(exact_mask)) {
    result <- lookup_and_fill(result, cleaned[exact_mask], which(exact_mask),
                              name_col, "exact")
  }

  # --- Pass 3: Case-insensitive ---
  ci_mask <- has_name & !genus_only & is.na(result$match_type)
  if (any(ci_mask)) {
    result <- lookup_and_fill(result, tolower(cleaned[ci_mask]), which(ci_mask),
                              "key_ci", "exact_ci")
  }

  # Precompute word counts once (used by pass 4 and 5)
  # Counting spaces is faster than strsplit
  word_count <- rep(1L, n)
  word_count[has_name] <- nchar(gsub("[^ ]", "", cleaned[has_name])) + 1L

  # --- Pass 4: Latin orthographic normalization ---
  norm_mask <- has_name & is.na(result$match_type)
  if (any(norm_mask)) {
    norm_idx   <- which(norm_mask)
    norm_names <- cleaned[norm_mask]

    norm_plain  <- normalize_epithets(norm_names)
    norm_hybrid <- ifelse(!is.na(hybrid_name[norm_mask]),
                          normalize_epithets(hybrid_name[norm_mask]),
                          NA_character_)
    wc_sub <- word_count[norm_mask]
    norm_species <- ifelse(
      wc_sub >= 3L,
      normalize_epithets(sub("^(\\S+\\s+\\S+)\\s+.*$", "\\1", norm_names)),
      NA_character_
    )

    has_hyb <- !is.na(norm_hybrid)
    has_sp  <- !is.na(norm_species)
    nk_ridx <- c(norm_idx, norm_idx[has_hyb], norm_idx[has_sp])
    nk_keys <- c(norm_plain, norm_hybrid[has_hyb], norm_species[has_sp])
    valid_nk <- !is.na(nk_keys)
    nk_ridx  <- nk_ridx[valid_nk]
    nk_keys  <- nk_keys[valid_nk]

    if (length(nk_keys) > 0L) {
      result <- lookup_and_fill(result, nk_keys, nk_ridx,
                                "key_normalized", "exact_ci")
    }
  }

  # --- Pass 5: Infraspecific-to-species fallback ---
  inf_mask <- has_name & is.na(result$match_type) & word_count >= 3L
  if (any(inf_mask)) {
    sp_names <- sub("^(\\S+\\s+\\S+)\\s+.*$", "\\1", cleaned[inf_mask])
    result <- lookup_and_fill(result, sp_names, which(inf_mask),
                              name_col, "exact")
  }

  result
}


#' Standardize backbone columns for pick_best_vec
#'
#' Maps backend-specific column names (via `col_map`) onto the generic column
#' names `pick_best_vec()` / `score_candidates()` expect: `taxonID`,
#' `taxonRank`, `taxonomicStatus`, and `matched_name_std` (the matched
#' backbone name, used for the epithet-preservation tiebreak).
#'
#' @param matches Collected query output.
#' @param col_map Named list mapping logical roles to column names.
#' @return `matches` with the standardized columns added.
#' @noRd
standardize_pick_cols <- function(matches, col_map) {
  matches$taxonID         <- matches[[col_map$id]]
  matches$taxonRank       <- matches[[col_map$rank]]
  matches$taxonomicStatus <- matches[[col_map$status]]
  matches$matched_name_std <-
    if (!is.null(col_map$name) && col_map$name %in% names(matches)) {
      matches[[col_map$name]]
    } else {
      NA_character_
    }
  matches
}


#' Fill match results from compiled backbone (vectorized)
#'
#' Reads accepted info directly from precomputed backbone columns.
#' No synonym resolution pass needed.
#'
#' @param result Match result data.frame (modified in parent frame).
#' @param matches Collected query output with row_idx column.
#' @param match_type "exact" or "exact_ci".
#' @param col_map Named list mapping logical roles to column names.
#' @param name_col_override If set, use this column for matched_name instead
#'   of col_map$name.
#' @noRd
fill_compiled_matches <- function(result, matches, match_type, col_map) {
  matches <- standardize_pick_cols(matches, col_map)

  best <- pick_best_vec(matches)
  idx <- best$row_idx

  # Only fill rows not already matched
  new_match <- is.na(result$match_type[idx])
  if (!any(new_match)) return(result)
  idx <- idx[new_match]
  best <- best[new_match, , drop = FALSE]

  result$matched_name[idx]      <- best[[col_map$name]]
  result$taxon_id[idx]          <- best[[col_map$id]]
  result$rank[idx]              <- tolower(best[[col_map$rank]])
  result$family[idx]            <- best$accepted_family
  result$genus[idx]             <- best$accepted_genus
  result$epithet[idx]           <- best[[col_map$epithet]]
  result$authorship[idx]        <- best[[col_map$authorship]]
  result$accepted_authorship[idx] <- best$accepted_authorship %||% NA_character_
  result$accepted_name[idx]     <- best$accepted_name
  result$accepted_id[idx]       <- best$accepted_taxon_id
  result$is_synonym[idx]        <- best$is_synonym
  result$match_type[idx]        <- match_type
  result$fuzzy_dist[idx]        <- NA_real_
  result$is_ambiguous[idx]      <- best$is_ambiguous %||% FALSE
  result$ambiguous_targets[idx] <- best$ambiguous_targets %||% NA_character_

  result
}


# ------------------------------------------------------------------
# Shared fuzzy matching via vectra::fuzzy_join()
# ------------------------------------------------------------------

#' Run fuzzy matching using vectra's C-level fuzzy_join with OpenMP
#'
#' Shared implementation for all backends. Builds a query .vtr from unmatched
#' rows, runs a genus-blocked fuzzy_join against the backbone, picks the best
#' match per input name, and fills the result data.frame.
#'
#' @param result The match result data.frame (from match_exact).
#' @param names_df Optional data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr file.
#' @param method Character. Distance algorithm.
#' @param threshold Numeric. Maximum normalized distance.
#' @param col_map Named list mapping logical roles to backbone column names.
#' @return The updated result data.frame.
#' @noRd
fuzzy_match_via_join <- function(result, names_df, bb_path, method, threshold,
                                 col_map, region = NULL,
                                 range_mode = "present") {
  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))
  if (length(unmatched_rows) == 0L) return(result)

  # Build cleaned names and genera for unmatched rows
  if (!is.null(names_df)) {
    cleaned_names <- names_df$cleaned[unmatched_rows]
    cleaned_names <- ifelse(!is.na(cleaned_names) & nzchar(cleaned_names),
                            cleaned_names, NA_character_)
  } else {
    cleaned_names <- vapply(unmatched_rows, function(i) {
      cl <- clean_one(result$input_name[i])$cleaned
      if (!is.na(cl) && nzchar(cl)) cl else NA_character_
    }, character(1L))
  }

  genera <- ifelse(!is.na(cleaned_names), sub(" .*", "", cleaned_names),
                   NA_character_)

  valid <- !is.na(cleaned_names)
  if (!any(valid)) return(result)

  query_df <- data.frame(
    row_idx = unmatched_rows[valid],
    cleaned_name = cleaned_names[valid],
    query_genus = genera[valid],
    stringsAsFactors = FALSE
  )

  # --- Pre-filter backbone via block_lookup ---
  # Instead of fuzzy_join against the full backbone (6.4M rows, slow
  # materialization), use the already-materialized block to extract only
  # candidate rows for the relevant genera. This reduces the fuzzy_join
  # right side from millions of rows to thousands.
  cache_key <- paste0(".blk_", basename(bb_path))
  blk <- .taxify_env[[cache_key]]
  if (is.null(blk)) {
    blk <- vectra::materialize(vectra::tbl(bb_path))
    .taxify_env[[cache_key]] <- blk
  }

  unique_genera <- unique(query_df$query_genus)
  unique_genera <- unique_genera[!is.na(unique_genera)]
  candidates <- vectra::block_lookup(blk, col_map$genus, unique_genera,
                                     ci = TRUE)
  if (nrow(candidates) == 0L) return(result)

  # Write small candidate set to temp .vtr for fuzzy_join
  tmp_candidates <- tempfile(fileext = ".vtr")
  tmp_query <- tempfile(fileext = ".vtr")
  on.exit(unlink(c(tmp_candidates, tmp_query)), add = TRUE)
  vectra::write_vtr(candidates, tmp_candidates)
  vectra::write_vtr(query_df, tmp_query)

  by_vec <- stats::setNames(col_map$name, "cleaned_name")
  block_vec <- stats::setNames(col_map$genus, "query_genus")

  matches <- tryCatch(
    vectra::fuzzy_join(
      vectra::tbl(tmp_query),
      vectra::tbl(tmp_candidates),
      by = by_vec,
      method = method,
      max_dist = threshold,
      block_by = block_vec,
      n_threads = 4L
    ) |> vectra::collect(),
    error = function(e) data.frame()
  )

  if (nrow(matches) > 0L) {
    matches <- standardize_pick_cols(matches, col_map)
    matches <- filter_fuzzy_by_region(matches, region, range_mode)
  }

  if (nrow(matches) > 0L) {
    best <- pick_best_vec(matches)
    best <- dedup_fuzzy_targets(best, id_col = col_map$id)
    idx <- best$row_idx
    result$matched_name[idx]      <- best[[col_map$name]]
    result$taxon_id[idx]          <- best[[col_map$id]]
    result$rank[idx]              <- tolower(best[[col_map$rank]])
    result$accepted_name[idx]     <- best$accepted_name
    result$accepted_id[idx]       <- best$accepted_taxon_id
    result$family[idx]            <- best$accepted_family
    result$genus[idx]             <- best$accepted_genus
    result$epithet[idx]           <- best[[col_map$epithet]]
    result$authorship[idx]        <- best[[col_map$authorship]]
    result$accepted_authorship[idx] <- best$accepted_authorship %||% NA_character_
    result$is_synonym[idx]        <- best$is_synonym
    result$match_type[idx]        <- "fuzzy"
    result$fuzzy_dist[idx]        <- best$fuzzy_dist
    result$is_ambiguous[idx]      <- best$is_ambiguous %||% FALSE
    result$ambiguous_targets[idx] <- best$ambiguous_targets %||% NA_character_
  }

  result
}


#' Get or create a compact backbone .vtr for fuzzy matching
#'
#' Selects only the columns needed for matching (no extra WFO/COL columns),
#' writes to a temp .vtr once per session. Sorted by genus for zone-map
#' pruning. Much smaller than the full backbone -> faster fuzzy_join I/O.
#'
#' @param bb_path Path to the full backbone .vtr.
#' @param col_map Named list mapping logical roles to column names.
#' @return Path to the compact .vtr (cached per session).
#' @noRd
get_fuzzy_bb <- function(bb_path, col_map) {
  cache_key <- paste0(".fuzzy_bb_", basename(bb_path))
  cached <- .taxify_env[[cache_key]]
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # Select only columns needed for matching + accepted info.
  # fuzzy_block is precomputed at build time by precompute_keys().
  keep_cols <- unique(c(
    col_map$name, col_map$genus, col_map$id, col_map$rank,
    col_map$status, col_map$epithet, col_map$authorship,
    "accepted_name", "accepted_family", "accepted_genus",
    "accepted_taxon_id", "accepted_authorship", "is_synonym", "fuzzy_block"
  ))

  # Drop any columns a pre-accepted_authorship backbone .vtr does not carry,
  # so selection stays valid against older downloads.
  available <- names(vectra::collect(utils::head(vectra::tbl(bb_path), 1L)))
  keep_cols <- intersect(keep_cols, available)

  fuzzy_path <- tempfile(fileext = ".vtr")
  vectra::tbl(bb_path) |>
    vectra::select(!!!lapply(keep_cols, as.name)) |>
    vectra::write_vtr(fuzzy_path, batch_size = 50000L)

  .taxify_env[[cache_key]] <- fuzzy_path
  fuzzy_path
}


#' Prefix-blocked fuzzy fallback for misspelled genera
#'
#' After genus-blocked fuzzy matching, names with a misspelled genus remain
#' unmatched, because the genus block never pulled their candidates. This pass
#' re-blocks on the first 2 characters of the name instead of the genus, so a
#' genus typo that preserves those 2 characters can still match. Typos in the
#' first 2 characters are not caught. The query side is the full backbone (via
#' `get_fuzzy_bb`), kept tractable by the prefix block.
#'
#' @param result The match result data.frame.
#' @param names_df Data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr file.
#' @param method Character. Distance algorithm.
#' @param threshold Numeric. Maximum normalized distance.
#' @param col_map Named list mapping logical roles to backbone column names.
#' @return The updated result data.frame.
#' @noRd
fuzzy_match_prefix_blocked <- function(result, names_df, bb_path, method,
                                       threshold, col_map, region = NULL,
                                       range_mode = "present") {
  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))
  if (length(unmatched_rows) == 0L) return(result)

  if (!is.null(names_df)) {
    cleaned_names <- names_df$cleaned[unmatched_rows]
    cleaned_names <- ifelse(!is.na(cleaned_names) & nzchar(cleaned_names),
                            cleaned_names, NA_character_)
  } else {
    cleaned_names <- vapply(unmatched_rows, function(i) {
      cl <- clean_one(result$input_name[i])$cleaned
      if (!is.na(cl) && nzchar(cl)) cl else NA_character_
    }, character(1L))
  }

  valid <- !is.na(cleaned_names)
  if (!any(valid)) return(result)

  # Use 2-char prefix blocking to reduce search space while still catching
  # misspelled genera (most genus typos preserve the first 2 characters).
  # This fallback handles few names (<5% of fuzzy candidates), so the
  # full backbone materialization via get_fuzzy_bb is acceptable.
  query_df <- data.frame(
    row_idx = unmatched_rows[valid],
    cleaned_name = cleaned_names[valid],
    query_prefix = tolower(substr(cleaned_names[valid], 1L, 2L)),
    stringsAsFactors = FALSE
  )

  tmp_query <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_query), add = TRUE)
  vectra::write_vtr(query_df, tmp_query)

  by_vec <- stats::setNames(col_map$name, "cleaned_name")
  block_vec <- stats::setNames("key_prefix", "query_prefix")

  fuzzy_bb <- get_fuzzy_bb(bb_path, col_map)
  prefix_expr <- substitute(
    tolower(substr(COL, 1L, 2L)),
    list(COL = as.name(col_map$name))
  )
  matches <- tryCatch(
    vectra::fuzzy_join(
      vectra::tbl(tmp_query),
      vectra::tbl(fuzzy_bb) |>
        vectra::mutate(key_prefix = !!prefix_expr),
      by = by_vec,
      method = method,
      max_dist = threshold,
      block_by = block_vec,
      n_threads = 4L
    ) |> vectra::collect(),
    error = function(e) data.frame()
  )

  if (nrow(matches) > 0L) {
    matches <- standardize_pick_cols(matches, col_map)
    matches <- filter_fuzzy_by_region(matches, region, range_mode)
  }

  if (nrow(matches) > 0L) {
    best <- pick_best_vec(matches)
    best <- dedup_fuzzy_targets(best, id_col = col_map$id)
    idx <- best$row_idx
    result$matched_name[idx]      <- best[[col_map$name]]
    result$taxon_id[idx]          <- best[[col_map$id]]
    result$rank[idx]              <- tolower(best[[col_map$rank]])
    result$accepted_name[idx]     <- best$accepted_name
    result$accepted_id[idx]       <- best$accepted_taxon_id
    result$family[idx]            <- best$accepted_family
    result$genus[idx]             <- best$accepted_genus
    result$epithet[idx]           <- best[[col_map$epithet]]
    result$authorship[idx]        <- best[[col_map$authorship]]
    result$accepted_authorship[idx] <- best$accepted_authorship %||% NA_character_
    result$is_synonym[idx]        <- best$is_synonym
    result$match_type[idx]        <- "fuzzy"
    result$fuzzy_dist[idx]        <- best$fuzzy_dist
    result$is_ambiguous[idx]      <- best$is_ambiguous %||% FALSE
    result$ambiguous_targets[idx] <- best$ambiguous_targets %||% NA_character_
  }

  result
}


#' Resolve abbreviated-genus names via genus initial plus epithet
#'
#' Handles inputs such as `"Q. robur"`, where the genus is given as a single
#' initial. These never match the exact or genus-blocked fuzzy passes, because
#' no genus is literally named `"Q."`. This stage restricts the backbone to
#' rows whose genus starts with the initial and whose specific epithet matches,
#' then resolves only when that yields a single accepted taxon. When two or
#' more genera with the initial share the epithet the abbreviation is genuinely
#' ambiguous: the row is left unmatched (`match_type` stays `NA`, becoming
#' `"none"`) with `is_ambiguous = TRUE` and the conflicting accepted IDs in
#' `ambiguous_targets`, rather than guessing a genus.
#'
#' Disambiguation prefers a genus the author spelled out in full elsewhere in
#' the same input (the convention of abbreviating after first mention): when a
#' candidate genus also appears unabbreviated in the batch, only those
#' candidates are kept.
#'
#' @param backend A taxify_backend object (supplies `col_map`).
#' @param result The match result data.frame (from match_exact).
#' @param names_df Data.frame from `clean_names()`, carrying `genus_abbrev`.
#' @param backbone Path to the compiled backbone .vtr file.
#' @return The updated result data.frame.
#' @noRd
match_abbrev_genus <- function(backend, result, names_df, backbone) {
  col_map <- backend$col_map
  if (is.null(names_df$genus_abbrev)) return(result)

  rows <- which(is.na(result$match_type) & !is.na(result$input_name) &
                names_df$genus_abbrev %in% TRUE)
  if (length(rows) == 0L) return(result)

  cleaned <- names_df$cleaned[rows]
  initial <- tolower(substr(cleaned, 1L, 1L))
  epithet <- tolower(sub("^\\S+\\s+(\\S+).*$", "\\1", cleaned))

  # Genera the author spelled out in full elsewhere in this batch (multi-letter
  # first tokens, no abbreviating period) — used to disambiguate by intent.
  first_tok <- sub(" .*", "", names_df$cleaned)
  spelled <- tolower(first_tok[!is.na(first_tok) & nchar(first_tok) > 1L &
                               !grepl(".", first_tok, fixed = TRUE)])

  # Materialized backbone (shared session cache with the exact/fuzzy passes).
  cache_key <- paste0(".blk_", basename(backbone))
  blk <- .taxify_env[[cache_key]]
  if (is.null(blk)) {
    blk <- vectra::materialize(vectra::tbl(backbone))
    .taxify_env[[cache_key]] <- blk
  }

  # Pull candidate rows by epithet via the same block-lookup the exact pass
  # uses, then constrain each query to its genus initial in R.
  cand_all <- vectra::block_lookup(blk, col_map$epithet, unique(epithet),
                                   ci = TRUE)
  if (nrow(cand_all) == 0L) return(result)

  cand_initial <- tolower(substr(cand_all[[col_map$genus]], 1L, 1L))
  cand_epithet <- tolower(cand_all[[col_map$epithet]])
  cand_genus   <- tolower(cand_all[[col_map$genus]])

  cand_list <- vector("list", length(rows))
  for (k in seq_along(rows)) {
    hit <- !is.na(cand_epithet) & cand_initial == initial[k] &
           cand_epithet == epithet[k]
    if (!any(hit)) next
    cand <- cand_all[hit, , drop = FALSE]

    if (length(spelled)) {
      in_list <- cand_genus[hit] %in% spelled
      if (any(in_list)) cand <- cand[in_list, , drop = FALSE]
    }

    cand$row_idx <- rows[k]
    cand_list[[k]] <- cand
  }
  matches <- do.call(rbind, cand_list)
  if (is.null(matches) || nrow(matches) == 0L) return(result)

  # Score per query: resolve the unambiguous ones, flag the rest without guessing.
  best <- pick_best_vec(standardize_pick_cols(matches, col_map))
  ambiguous <- best$is_ambiguous %in% TRUE

  ok_idx <- best$row_idx[!ambiguous]
  if (length(ok_idx)) {
    keep <- matches$row_idx %in% ok_idx
    result <- fill_compiled_matches(result, matches[keep, , drop = FALSE],
                                    "abbrev", col_map)
  }

  if (any(ambiguous)) {
    amb <- best[ambiguous, , drop = FALSE]
    result$is_ambiguous[amb$row_idx]      <- TRUE
    result$ambiguous_targets[amb$row_idx] <- amb$ambiguous_targets
  }

  result
}


#' Resolve a backend name to an S3 object
#'
#' @param backend Character string or taxify_backend object.
#' @return A taxify_backend object.
#' @noRd
resolve_backend <- function(backend) {
  if (inherits(backend, "taxify_backend")) return(backend)
  switch(backend,
    wfo = wfo_backend(),
    col = col_backend(),
    gbif = gbif_backend(),
    itis = itis_backend(),
    ncbi = ncbi_backend(),
    ott = ott_backend(),
    worms = worms_backend(),
    fungorum = fungorum_backend(),
    algaebase = algaebase_backend(),
    euromed = euromed_backend(),
    fishbase = fishbase_backend(),
    sealifebase = sealifebase_backend(),
    reptiledb = reptiledb_backend(),
    stop(sprintf(
      "Unknown backend '%s'. Available: wfo, col, gbif, itis, ncbi, ott, worms, fungorum, algaebase, euromed, fishbase, sealifebase, reptiledb",
      backend), call. = FALSE)
  )
}


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

#' Create an empty match result data.frame
#'
#' @param n Integer. Number of rows.
#' @return A data.frame with all match columns initialized to NA.
#' @noRd
empty_match_result <- function(n) {
  data.frame(
    input_name        = character(n),
    matched_name      = NA_character_,
    accepted_name     = NA_character_,
    taxon_id          = NA_character_,
    accepted_id       = NA_character_,
    rank              = NA_character_,
    family            = NA_character_,
    genus             = NA_character_,
    epithet           = NA_character_,
    authorship        = NA_character_,
    accepted_authorship = NA_character_,
    is_synonym        = NA,
    is_hybrid         = NA,
    match_type        = NA_character_,
    fuzzy_dist        = NA_real_,
    is_ambiguous      = NA,
    ambiguous_targets = NA_character_,
    backend           = NA_character_,
    backbone_version  = NA_character_,
    stringsAsFactors  = FALSE
  )
}


#' Check if a compiled backbone has precomputed columns
#'
#' Used by `ensure_backbone()` to detect old-format backbones that need
#' re-download.
#'
#' @param vtr_path Path to the .vtr file.
#' @return Logical. TRUE if the backbone has precomputed columns.
#' @noRd
is_compiled_backbone <- function(vtr_path) {
  tryCatch({
    cols <- names(vectra::tbl(vtr_path) |>
                    vectra::slice_head(n = 1L) |>
                    vectra::collect())
    "accepted_name" %in% cols
  }, error = function(e) FALSE)
}

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
                        names_df = NULL, ...) {
  UseMethod("match_fuzzy")
}


# ------------------------------------------------------------------
# Shared compiled matching engine
# ------------------------------------------------------------------

#' Embed accepted taxon info at build time (synonym self-join)
#'
#' For every synonym row, resolves the accepted taxon and embeds its name,
#' family, and genus directly. Handles synonym chains by iterating until
#' stable (max 10 hops).
#'
#' @param df The full backbone data.frame.
#' @param id_col Name of the taxon ID column.
#' @param acc_id_col Name of the accepted name usage ID column.
#' @param name_col Name of the canonical name column.
#' @param family_col Name of the family column.
#' @param genus_col Name of the genus column.
#' @param status_col Name of the taxonomic status column.
#' @param synonym_pattern Regex pattern to detect synonyms in status column.
#' @return The data.frame with added columns: accepted_name, accepted_family,
#'   accepted_genus, accepted_taxon_id, is_synonym.
#' @noRd
embed_accepted <- function(df, id_col, acc_id_col, name_col, family_col,
                           genus_col, status_col,
                           synonym_pattern = "SYNONYM") {
  n <- nrow(df)

  # Detect synonyms
  is_syn <- !is.na(df[[status_col]]) &
    grepl(synonym_pattern, df[[status_col]])

  # Default: accepted = self

  df$accepted_name     <- df[[name_col]]
  df$accepted_family   <- df[[family_col]]
  df$accepted_genus    <- df[[genus_col]]
  df$accepted_taxon_id <- df[[id_col]]
  df$is_synonym        <- FALSE

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
  }

  df
}


#' Precompute matching keys at build time
#'
#' Adds key_ci, key_normalized, and key_species columns to the backbone
#' data.frame for direct lookup at query time.
#'
#' @param df The backbone data.frame.
#' @param name_col Name of the canonical name column.
#' @param genus_col Name of the genus column.
#' @param epithet_col Name of the specific epithet column.
#' @return The data.frame with added key columns.
#' @noRd
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

  df
}


#' Create indexes on compiled backbone .vtr
#'
#' Builds hash indexes for the name and genus columns to enable
#' O(1) row-group pruning at query time.
#'
#' @param vtr_path Path to the .vtr file.
#' @param name_col Name of the canonical name column.
#' @param genus_col Name of the genus column.
#' @noRd
create_backbone_indexes <- function(vtr_path, name_col, genus_col) {
  vectra::create_index(vtr_path, genus_col)
  vectra::create_index(vtr_path, name_col)
  vectra::create_index(vtr_path, "key_ci")
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

  # --- Pass 0: Genus-only ---
  genus_mask <- has_name & genus_only
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
  # Standardize for pick_best_vec
  matches$taxonID <- matches[[col_map$id]]
  matches$taxonRank <- matches[[col_map$rank]]
  matches$taxonomicStatus <- matches[[col_map$status]]

  best <- pick_best_vec(matches)
  idx <- best$row_idx

  # Only fill rows not already matched
  new_match <- is.na(result$match_type[idx])
  if (!any(new_match)) return(result)
  idx <- idx[new_match]
  best <- best[new_match, , drop = FALSE]

  result$matched_name[idx]  <- best[[col_map$name]]
  result$taxon_id[idx]      <- best[[col_map$id]]
  result$rank[idx]          <- tolower(best[[col_map$rank]])
  result$family[idx]        <- best$accepted_family
  result$genus[idx]         <- best$accepted_genus
  result$epithet[idx]       <- best[[col_map$epithet]]
  result$authorship[idx]    <- best[[col_map$authorship]]
  result$accepted_name[idx] <- best$accepted_name
  result$accepted_id[idx]   <- best$accepted_taxon_id
  result$is_synonym[idx]    <- best$is_synonym
  result$match_type[idx]    <- match_type
  result$fuzzy_dist[idx]    <- NA_real_

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
                                 col_map) {
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

  tmp_query <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_query), add = TRUE)
  vectra::write_vtr(query_df, tmp_query)

  # Use cached compact .vtr for fuzzy matching (select only matching columns,
  # much smaller than the full backbone with extra WFO/COL columns)
  fuzzy_bb <- get_fuzzy_bb(bb_path, col_map)

  by_vec <- stats::setNames(col_map$name, "cleaned_name")
  block_vec <- stats::setNames(col_map$genus, "query_genus")

  matches <- tryCatch(
    vectra::fuzzy_join(
      vectra::tbl(tmp_query),
      vectra::tbl(fuzzy_bb),
      by = by_vec,
      method = method,
      max_dist = threshold,
      block_by = block_vec,
      n_threads = 4L
    ) |> vectra::collect(),
    error = function(e) data.frame()
  )

  if (nrow(matches) > 0L) {
    # Standardize for pick_best_vec
    matches$taxonID <- matches[[col_map$id]]
    matches$taxonRank <- matches[[col_map$rank]]
    matches$taxonomicStatus <- matches[[col_map$status]]

    best <- pick_best_vec(matches)
    idx <- best$row_idx
    result$matched_name[idx]  <- best[[col_map$name]]
    result$taxon_id[idx]      <- best[[col_map$id]]
    result$rank[idx]          <- tolower(best[[col_map$rank]])
    result$accepted_name[idx] <- best$accepted_name
    result$accepted_id[idx]   <- best$accepted_taxon_id
    result$family[idx]        <- best$accepted_family
    result$genus[idx]         <- best$accepted_genus
    result$epithet[idx]       <- best[[col_map$epithet]]
    result$authorship[idx]    <- best[[col_map$authorship]]
    result$is_synonym[idx]    <- best$is_synonym
    result$match_type[idx]    <- "fuzzy"
    result$fuzzy_dist[idx]    <- best$fuzzy_dist
  }

  result
}


#' Get or create a compact backbone .vtr for fuzzy matching
#'
#' Selects only the columns needed for matching (no extra WFO/COL columns),
#' writes to a temp .vtr once per session. Sorted by genus for zone-map
#' pruning. Much smaller than the full backbone → faster fuzzy_join I/O.
#'
#' @param bb_path Path to the full backbone .vtr.
#' @param col_map Named list mapping logical roles to column names.
#' @return Path to the compact .vtr (cached per session).
#' @noRd
get_fuzzy_bb <- function(bb_path, col_map) {
  cache_key <- paste0(".fuzzy_bb_", basename(bb_path))
  cached <- .taxify_env[[cache_key]]
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # Select only columns needed for matching + accepted info
  keep_cols <- unique(c(
    col_map$name, col_map$genus, col_map$id, col_map$rank,
    col_map$status, col_map$epithet, col_map$authorship,
    "accepted_name", "accepted_family", "accepted_genus",
    "accepted_taxon_id", "is_synonym"
  ))

  fuzzy_path <- tempfile(fileext = ".vtr")
  vectra::tbl(bb_path) |>
    vectra::select(tidyselect::all_of(keep_cols)) |>
    vectra::write_vtr(fuzzy_path, batch_size = 50000L)

  .taxify_env[[cache_key]] <- fuzzy_path
  fuzzy_path
}


#' Unblocked fuzzy fallback for misspelled genera
#'
#' After genus-blocked fuzzy matching, names with misspelled genera remain
#' unmatched. This runs a single fuzzy_join WITHOUT genus blocking for all
#' remaining names, replacing the per-name loop.
#'
#' @param result The match result data.frame.
#' @param names_df Data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr file.
#' @param method Character. Distance algorithm.
#' @param threshold Numeric. Maximum normalized distance.
#' @param col_map Named list mapping logical roles to backbone column names.
#' @return The updated result data.frame.
#' @noRd
fuzzy_match_unblocked <- function(result, names_df, bb_path, method, threshold,
                                  col_map) {
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
  # misspelled genera (most genus typos preserve the first 2 characters)
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

  # Use compact backbone, compute prefix column for blocking
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
    matches$taxonID <- matches[[col_map$id]]
    matches$taxonRank <- matches[[col_map$rank]]
    matches$taxonomicStatus <- matches[[col_map$status]]

    best <- pick_best_vec(matches)
    idx <- best$row_idx
    result$matched_name[idx]  <- best[[col_map$name]]
    result$taxon_id[idx]      <- best[[col_map$id]]
    result$rank[idx]          <- tolower(best[[col_map$rank]])
    result$accepted_name[idx] <- best$accepted_name
    result$accepted_id[idx]   <- best$accepted_taxon_id
    result$family[idx]        <- best$accepted_family
    result$genus[idx]         <- best$accepted_genus
    result$epithet[idx]       <- best[[col_map$epithet]]
    result$authorship[idx]    <- best[[col_map$authorship]]
    result$is_synonym[idx]    <- best$is_synonym
    result$match_type[idx]    <- "fuzzy"
    result$fuzzy_dist[idx]    <- best$fuzzy_dist
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
    stop(sprintf(
      "Unknown backend '%s'. Available: wfo, col, gbif, itis, ncbi, ott, worms, fungorum, algaebase",
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
    input_name     = character(n),
    matched_name   = NA_character_,
    accepted_name  = NA_character_,
    taxon_id       = NA_character_,
    accepted_id    = NA_character_,
    rank           = NA_character_,
    family         = NA_character_,
    genus          = NA_character_,
    epithet        = NA_character_,
    authorship     = NA_character_,
    is_synonym     = NA,
    is_hybrid      = NA,
    match_type     = NA_character_,
    fuzzy_dist     = NA_real_,
    backend        = NA_character_,
    backbone_version = NA_character_,
    stringsAsFactors = FALSE
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

# ---- GBIF (Global Biodiversity Information Facility) backbone backend ----
#
# Offline matching against GBIF backbone taxonomy (simple.txt.gz).
# Downloads from hosted-datasets.gbif.org, converts to .vtr, queries via vectra.
#
# Key GBIF quirks:
# - simple.txt.gz has NO header row — columns are positional (30 cols)
# - No family text column — only family_key FK. Denormalized during conversion.
# - Synonyms use parent_key as accepted taxon ID (not acceptedNameUsageID).
# - NULL encoded as \N (Postgres copy format).
# - canonical_name exists (no authorship), scientific_name includes authorship.

# Latest GBIF backbone URL (always points to current release)
.gbif_url <- "https://hosted-datasets.gbif.org/datasets/backbone/current/simple.txt.gz"
.gbif_version <- "current"

# Positional column names for simple.txt (30 columns, no header)
.gbif_col_names <- c(
  "id", "parent_key", "basionym_key", "is_synonym", "status",
  "rank", "nom_status", "constituent_key", "origin", "source_taxon_key",
  "kingdom_key", "phylum_key", "class_key", "order_key", "family_key",
  "genus_key", "species_key", "name_id", "scientific_name", "canonical_name",
  "genus_or_above", "specific_epithet", "infra_specific_epithet", "notho_type",
  "authorship", "year", "bracket_authorship", "bracket_year",
  "name_published_in", "issues"
)

# Columns to keep in the .vtr (matching + extras for add_gbif_info)
.gbif_match_cols <- c(
  "id",
  "canonical_name",
  "scientific_name",
  "rank",
  "status",
  "is_synonym",
  "parent_key",
  "family",
  "genus_or_above",
  "specific_epithet",
  "authorship",
  "infra_specific_epithet"
)

.gbif_extra_cols <- c(
  "notho_type",
  "nom_status",
  "bracket_authorship",
  "bracket_year",
  "year",
  "name_published_in",
  "origin",
  "issues"
)


#' Create a GBIF backend object
#'
#' @return A taxify_backend object of class `"taxify_gbif"`.
#' @noRd
gbif_backend <- function() {
  new_backend(
    name = "gbif",
    version = .gbif_version,
    class = "taxify_gbif"
  )
}


#' @export
taxify_download.taxify_gbif <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  # Default to the versioned layout: <data_dir>/gbif/latest/
  dest <- dest %||% versioned_dir("gbif", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "gbif.vtr")
  url <- .gbif_url
  gz_path <- file.path(dest, "gbif_download.txt.gz")

  # Download (always re-downloads to get latest)
  if (verbose) {
    message("Downloading GBIF backbone from hosted-datasets.gbif.org (~1.5 GB)...")
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, gz_path, mode = "wb", quiet = !verbose)

  # Read simple.txt.gz — no header, \N = NA
  if (verbose) message("Reading simple.txt.gz (this may take a while)...")
  df <- utils::read.delim(
    gz_path,
    header = FALSE,
    col.names = .gbif_col_names,
    stringsAsFactors = FALSE,
    quote = "",
    na.strings = "\\N",
    fileEncoding = "UTF-8"
  )

  # Denormalize family: self-join id -> canonical_name for family_key
  if (verbose) message("Denormalizing family names...")
  df$family <- gbif_resolve_higher(df, df$family_key)

  # Normalize status and rank to uppercase
  df$status <- toupper(df$status)
  df$rank <- toupper(df$rank)

  # Normalize is_synonym to logical-like string for storage
  # simple.txt uses 't'/'f'
  df$is_synonym_flag <- df$is_synonym == "t"

  # Build acceptedNameUsageID equivalent:
  # For synonyms, parent_key = accepted taxon ID
  # For accepted names, parent_key = parent in classification tree
  df$accepted_id <- ifelse(df$is_synonym_flag, as.character(df$parent_key),
                           NA_character_)

  # Select columns to keep
  keep <- intersect(
    c(.gbif_match_cols, .gbif_extra_cols, "accepted_id", "is_synonym_flag"),
    names(df)
  )
  df <- df[, keep, drop = FALSE]

  # Strip whitespace from key text columns
  text_cols <- intersect(
    c("canonical_name", "scientific_name", "family", "genus_or_above",
      "specific_epithet", "authorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  # Convert id to character for consistent taxon_id handling
  df$id <- as.character(df$id)
  df$parent_key <- as.character(df$parent_key)

  if (verbose) message("Converting to .vtr format...")
  vectra::write_vtr(df, vtr_path)
  write_backbone_meta(vtr_path, "gbif", backend$version, url, nrow(df))
  write_version_meta(dest, "gbif", backend$version, pinned = FALSE)

  # Clean up
  unlink(gz_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf("GBIF backbone saved: %s (%.0f MB)", vtr_path, size_mb))
  }

  invisible(vtr_path)
}


#' Resolve higher classification keys to names via self-join
#'
#' GBIF simple.txt stores higher classification as foreign keys (integers).
#' This resolves a key column to canonical names by lookup against the
#' id/canonical_name mapping.
#'
#' @param df The full GBIF data.frame.
#' @param key_col Integer vector of keys to resolve.
#' @return Character vector of resolved names.
#' @noRd
gbif_resolve_higher <- function(df, key_col) {
  # Build lookup: id -> canonical_name
  lookup <- stats::setNames(df$canonical_name, as.character(df$id))
  resolved <- lookup[as.character(key_col)]
  unname(resolved)
}


#' @noRd
taxify_load.taxify_gbif <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "gbif.vtr")
  if (!file.exists(path)) {
    stop(sprintf(
      "GBIF backbone not found at: %s\nRun taxify_download('gbif') first.",
      path
    ), call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching
# ------------------------------------------------------------------

#' @noRd
match_exact.taxify_gbif <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  cleaned <- names_df$cleaned
  genus_only <- names_df$genus_only
  has_name <- !is.na(cleaned)

  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid <- names_df$is_hybrid

  if (!any(has_name)) return(result)

  # --- Genus-only pass: match against genus_or_above where rank is GENUS ---
  genus_mask <- has_name & genus_only
  if (any(genus_mask)) {
    genus_df <- data.frame(
      row_idx = which(genus_mask),
      cleaned_name = cleaned[genus_mask],
      stringsAsFactors = FALSE
    )
    tmp_genus <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_genus), add = TRUE)
    vectra::write_vtr(genus_df, tmp_genus)

    genus_matches <- vectra::inner_join(
      vectra::tbl(tmp_genus),
      vectra::tbl(bb_path) |>
        vectra::filter(rank == "GENUS") |>
        vectra::select(id, canonical_name, rank, status, is_synonym_flag,
                       accepted_id, family, genus_or_above, specific_epithet,
                       authorship),
      by = c("cleaned_name" = "canonical_name")
    ) |> vectra::collect()

    if (nrow(genus_matches) > 0L) {
      fill_gbif_matches(result, genus_matches, match_type = "exact",
                        name_col = "cleaned_name")
    }
  }

  # --- Species-level passes: skip genus_only rows ---
  species_mask <- has_name & !genus_only
  if (!any(species_mask)) return(result)

  # Write input names to temp .vtr
  input_df <- data.frame(
    row_idx = which(species_mask),
    cleaned_name = cleaned[species_mask],
    stringsAsFactors = FALSE
  )
  tmp_input <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_input), add = TRUE)
  vectra::write_vtr(input_df, tmp_input)

  # Pass 1: Exact match on cleaned_name == canonical_name
  exact <- vectra::inner_join(
    vectra::tbl(tmp_input),
    vectra::tbl(bb_path) |>
      vectra::select(id, canonical_name, rank, status, is_synonym_flag,
                     accepted_id, family, genus_or_above, specific_epithet,
                     authorship),
    by = c("cleaned_name" = "canonical_name")
  ) |> vectra::collect()

  if (nrow(exact) > 0L) {
    fill_gbif_matches(result, exact, match_type = "exact")
  }

  # Pass 2: Case-insensitive for remaining unmatched
  unmatched_mask <- species_mask & is.na(result$match_type)
  if (any(unmatched_mask)) {
    ci_df <- data.frame(
      row_idx = which(unmatched_mask),
      cleaned_name = cleaned[unmatched_mask],
      join_key = tolower(cleaned[unmatched_mask]),
      stringsAsFactors = FALSE
    )
    tmp_ci <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_ci), add = TRUE)
    vectra::write_vtr(ci_df, tmp_ci)

    ci_matches <- vectra::inner_join(
      vectra::tbl(tmp_ci),
      vectra::tbl(bb_path) |>
        vectra::select(id, canonical_name, rank, status, is_synonym_flag,
                       accepted_id, family, genus_or_above, specific_epithet,
                       authorship) |>
        vectra::mutate(join_key = tolower(canonical_name)),
      by = "join_key"
    ) |> vectra::collect()

    if (nrow(ci_matches) > 0L) {
      fill_gbif_matches(result, ci_matches, match_type = "exact_ci",
                        name_col = "canonical_name")
    }
  }

  # Pass 3: Infraspecific-to-species fallback
  infraspec_mask <- has_name & is.na(result$match_type) &
    vapply(strsplit(cleaned[seq_len(n)], " ", fixed = TRUE),
           length, integer(1L)) >= 3L
  if (any(infraspec_mask)) {
    species_names <- sub("^(\\S+\\s+\\S+)\\s+.*$", "\\1",
                         cleaned[infraspec_mask])
    sp_df <- data.frame(
      row_idx = which(infraspec_mask),
      cleaned_name = cleaned[infraspec_mask],
      species_name = species_names,
      stringsAsFactors = FALSE
    )
    tmp_sp <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_sp), add = TRUE)
    vectra::write_vtr(sp_df, tmp_sp)

    sp_matches <- vectra::inner_join(
      vectra::tbl(tmp_sp),
      vectra::tbl(bb_path) |>
        vectra::select(id, canonical_name, rank, status, is_synonym_flag,
                       accepted_id, family, genus_or_above, specific_epithet,
                       authorship),
      by = c("species_name" = "canonical_name")
    ) |> vectra::collect()

    if (nrow(sp_matches) > 0L) {
      fill_gbif_matches(result, sp_matches, match_type = "exact",
                        name_col = "species_name")
    }
  }

  result
}


#' Fill match results from GBIF join output
#'
#' @param result The match result data.frame.
#' @param matches The collected join output.
#' @param match_type Character.
#' @param name_col Character. Column containing the matched name.
#' @return NULL (modifies result in the calling environment).
#' @noRd
fill_gbif_matches <- function(result, matches, match_type,
                              name_col = "cleaned_name") {
  env <- parent.frame()
  res <- env$result

  # Map GBIF status to the taxonomicStatus expected by pick_best
  matches$taxonomicStatus <- gbif_status_to_standard(matches$status)
  matches$taxonID <- matches$id
  matches$taxonRank <- matches$rank

  for (ri in unique(matches$row_idx)) {
    candidates <- matches[matches$row_idx == ri, , drop = FALSE]
    best <- pick_best(candidates)
    i <- best$row_idx
    res$matched_name[i] <- best[[name_col]]
    res$taxon_id[i] <- best$id
    res$rank[i] <- tolower(best$rank)
    res$taxonomicStatus[i] <- best$taxonomicStatus
    res$accepted_id_raw[i] <- best$accepted_id
    res$family[i] <- best$family
    res$genus[i] <- best$genus_or_above
    res$epithet[i] <- best$specific_epithet
    res$authorship[i] <- best$authorship
    res$match_type[i] <- match_type
    res$fuzzy_dist[i] <- NA_real_
  }
  env$result <- res
  invisible(NULL)
}


#' Map GBIF status values to standard ACCEPTED/SYNONYM
#'
#' @param status Character vector of GBIF status values.
#' @return Character vector with "ACCEPTED" or "SYNONYM".
#' @noRd
gbif_status_to_standard <- function(status) {
  ifelse(
    status %in% c("ACCEPTED", "DOUBTFUL", "PROVISIONALLY_ACCEPTED"),
    "ACCEPTED",
    "SYNONYM"
  )
}


#' @noRd
match_fuzzy.taxify_gbif <- function(backend, unmatched_df, backbone,
                                    method = "dl", threshold = 0.2, ...) {
  bb_path <- backbone
  result <- unmatched_df
  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))

  if (length(unmatched_rows) == 0L) return(result)

  jw_mode <- (method == "jw")

  for (i in unmatched_rows) {
    cleaned <- clean_one(result$input_name[i])$cleaned
    if (is.na(cleaned) || !nzchar(cleaned)) next

    genus_name <- sub(" .*", "", cleaned)

    candidates <- run_gbif_fuzzy_query(bb_path, genus_name, cleaned,
                                       method, threshold, by_genus = TRUE)

    if (nrow(candidates) == 0L) {
      prefix <- substr(cleaned, 1L, 3L)
      candidates <- run_gbif_fuzzy_query(bb_path, prefix, cleaned,
                                         method, threshold, by_genus = FALSE)
    }

    if (nrow(candidates) == 0L) next

    if (jw_mode) {
      candidates$dist <- 1.0 - candidates$dist
      candidates <- candidates[order(candidates$dist), , drop = FALSE]
    }

    # Add columns expected by pick_best
    candidates$taxonomicStatus <- gbif_status_to_standard(candidates$status)
    candidates$taxonID <- candidates$id
    candidates$taxonRank <- candidates$rank

    best <- pick_best(candidates)
    result$matched_name[i] <- best$canonical_name
    result$taxon_id[i] <- best$id
    result$rank[i] <- tolower(best$rank)
    result$taxonomicStatus[i] <- best$taxonomicStatus
    result$accepted_id_raw[i] <- best$accepted_id
    result$family[i] <- best$family
    result$genus[i] <- best$genus_or_above
    result$epithet[i] <- best$specific_epithet
    result$authorship[i] <- best$authorship
    result$match_type[i] <- "fuzzy"
    result$fuzzy_dist[i] <- best$dist
  }

  result
}


#' Run a single fuzzy query against the GBIF backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character. Genus name (if by_genus) or prefix string.
#' @param target Character. The cleaned name to match against.
#' @param method Character. "dl", "levenshtein", or "jw".
#' @param threshold Numeric. Maximum distance (or minimum similarity for JW).
#' @param by_genus Logical.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_gbif_fuzzy_query <- function(bb_path, filter_value, target,
                                 method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(id, canonical_name, rank, status, is_synonym_flag,
                     accepted_id, family, genus_or_above, specific_epithet,
                     authorship)

    if (by_genus) {
      bb <- bb |> vectra::filter(genus_or_above == filter_value)
    } else {
      bb <- bb |> vectra::filter(startsWith(canonical_name, filter_value))
    }

    if (method == "dl") {
      bb <- bb |>
        vectra::mutate(dist = dl_dist_norm(canonical_name, target)) |>
        vectra::filter(dist <= threshold)
    } else if (method == "levenshtein") {
      bb <- bb |>
        vectra::mutate(dist = levenshtein_norm(canonical_name, target)) |>
        vectra::filter(dist <= threshold)
    } else {
      jw_thresh <- 1.0 - threshold
      bb <- bb |>
        vectra::mutate(dist = jaro_winkler(canonical_name, target)) |>
        vectra::filter(dist >= jw_thresh)
    }

    bb |>
      vectra::arrange(dist) |>
      utils::head(5L) |>
      vectra::collect()
  }, error = function(e) {
    data.frame()
  })
}


#' @noRd
resolve_synonyms.taxify_gbif <- function(backend, matches, backbone, ...) {
  bb_path <- backbone
  result <- matches

  # GBIF synonyms: taxonomicStatus mapped to "SYNONYM" via gbif_status_to_standard
  synonym_rows <- which(
    !is.na(result$taxonomicStatus) &
    result$taxonomicStatus == "SYNONYM"
  )

  if (length(synonym_rows) == 0L) {
    accepted_rows <- !is.na(result$matched_name)
    result$accepted_name[accepted_rows] <- result$matched_name[accepted_rows]
    result$accepted_id[accepted_rows] <- result$taxon_id[accepted_rows]
    result$is_synonym[accepted_rows] <- FALSE
    return(result)
  }

  # Look up accepted names by accepted_id (= parent_key for synonyms)
  acc_ids <- unique(result$accepted_id_raw[synonym_rows])
  acc_ids <- acc_ids[!is.na(acc_ids)]

  if (length(acc_ids) > 0L) {
    id_df <- data.frame(lookup_id = acc_ids, stringsAsFactors = FALSE)
    tmp_ids <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_ids), add = TRUE)
    vectra::write_vtr(id_df, tmp_ids)

    acc_info <- vectra::inner_join(
      vectra::tbl(tmp_ids),
      vectra::tbl(bb_path) |>
        vectra::select(id, canonical_name, family, genus_or_above),
      by = c("lookup_id" = "id")
    ) |> vectra::collect()

    acc_lookup <- split(acc_info, acc_info$lookup_id)
  } else {
    acc_lookup <- list()
  }

  for (i in seq_len(nrow(result))) {
    if (is.na(result$matched_name[i])) {
      result$is_synonym[i] <- NA
      next
    }

    if (i %in% synonym_rows && !is.na(result$accepted_id_raw[i])) {
      acc <- acc_lookup[[result$accepted_id_raw[i]]]
      if (!is.null(acc) && nrow(acc) > 0L) {
        result$accepted_name[i] <- acc$canonical_name[1L]
        result$accepted_id[i] <- acc$lookup_id[1L]
        result$family[i] <- acc$family[1L] %||% result$family[i]
        result$genus[i] <- acc$genus_or_above[1L] %||% result$genus[i]
      } else {
        result$accepted_name[i] <- result$matched_name[i]
        result$accepted_id[i] <- result$taxon_id[i]
      }
      result$is_synonym[i] <- TRUE
    } else {
      result$accepted_name[i] <- result$matched_name[i]
      result$accepted_id[i] <- result$taxon_id[i]
      result$is_synonym[i] <- FALSE
    }
  }

  result
}

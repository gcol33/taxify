# ---- WFO (World Flora Online) backend ----
#
# Offline matching against WFO Darwin Core snapshots from Zenodo.
# Downloads classification.txt, converts to .vtr, queries via vectra.

# Zenodo URLs for WFO backbone (same as RESOLVE's wfo.py)
.wfo_urls <- list(
  "2024-12" = "https://zenodo.org/records/14538251/files/_DwC_backbone_R.zip",
  "2024-06" = "https://zenodo.org/records/12171908/files/_DwC_backbone_R.zip"
)

# Columns needed for matching (core + authorship + infraspecific)
.wfo_match_cols <- c(
  "taxonID",
  "scientificName",
  "taxonRank",
  "taxonomicStatus",
  "acceptedNameUsageID",
  "family",
  "genus",
  "specificEpithet",
  "scientificNameAuthorship",
  "infraspecificEpithet"
)

# Extra columns for add_wfo_info() — all columns in classification.txt
.wfo_extra_cols <- c(
  "scientificNameID",
  "parentNameUsageID",
  "namePublishedIn",
  "higherClassification",
  "taxonRemarks"
)


#' Create a WFO backend object
#'
#' @param version Character. WFO version (e.g., `"2024-12"`).
#'   `"latest"` uses the most recent available version.
#' @return A taxify_backend object of class `"taxify_wfo"`.
#' @noRd
wfo_backend <- function(version = "latest") {
  if (version == "latest") version <- "2024-12"
  available <- names(.wfo_urls)
  if (!version %in% available) {
    stop(sprintf("Unknown WFO version '%s'. Available: %s",
                 version, paste(available, collapse = ", ")),
         call. = FALSE)
  }
  new_backend(
    name = "wfo",
    version = version,
    class = "taxify_wfo"
  )
}


#' @export
taxify_download.taxify_wfo <- function(backend, dest = NULL, version = "latest",
                                       verbose = TRUE, ...) {
  if (version != "latest") backend$version <- version
  dest <- dest %||% taxify_data_dir()
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, paste0("wfo_", backend$version, ".vtr"))

  # Skip if already converted

  if (file.exists(vtr_path)) {
    if (verbose) {
      size_mb <- file.size(vtr_path) / (1024 * 1024)
      message(sprintf("WFO backbone already exists: %s (%.0f MB)", vtr_path,
                       size_mb))
    }
    return(invisible(vtr_path))
  }

  url <- .wfo_urls[[backend$version]]

  zip_path <- file.path(dest, paste0("wfo_", backend$version, ".zip"))

  # Download
  if (verbose) {
    message(sprintf("Downloading WFO backbone %s from Zenodo...", backend$version))
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, zip_path, mode = "wb", quiet = !verbose)

  # Extract classification.txt
  if (verbose) message("Extracting classification.txt...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  txt_target <- txt_files[grepl("classification\\.txt$", txt_files)]
  if (length(txt_target) == 0L) {
    stop("classification.txt not found in downloaded archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = txt_target[1L], exdir = dest, junkpaths = TRUE)
  txt_path <- file.path(dest, "classification.txt")

  # Convert TSV to .vtr
  # vectra's tbl_csv() is comma-only, so we read with read.delim and write_vtr
  if (verbose) message("Converting to .vtr format...")
  df <- utils::read.delim(
    txt_path,
    fileEncoding = "latin1",
    stringsAsFactors = FALSE,
    quote = "",
    na.strings = ""
  )

  # Select only needed columns (match + extra for add_wfo_info)
  keep <- intersect(c(.wfo_match_cols, .wfo_extra_cols), names(df))
  df <- df[, keep, drop = FALSE]

  # Normalize taxonomicStatus and taxonRank to uppercase
  if ("taxonomicStatus" %in% names(df)) {
    df$taxonomicStatus <- toupper(df$taxonomicStatus)
  }
  if ("taxonRank" %in% names(df)) {
    df$taxonRank <- toupper(df$taxonRank)
  }

  # Strip whitespace from key text columns
  text_cols <- intersect(
    c("scientificName", "family", "genus", "specificEpithet",
      "scientificNameAuthorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  vectra::write_vtr(df, vtr_path)

  # Clean up
  unlink(zip_path)
  unlink(txt_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf("WFO backbone saved: %s (%.0f MB)", vtr_path, size_mb))
  }

  invisible(vtr_path)
}


#' @noRd
taxify_load.taxify_wfo <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(),
                               paste0("wfo_", backend$version, ".vtr"))
  if (!file.exists(path)) {
    stop(sprintf("WFO backbone not found at: %s\nRun taxify_download('wfo') first.",
                 path),
         call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching
# ------------------------------------------------------------------

#' @noRd
match_exact.taxify_wfo <- function(backend, names_df, backbone, ...) {
  # names_df: data.frame with columns original, cleaned, is_hybrid, qualifier
  # backbone: path to .vtr file (fresh tbl() created per query)
  #
  # Strategy: write cleaned names to temp .vtr, then join against backbone.
  # Two passes: exact on cleaned_name, then case-insensitive.

  bb_path <- backbone
  cleaned <- names_df$cleaned
  has_name <- !is.na(cleaned)

  # Prepare empty results template
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid <- names_df$is_hybrid

  if (!any(has_name)) return(result)

  # Write input names to temp .vtr for vectra joins
  input_df <- data.frame(
    row_idx = which(has_name),
    cleaned_name = cleaned[has_name],
    stringsAsFactors = FALSE
  )
  tmp_input <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_input), add = TRUE)
  vectra::write_vtr(input_df, tmp_input)

  # Pass 1: Exact match on cleaned_name == scientificName
  exact <- vectra::inner_join(
    vectra::tbl(tmp_input),
    vectra::tbl(bb_path) |>
      vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                     acceptedNameUsageID, family, genus, specificEpithet,
                     scientificNameAuthorship),
    by = c("cleaned_name" = "scientificName")
  ) |> vectra::collect()

  if (nrow(exact) > 0L) {
    for (ri in unique(exact$row_idx)) {
      candidates <- exact[exact$row_idx == ri, , drop = FALSE]
      best <- pick_best(candidates)
      i <- best$row_idx
      result$matched_name[i] <- best$cleaned_name
      result$taxon_id[i] <- best$taxonID
      result$rank[i] <- tolower(best$taxonRank)
      result$taxonomicStatus[i] <- best$taxonomicStatus
      result$accepted_id_raw[i] <- best$acceptedNameUsageID
      result$family[i] <- best$family
      result$genus[i] <- best$genus
      result$epithet[i] <- best$specificEpithet
      result$authorship[i] <- best$scientificNameAuthorship
      result$match_type[i] <- "exact"
      result$fuzzy_dist[i] <- NA_real_
    }
  }

  # Pass 2: Case-insensitive for remaining unmatched
  unmatched_mask <- has_name & is.na(result$match_type)
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
        vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genus, specificEpithet,
                       scientificNameAuthorship) |>
        vectra::mutate(join_key = tolower(scientificName)),
      by = "join_key"
    ) |> vectra::collect()

    if (nrow(ci_matches) > 0L) {
      for (ri in unique(ci_matches$row_idx)) {
        candidates <- ci_matches[ci_matches$row_idx == ri, , drop = FALSE]
        best <- pick_best(candidates)
        i <- best$row_idx
        result$matched_name[i] <- best$scientificName
        result$taxon_id[i] <- best$taxonID
        result$rank[i] <- tolower(best$taxonRank)
        result$taxonomicStatus[i] <- best$taxonomicStatus
        result$accepted_id_raw[i] <- best$acceptedNameUsageID
        result$family[i] <- best$family
        result$genus[i] <- best$genus
        result$epithet[i] <- best$specificEpithet
        result$authorship[i] <- best$scientificNameAuthorship
        result$match_type[i] <- "exact_ci"
        result$fuzzy_dist[i] <- NA_real_
      }
    }
  }

  result
}


#' @noRd
match_fuzzy.taxify_wfo <- function(backend, unmatched_df, backbone,
                                   method = "dl", threshold = 0.2, ...) {
  # unmatched_df: a match result data.frame where match_type is still NA
  # backbone: path to .vtr file
  # For each unmatched name, do genus-filtered fuzzy search via vectra.

  bb_path <- backbone
  result <- unmatched_df
  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))

  if (length(unmatched_rows) == 0L) return(result)

  # For JW: similarity score (1 = identical), threshold means minimum similarity
  jw_mode <- (method == "jw")

  for (i in unmatched_rows) {
    cleaned <- clean_one(result$input_name[i])$cleaned
    if (is.na(cleaned) || !nzchar(cleaned)) next

    genus_name <- sub(" .*", "", cleaned)

    # Genus-filtered fuzzy query (fresh tbl() each time — nodes are single-use)
    candidates <- run_fuzzy_query(bb_path, genus_name, cleaned,
                                  method, threshold, by_genus = TRUE)

    # Fallback: prefix filter if genus found nothing
    if (nrow(candidates) == 0L) {
      prefix <- substr(cleaned, 1L, 3L)
      candidates <- run_fuzzy_query(bb_path, prefix, cleaned,
                                    method, threshold, by_genus = FALSE)
    }

    if (nrow(candidates) == 0L) next

    # For JW, convert similarity to distance for consistent output
    if (jw_mode) {
      candidates$dist <- 1.0 - candidates$dist
      candidates <- candidates[order(candidates$dist), , drop = FALSE]
    }

    best <- pick_best(candidates)
    result$matched_name[i] <- best$scientificName
    result$taxon_id[i] <- best$taxonID
    result$rank[i] <- tolower(best$taxonRank)
    result$taxonomicStatus[i] <- best$taxonomicStatus
    result$accepted_id_raw[i] <- best$acceptedNameUsageID
    result$family[i] <- best$family
    result$genus[i] <- best$genus
    result$epithet[i] <- best$specificEpithet
    result$authorship[i] <- best$scientificNameAuthorship
    result$match_type[i] <- "fuzzy"
    result$fuzzy_dist[i] <- best$dist
  }

  result
}


#' Run a single fuzzy query against the backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character. Genus name (if by_genus) or prefix string.
#' @param target Character. The cleaned name to match against.
#' @param method Character. "dl", "levenshtein", or "jw".
#' @param threshold Numeric. Maximum distance (or minimum similarity for JW).
#' @param by_genus Logical. If TRUE, filter by genus column. If FALSE, filter
#'   by startsWith on scientificName.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_fuzzy_query <- function(bb_path, filter_value, target,
                            method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                     acceptedNameUsageID, family, genus, specificEpithet,
                     scientificNameAuthorship)

    if (by_genus) {
      bb <- bb |> vectra::filter(genus == filter_value)
    } else {
      bb <- bb |> vectra::filter(startsWith(scientificName, filter_value))
    }

    if (method == "dl") {
      bb <- bb |>
        vectra::mutate(dist = dl_dist_norm(scientificName, target)) |>
        vectra::filter(dist <= threshold)
    } else if (method == "levenshtein") {
      bb <- bb |>
        vectra::mutate(dist = levenshtein_norm(scientificName, target)) |>
        vectra::filter(dist <= threshold)
    } else {
      jw_thresh <- 1.0 - threshold
      bb <- bb |>
        vectra::mutate(dist = jaro_winkler(scientificName, target)) |>
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
resolve_synonyms.taxify_wfo <- function(backend, matches, backbone, ...) {
  # backbone: path to .vtr file
  # For rows where taxonomicStatus contains SYNONYM, look up the accepted name.

  bb_path <- backbone
  result <- matches
  synonym_rows <- which(
    !is.na(result$taxonomicStatus) &
    grepl("SYNONYM", result$taxonomicStatus)
  )

  if (length(synonym_rows) == 0L) {
    # Fill in accepted = matched for non-synonyms
    accepted_rows <- !is.na(result$matched_name)
    result$accepted_name[accepted_rows] <- result$matched_name[accepted_rows]
    result$accepted_id[accepted_rows] <- result$taxon_id[accepted_rows]
    result$is_synonym[accepted_rows] <- FALSE
    return(result)
  }

  # Collect unique acceptedNameUsageIDs to look up
  acc_ids <- unique(result$accepted_id_raw[synonym_rows])
  acc_ids <- acc_ids[!is.na(acc_ids)]

  if (length(acc_ids) > 0L) {
    # Write IDs to temp .vtr for join
    id_df <- data.frame(lookup_id = acc_ids, stringsAsFactors = FALSE)
    tmp_ids <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_ids), add = TRUE)
    vectra::write_vtr(id_df, tmp_ids)

    acc_info <- vectra::inner_join(
      vectra::tbl(tmp_ids),
      vectra::tbl(bb_path) |>
        vectra::select(taxonID, scientificName, family, genus),
      by = c("lookup_id" = "taxonID")
    ) |> vectra::collect()

    # Build lookup
    acc_lookup <- stats::setNames(
      split(acc_info, acc_info$lookup_id),
      acc_info$lookup_id
    )
  } else {
    acc_lookup <- list()
  }

  # Fill in accepted info
  for (i in seq_len(nrow(result))) {
    if (is.na(result$matched_name[i])) {
      # No match at all
      result$is_synonym[i] <- NA
      next
    }

    if (i %in% synonym_rows && !is.na(result$accepted_id_raw[i])) {
      acc <- acc_lookup[[result$accepted_id_raw[i]]]
      if (!is.null(acc) && nrow(acc) > 0L) {
        result$accepted_name[i] <- acc$scientificName[1L]
        result$accepted_id[i] <- acc$lookup_id[1L]
        result$family[i] <- acc$family[1L] %||% result$family[i]
        result$genus[i] <- acc$genus[1L] %||% result$genus[i]
      } else {
        # acceptedNameUsageID exists but not found in backbone
        result$accepted_name[i] <- result$matched_name[i]
        result$accepted_id[i] <- result$taxon_id[i]
      }
      result$is_synonym[i] <- TRUE
    } else {
      # Accepted name
      result$accepted_name[i] <- result$matched_name[i]
      result$accepted_id[i] <- result$taxon_id[i]
      result$is_synonym[i] <- FALSE
    }
  }

  result
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
    # Internal columns (stripped before returning to user)
    taxonomicStatus  = NA_character_,
    accepted_id_raw  = NA_character_,
    stringsAsFactors = FALSE
  )
}

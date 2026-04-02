# ---- WFO (World Flora Online) backend ----
#
# Offline matching against WFO Darwin Core snapshots from Zenodo.
# Downloads classification.txt, converts to .vtr, queries via vectra.

# Latest WFO backbone URL and version (updated with package releases)
.wfo_url <- "https://zenodo.org/records/14538251/files/_DwC_backbone_R.zip"
.wfo_version <- "2024-12"

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

# Extra columns for add_wfo_info() — additional columns in classification file
.wfo_extra_cols <- c(
  "scientificNameID",
  "parentNameUsageID",
  "namePublishedIn",
  "nomenclaturalStatus",
  "taxonRemarks",
  "subfamily",
  "tribe",
  "subtribe",
  "subgenus"
)


#' Create a WFO backend object
#'
#' @return A taxify_backend object of class `"taxify_wfo"`.
#' @noRd
wfo_backend <- function() {
  new_backend(
    name = "wfo",
    version = .wfo_version,
    class = "taxify_wfo"
  )
}


#' @export
taxify_download.taxify_wfo <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  # Default to the versioned layout: <data_dir>/wfo/latest/
  dest <- dest %||% versioned_dir("wfo", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "wfo.vtr")
  url <- .wfo_url
  zip_path <- file.path(dest, "wfo_download.zip")

  # Download (always re-downloads to get latest)
  if (verbose) {
    message(sprintf("Downloading WFO backbone (%s) from Zenodo (~120 MB)...",
                    backend$version))
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, zip_path, mode = "wb", quiet = !verbose)

  # Extract classification file (may be .txt or .csv depending on WFO release)
  if (verbose) message("Extracting classification file...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  txt_target <- txt_files[grepl("classification\\.(txt|csv)$", txt_files)]
  if (length(txt_target) == 0L) {
    stop("classification.txt/.csv not found in downloaded archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = txt_target[1L], exdir = dest, junkpaths = TRUE)
  txt_path <- file.path(dest, basename(txt_target[1L]))

  # Convert TSV to .vtr
  # vectra's tbl_csv() is comma-only, so we read with read.delim and write_vtr
  if (verbose) message("Converting to .vtr format...")
  df <- utils::read.delim(
    txt_path,
    fileEncoding = "latin1",
    stringsAsFactors = FALSE,
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

  # Fix mojibake: the source file contains UTF-8 × (bytes C3 97) which Latin-1
  # reads as "Ã\x97". Normalize to proper × (U+00D7) in all text columns.
  text_cols <- intersect(
    c("scientificName", "family", "genus", "specificEpithet",
      "scientificNameAuthorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
    df[[col]] <- gsub("\u00c3\u0097", "\u00d7", df[[col]], fixed = TRUE)
  }

  # Add normalized epithet column for Latin orthographic variant matching
  df$normalizedName <- normalize_epithets(df$scientificName)

  vectra::write_vtr(df, vtr_path)
  write_backbone_meta(vtr_path, "wfo", backend$version, url, nrow(df))
  write_version_meta(dest, "wfo", backend$version, pinned = FALSE)

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
  path <- path %||% file.path(taxify_data_dir(), "wfo.vtr")
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
  # names_df: data.frame with columns original, cleaned, is_hybrid, qualifier,
  #   genus_only
  # backbone: path to .vtr file (fresh tbl() created per query)
  #
  # Strategy: write cleaned names to temp .vtr, then join against backbone.
  # genus_only names match against genus column where taxonRank == "GENUS".
  # Remaining names: exact on cleaned_name, then case-insensitive.

  bb_path <- backbone
  cleaned <- names_df$cleaned
  genus_only <- names_df$genus_only
  has_name <- !is.na(cleaned)

  # Prepare empty results template
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid <- names_df$is_hybrid

  if (!any(has_name)) return(result)

  # --- Genus-only pass: match against genus column where rank is GENUS ---
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
        vectra::filter(taxonRank == "GENUS") |>
        vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genus, specificEpithet,
                       scientificNameAuthorship),
      by = c("cleaned_name" = "scientificName")
    ) |> vectra::collect()

    if (nrow(genus_matches) > 0L) {
      for (ri in unique(genus_matches$row_idx)) {
        candidates <- genus_matches[genus_matches$row_idx == ri, , drop = FALSE]
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
  }

  # --- Species-level passes: skip genus_only rows ---
  species_mask <- has_name & !genus_only
  if (!any(species_mask)) return(result)

  # --- Hybrid pass: for nothospecies, try "Genus × epithet" form first ---
  hybrid_name <- names_df$hybrid_name
  hybrid_mask <- species_mask & !is.na(hybrid_name)
  if (any(hybrid_mask)) {
    hb_df <- data.frame(
      row_idx = which(hybrid_mask),
      hybrid_name = hybrid_name[hybrid_mask],
      stringsAsFactors = FALSE
    )
    tmp_hb <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_hb), add = TRUE)
    vectra::write_vtr(hb_df, tmp_hb)

    hb_matches <- vectra::inner_join(
      vectra::tbl(tmp_hb),
      vectra::tbl(bb_path) |>
        vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genus, specificEpithet,
                       scientificNameAuthorship),
      by = c("hybrid_name" = "scientificName")
    ) |> vectra::collect()

    if (nrow(hb_matches) > 0L) {
      for (ri in unique(hb_matches$row_idx)) {
        candidates <- hb_matches[hb_matches$row_idx == ri, , drop = FALSE]
        best <- pick_best(candidates)
        i <- best$row_idx
        result$matched_name[i] <- best$hybrid_name
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
  }

  # Write input names to temp .vtr for vectra joins (skip already-matched hybrids)
  remaining_mask <- species_mask & is.na(result$match_type)
  if (!any(remaining_mask)) return(result)

  input_df <- data.frame(
    row_idx = which(remaining_mask),
    cleaned_name = cleaned[remaining_mask],
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

  # Pass 3: Latin orthographic normalization (ae/e, oe/e, ii/i, y/i, ph/f)
  # Join normalized input against precomputed normalizedName column in backbone.
  # For hybrids, also try the normalized "Genus × epithet" form.
  norm_mask <- has_name & is.na(result$match_type)
  if (any(norm_mask)) {
    # Build all normalized variants for each unmatched name
    norm_idx <- which(norm_mask)
    norm_plain <- normalize_epithets(cleaned[norm_mask])

    # For hybrids: also normalize the "Genus × epithet" form
    norm_hybrid <- ifelse(
      !is.na(hybrid_name[norm_mask]),
      normalize_epithets(hybrid_name[norm_mask]),
      NA_character_
    )

    # For infraspecific (3+ words): also normalize the species binomial
    word_counts <- vapply(strsplit(cleaned[norm_mask], " ", fixed = TRUE),
                          length, integer(1L))
    norm_species <- ifelse(
      word_counts >= 3L,
      normalize_epithets(sub("^(\\S+\\s+\\S+)\\s+.*$", "\\1", cleaned[norm_mask])),
      NA_character_
    )

    # Stack all variants into one data.frame for a single join
    rows <- list()
    for (j in seq_along(norm_idx)) {
      rows[[length(rows) + 1L]] <- data.frame(
        row_idx = norm_idx[j], norm_key = norm_plain[j],
        stringsAsFactors = FALSE
      )
      if (!is.na(norm_hybrid[j])) {
        rows[[length(rows) + 1L]] <- data.frame(
          row_idx = norm_idx[j], norm_key = norm_hybrid[j],
          stringsAsFactors = FALSE
        )
      }
      if (!is.na(norm_species[j])) {
        rows[[length(rows) + 1L]] <- data.frame(
          row_idx = norm_idx[j], norm_key = norm_species[j],
          stringsAsFactors = FALSE
        )
      }
    }
    norm_df <- do.call(rbind, rows)

    tmp_norm <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp_norm), add = TRUE)
    vectra::write_vtr(norm_df, tmp_norm)

    norm_matches <- vectra::inner_join(
      vectra::tbl(tmp_norm),
      vectra::tbl(bb_path) |>
        vectra::select(taxonID, scientificName, normalizedName, taxonRank,
                       taxonomicStatus, acceptedNameUsageID, family, genus,
                       specificEpithet, scientificNameAuthorship),
      by = c("norm_key" = "normalizedName")
    ) |> vectra::collect()

    if (nrow(norm_matches) > 0L) {
      for (ri in unique(norm_matches$row_idx)) {
        if (!is.na(result$match_type[ri])) next
        candidates <- norm_matches[norm_matches$row_idx == ri, , drop = FALSE]
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

  # Pass 4: Infraspecific-to-species fallback
  # After cleaning, names like "Genus epithet subsp. infraepithet" become
  # "Genus epithet infraepithet" (3+ words). If still unmatched, try matching
  # just the species binomial (first two words).
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
        vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genus, specificEpithet,
                       scientificNameAuthorship),
      by = c("species_name" = "scientificName")
    ) |> vectra::collect()

    if (nrow(sp_matches) > 0L) {
      for (ri in unique(sp_matches$row_idx)) {
        candidates <- sp_matches[sp_matches$row_idx == ri, , drop = FALSE]
        best <- pick_best(candidates)
        i <- best$row_idx
        result$matched_name[i] <- best$species_name
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

    # Build lookup (split already returns a named list keyed by lookup_id)
    acc_lookup <- split(acc_info, acc_info$lookup_id)
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
    backbone_version = NA_character_,
    # Internal columns (stripped before returning to user)
    taxonomicStatus  = NA_character_,
    accepted_id_raw  = NA_character_,
    stringsAsFactors = FALSE
  )
}

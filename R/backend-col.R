# ---- COL (Catalogue of Life) backend ----
#
# Offline matching against COL Darwin Core Archive snapshots from ChecklistBank.
# Downloads Taxon.tsv (+ SpeciesProfile.tsv for add_col_info), converts to .vtr,
# queries via vectra.

# Latest COL backbone URL and version (updated with package releases)
.col_url <- "https://download.checklistbank.org/col/annual/2025_dwca.zip"
.col_version <- "2025"

# Columns needed for matching (after stripping namespace prefixes)
.col_match_cols <- c(
  "taxonID",
  "scientificName",
  "taxonRank",
  "taxonomicStatus",
  "acceptedNameUsageID",
  "family",
  "genericName",
  "specificEpithet",
  "scientificNameAuthorship",
  "infraspecificEpithet"
)

# Extra columns for add_col_info()
.col_extra_cols <- c(
  "notho",
  "nomenclaturalCode",
  "nomenclaturalStatus",
  "namePublishedIn",
  "nameAccordingTo",
  "kingdom",
  "phylum",
  "class",
  "order",
  "superfamily",
  "subfamily",
  "tribe",
  "taxonRemarks",
  "references",
  "scientificNameID",
  "parentNameUsageID",
  "infragenericEpithet",
  "cultivarEpithet"
)


#' Create a COL backend object
#'
#' @return A taxify_backend object of class `"taxify_col"`.
#' @noRd
col_backend <- function() {
  new_backend(
    name = "col",
    version = .col_version,
    class = "taxify_col"
  )
}


#' @export
taxify_download.taxify_col <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  # Default to the versioned layout: <data_dir>/col/latest/
  dest <- dest %||% versioned_dir("col", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "col.vtr")
  url <- .col_url
  zip_path <- file.path(dest, "col_download.zip")

  # Download (always re-downloads to get latest)
  if (verbose) {
    message(sprintf("Downloading COL backbone (%s) from ChecklistBank (~600 MB)...",
                    backend$version))
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, zip_path, mode = "wb", quiet = !verbose)

  # Extract Taxon.tsv
  if (verbose) message("Extracting Taxon.tsv...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  taxon_target <- txt_files[grepl("Taxon\\.tsv$", txt_files)]
  if (length(taxon_target) == 0L) {
    stop("Taxon.tsv not found in downloaded archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = taxon_target[1L], exdir = dest,
               junkpaths = TRUE)
  tsv_path <- file.path(dest, "Taxon.tsv")

  # Also extract SpeciesProfile.tsv if present (for add_col_info)
  sp_target <- txt_files[grepl("SpeciesProfile\\.tsv$", txt_files)]
  if (length(sp_target) > 0L) {
    if (verbose) message("Extracting SpeciesProfile.tsv...")
    utils::unzip(zip_path, files = sp_target[1L], exdir = dest,
                 junkpaths = TRUE)
    sp_path <- file.path(dest, "SpeciesProfile.tsv")
  } else {
    sp_path <- NULL
  }

  # Convert Taxon.tsv to .vtr
  if (verbose) message("Converting Taxon.tsv to .vtr format...")
  df <- utils::read.delim(
    tsv_path,
    fileEncoding = "UTF-8",
    stringsAsFactors = FALSE,
    quote = "",
    na.strings = "",
    check.names = FALSE
  )

  # Strip namespace prefixes from column names (dwc:taxonID -> taxonID)
  names(df) <- sub("^[a-z]+:", "", names(df))

  # Select only needed columns (match + extra for add_col_info)
  keep <- intersect(c(.col_match_cols, .col_extra_cols), names(df))
  df <- df[, keep, drop = FALSE]

  # Normalize taxonomicStatus to uppercase for consistent handling
  if ("taxonomicStatus" %in% names(df)) {
    df$taxonomicStatus <- toupper(df$taxonomicStatus)
  }
  if ("taxonRank" %in% names(df)) {
    df$taxonRank <- toupper(df$taxonRank)
  }

  # COL scientificName includes authorship — create canonical name for matching
  # Strip authorship by removing the scientificNameAuthorship suffix
  if (all(c("scientificName", "scientificNameAuthorship") %in% names(df))) {
    df$canonicalName <- col_strip_authorship(df$scientificName,
                                             df$scientificNameAuthorship)
  } else {
    df$canonicalName <- df$scientificName
  }

  # Denormalize family names from parent chain
  # COL stores hierarchy relationally; family column is empty for species/genera
  if (verbose) message("Denormalizing family names...")
  df$family <- col_resolve_family(df)

  # Strip whitespace from key text columns
  text_cols <- intersect(
    c("canonicalName", "scientificName", "family", "genericName",
      "specificEpithet", "scientificNameAuthorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
  }

  vectra::write_vtr(df, vtr_path)
  write_backbone_meta(vtr_path, "col", backend$version, url, nrow(df))
  write_version_meta(dest, "col", backend$version, pinned = FALSE)

  # Convert SpeciesProfile.tsv if present
  if (!is.null(sp_path) && file.exists(sp_path)) {
    sp_vtr <- file.path(dest, "col_species_profile.vtr")
    if (verbose) message("Converting SpeciesProfile.tsv to .vtr format...")
    sp_df <- utils::read.delim(
      sp_path,
      fileEncoding = "UTF-8",
      stringsAsFactors = FALSE,
      quote = "",
      na.strings = "",
      check.names = FALSE
    )
    names(sp_df) <- sub("^[a-z]+:", "", names(sp_df))
    vectra::write_vtr(sp_df, sp_vtr)
    unlink(sp_path)
  }

  # Clean up
  unlink(zip_path)
  unlink(tsv_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf("COL backbone saved: %s (%.0f MB)", vtr_path, size_mb))
  }

  invisible(vtr_path)
}


#' Resolve family names for all COL rows via vectorized tree propagation
#'
#' COL stores the classification hierarchy relationally via parentNameUsageID.
#' The family column is empty for most taxa. This resolves it using fully
#' vectorized operations — no R-level per-row loops.
#'
#' Strategy:
#' 1. FAMILY-rank rows: family = own canonicalName (seed)
#' 2. Vectorized BFS: propagate family from parent to child, one tree level
#'    per iteration. Each iteration is a single vectorized index lookup.
#' 3. After propagation, fill remaining species/subspecies via genericName
#'    → genus family lookup (handles cases where genus is in a different
#'    tree branch).
#'
#' @param df The full COL data.frame with columns taxonID, taxonRank,
#'   canonicalName, parentNameUsageID, genericName.
#' @return Character vector of family names (same length as nrow(df)).
#' @noRd
col_resolve_family <- function(df) {
  n <- nrow(df)
  family <- rep(NA_character_, n)

  rank <- toupper(df$taxonRank)

  # Step 1: Seed — family-rank rows know their own name
  is_family <- rank == "FAMILY"
  family[is_family] <- df$canonicalName[is_family]

  # Build taxonID → row index lookup (vectorized hash map)
  id_to_idx <- stats::setNames(seq_len(n), df$taxonID)

  # Precompute parent index for every row (one vectorized lookup)
  parent_idx <- unname(id_to_idx[df$parentNameUsageID])

  # Step 2: Vectorized BFS propagation
  # Each iteration: for rows still missing family, inherit from parent if
  # parent's family is known. One tree level per iteration.
  # COL tree depth is ~15 max (kingdom→species), so 15 iterations suffice.
  for (iter in seq_len(15L)) {
    missing <- is.na(family) & !is.na(parent_idx)
    if (!any(missing)) break
    # Vectorized: look up parent's family for all missing rows at once
    parent_fam <- family[parent_idx[missing]]
    resolved <- !is.na(parent_fam)
    if (!any(resolved)) break
    idx_missing <- which(missing)
    family[idx_missing[resolved]] <- parent_fam[resolved]
  }

  # Step 3: Fill remaining via genericName → genus family lookup
  # This catches species whose genus was resolved but they themselves
  # weren't linked via parentNameUsageID (e.g., synonyms pointing to
  # accepted taxa in a different branch)
  is_genus <- rank == "GENUS"
  genus_names <- df$canonicalName[is_genus]
  genus_families <- family[is_genus]
  has_fam <- !is.na(genus_families)
  if (any(has_fam)) {
    genus_fam_lookup <- stats::setNames(genus_families[has_fam],
                                        genus_names[has_fam])
    needs_family <- is.na(family) & !is.na(df$genericName)
    if (any(needs_family)) {
      family[needs_family] <- unname(
        genus_fam_lookup[df$genericName[needs_family]]
      )
    }
  }

  family
}


#' Strip authorship from COL scientificName to produce canonical name
#'
#' COL's scientificName includes authorship (e.g., "Quercus robur L.").
#' We strip the authorship suffix to get the canonical name for matching.
#'
#' @param sci_name Character vector of scientificName values.
#' @param authorship Character vector of scientificNameAuthorship values.
#' @return Character vector of canonical names.
#' @noRd
col_strip_authorship <- function(sci_name, authorship) {
  canonical <- sci_name
  has_both <- !is.na(sci_name) & !is.na(authorship) & nzchar(authorship)
  if (any(has_both)) {
    # COL format: scientificName = "Genus epithet Authorship"
    # Strip by removing the last nchar(authorship) characters
    sn <- sci_name[has_both]
    au <- authorship[has_both]
    sn_len <- nchar(sn)
    au_len <- nchar(au)
    # Only strip if name is long enough and ends with the authorship
    strip_len <- sn_len - au_len
    can_strip <- strip_len > 0L
    canonical[has_both][can_strip] <- trimws(
      substr(sn[can_strip], 1L, strip_len[can_strip])
    )
  }
  canonical
}


#' @noRd
taxify_load.taxify_col <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "col.vtr")
  if (!file.exists(path)) {
    stop(sprintf("COL backbone not found at: %s\nRun taxify_download('col') first.",
                 path),
         call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching
# ------------------------------------------------------------------

#' @noRd
match_exact.taxify_col <- function(backend, names_df, backbone, ...) {
  # Same strategy as WFO: exact on canonicalName, then case-insensitive.
  # COL uses genericName instead of genus.
  # genus_only names match against genericName where taxonRank == "GENUS".

  bb_path <- backbone
  cleaned <- names_df$cleaned
  genus_only <- names_df$genus_only
  has_name <- !is.na(cleaned)

  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid <- names_df$is_hybrid

  if (!any(has_name)) return(result)

  # --- Genus-only pass: match against genericName where rank is GENUS ---
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
        vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genericName, specificEpithet,
                       scientificNameAuthorship),
      by = c("cleaned_name" = "canonicalName")
    ) |> vectra::collect()

    if (nrow(genus_matches) > 0L) {
      fill_col_matches(result, genus_matches, match_type = "exact",
                       name_col = "cleaned_name")
    }
  }

  # --- Species-level passes: skip genus_only rows ---
  species_mask <- has_name & !genus_only
  if (!any(species_mask)) return(result)

  # Write input names to temp .vtr for vectra joins
  input_df <- data.frame(
    row_idx = which(species_mask),
    cleaned_name = cleaned[species_mask],
    stringsAsFactors = FALSE
  )
  tmp_input <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_input), add = TRUE)
  vectra::write_vtr(input_df, tmp_input)

  # Pass 1: Exact match on cleaned_name == canonicalName
  exact <- vectra::inner_join(
    vectra::tbl(tmp_input),
    vectra::tbl(bb_path) |>
      vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                     acceptedNameUsageID, family, genericName, specificEpithet,
                     scientificNameAuthorship),
    by = c("cleaned_name" = "canonicalName")
  ) |> vectra::collect()

  if (nrow(exact) > 0L) {
    fill_col_matches(result, exact, match_type = "exact")
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
        vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genericName, specificEpithet,
                       scientificNameAuthorship) |>
        vectra::mutate(join_key = tolower(canonicalName)),
      by = "join_key"
    ) |> vectra::collect()

    if (nrow(ci_matches) > 0L) {
      fill_col_matches(result, ci_matches, match_type = "exact_ci",
                       name_col = "canonicalName")
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
        vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                       acceptedNameUsageID, family, genericName, specificEpithet,
                       scientificNameAuthorship),
      by = c("species_name" = "canonicalName")
    ) |> vectra::collect()

    if (nrow(sp_matches) > 0L) {
      fill_col_matches(result, sp_matches, match_type = "exact",
                       name_col = "species_name")
    }
  }

  result
}


#' Fill match results from COL join output
#'
#' Shared helper for exact and case-insensitive passes.
#'
#' @param result The match result data.frame (modified in place via parent env).
#' @param matches The collected join output.
#' @param match_type Character. "exact" or "exact_ci".
#' @param name_col Character. Column name containing the matched name.
#' @return NULL (modifies result in the calling environment).
#' @noRd
fill_col_matches <- function(result, matches, match_type,
                             name_col = "cleaned_name") {
  env <- parent.frame()
  res <- env$result
  for (ri in unique(matches$row_idx)) {
    candidates <- matches[matches$row_idx == ri, , drop = FALSE]
    best <- pick_best(candidates)
    i <- best$row_idx
    res$matched_name[i] <- best[[name_col]]
    res$taxon_id[i] <- best$taxonID
    res$rank[i] <- tolower(best$taxonRank)
    res$taxonomicStatus[i] <- best$taxonomicStatus
    res$accepted_id_raw[i] <- best$acceptedNameUsageID
    res$family[i] <- best$family
    res$genus[i] <- best$genericName
    res$epithet[i] <- best$specificEpithet
    res$authorship[i] <- best$scientificNameAuthorship
    res$match_type[i] <- match_type
    res$fuzzy_dist[i] <- NA_real_
  }
  env$result <- res
  invisible(NULL)
}


#' @noRd
match_fuzzy.taxify_col <- function(backend, unmatched_df, backbone,
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

    # Genus-filtered fuzzy query using COL's canonicalName and genericName
    candidates <- run_col_fuzzy_query(bb_path, genus_name, cleaned,
                                      method, threshold, by_genus = TRUE)

    # Fallback: prefix filter if genus found nothing
    if (nrow(candidates) == 0L) {
      prefix <- substr(cleaned, 1L, 3L)
      candidates <- run_col_fuzzy_query(bb_path, prefix, cleaned,
                                        method, threshold, by_genus = FALSE)
    }

    if (nrow(candidates) == 0L) next

    if (jw_mode) {
      candidates$dist <- 1.0 - candidates$dist
      candidates <- candidates[order(candidates$dist), , drop = FALSE]
    }

    best <- pick_best(candidates)
    result$matched_name[i] <- best$canonicalName
    result$taxon_id[i] <- best$taxonID
    result$rank[i] <- tolower(best$taxonRank)
    result$taxonomicStatus[i] <- best$taxonomicStatus
    result$accepted_id_raw[i] <- best$acceptedNameUsageID
    result$family[i] <- best$family
    result$genus[i] <- best$genericName
    result$epithet[i] <- best$specificEpithet
    result$authorship[i] <- best$scientificNameAuthorship
    result$match_type[i] <- "fuzzy"
    result$fuzzy_dist[i] <- best$dist
  }

  result
}


#' Run a single fuzzy query against the COL backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character. Genus name (if by_genus) or prefix string.
#' @param target Character. The cleaned name to match against.
#' @param method Character. "dl", "levenshtein", or "jw".
#' @param threshold Numeric. Maximum distance (or minimum similarity for JW).
#' @param by_genus Logical. If TRUE, filter by genericName column.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_col_fuzzy_query <- function(bb_path, filter_value, target,
                                method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                     acceptedNameUsageID, family, genericName, specificEpithet,
                     scientificNameAuthorship)

    if (by_genus) {
      bb <- bb |> vectra::filter(genericName == filter_value)
    } else {
      bb <- bb |> vectra::filter(startsWith(canonicalName, filter_value))
    }

    if (method == "dl") {
      bb <- bb |>
        vectra::mutate(dist = dl_dist_norm(canonicalName, target)) |>
        vectra::filter(dist <= threshold)
    } else if (method == "levenshtein") {
      bb <- bb |>
        vectra::mutate(dist = levenshtein_norm(canonicalName, target)) |>
        vectra::filter(dist <= threshold)
    } else {
      jw_thresh <- 1.0 - threshold
      bb <- bb |>
        vectra::mutate(dist = jaro_winkler(canonicalName, target)) |>
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
resolve_synonyms.taxify_col <- function(backend, matches, backbone, ...) {
  bb_path <- backbone
  result <- matches

  # COL synonym statuses (already uppercased): SYNONYM, AMBIGUOUS SYNONYM, MISAPPLIED

  synonym_rows <- which(
    !is.na(result$taxonomicStatus) &
    grepl("SYNONYM|MISAPPLIED", result$taxonomicStatus)
  )

  if (length(synonym_rows) == 0L) {
    accepted_rows <- !is.na(result$matched_name)
    result$accepted_name[accepted_rows] <- result$matched_name[accepted_rows]
    result$accepted_id[accepted_rows] <- result$taxon_id[accepted_rows]
    result$is_synonym[accepted_rows] <- FALSE
    return(result)
  }

  # Look up accepted names
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
        vectra::select(taxonID, canonicalName, family, genericName),
      by = c("lookup_id" = "taxonID")
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
        result$accepted_name[i] <- acc$canonicalName[1L]
        result$accepted_id[i] <- acc$lookup_id[1L]
        result$family[i] <- acc$family[1L] %||% result$family[i]
        result$genus[i] <- acc$genericName[1L] %||% result$genus[i]
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

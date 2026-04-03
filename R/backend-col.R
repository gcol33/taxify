# ---- COL (Catalogue of Life) backend ----
#
# Offline matching against COL Darwin Core Archive snapshots from ChecklistBank.
# Downloads Taxon.tsv (+ SpeciesProfile.tsv for add_col_info), compiles to .vtr
# with precomputed keys and embedded accepted info, queries via vectra.

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

# Column map for shared matching engine
.col_col_map <- list(
  name       = "canonicalName",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genericName",
  id         = "taxonID",
  rank       = "taxonRank",
  status     = "taxonomicStatus",
  acc_id     = "acceptedNameUsageID",
  family     = "family",
  genus_out  = "genericName",
  epithet    = "specificEpithet",
  authorship = "scientificNameAuthorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a COL backend object
#'
#' @return A taxify_backend object of class `"taxify_col"`.
#' @noRd
col_backend <- function() {
  new_backend(
    name = "col",
    version = .col_version,
    genus_col = "genericName",
    col_map = .col_col_map,
    class = "taxify_col"
  )
}


#' @export
taxify_download.taxify_col <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("col", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "col.vtr")
  url <- .col_url
  zip_path <- file.path(dest, "col_download.zip")

  # Download
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

  # Read Taxon.tsv
  if (verbose) message("Reading Taxon.tsv...")
  df <- utils::read.delim(
    tsv_path,
    fileEncoding = "UTF-8",
    stringsAsFactors = FALSE,
    quote = "",
    na.strings = "",
    check.names = FALSE
  )

  # Strip namespace prefixes (dwc:taxonID -> taxonID)
  names(df) <- sub("^[a-z]+:", "", names(df))

  # Select needed columns
  keep <- intersect(c(.col_match_cols, .col_extra_cols), names(df))
  df <- df[, keep, drop = FALSE]

  # Normalize status and rank to uppercase
  if ("taxonomicStatus" %in% names(df))
    df$taxonomicStatus <- toupper(df$taxonomicStatus)
  if ("taxonRank" %in% names(df))
    df$taxonRank <- toupper(df$taxonRank)

  # Build canonical name (strip authorship from scientificName)
  if (all(c("scientificName", "scientificNameAuthorship") %in% names(df))) {
    df$canonicalName <- col_strip_authorship(df$scientificName,
                                             df$scientificNameAuthorship)
  } else {
    df$canonicalName <- df$scientificName
  }

  # Denormalize family names from parent chain
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

  # ---- Compile: precompute keys ----
  if (verbose) message("Precomputing match keys...")
  df <- precompute_keys(df, "canonicalName", "genericName", "specificEpithet")

  # ---- Compile: embed accepted info (synonym self-join) ----
  if (verbose) message("Embedding accepted taxon info...")
  df <- embed_accepted(df,
    id_col     = "taxonID",
    acc_id_col = "acceptedNameUsageID",
    name_col   = "canonicalName",
    family_col = "family",
    genus_col  = "genericName",
    status_col = "taxonomicStatus",
    synonym_pattern = "SYNONYM|MISAPPLIED"
  )

  # ---- Sort by genericName for zone-map pruning ----
  if ("genericName" %in% names(df)) {
    df <- df[order(df$genericName, na.last = TRUE), ]
    rownames(df) <- NULL
  }

  # ---- Write with controlled row-group size ----
  if (verbose) message("Writing compiled backbone...")
  vectra::write_vtr(df, vtr_path, batch_size = 50000L)
  write_backbone_meta(vtr_path, "col", backend$version, url, nrow(df))
  write_version_meta(dest, "col", backend$version, pinned = FALSE)

  # ---- Build indexes ----
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonicalName", "genericName")

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

  # Build taxonID → row index lookup
  id_to_idx <- stats::setNames(seq_len(n), df$taxonID)

  # Precompute parent index
  parent_idx <- unname(id_to_idx[df$parentNameUsageID])

  # Step 2: Vectorized BFS propagation
  for (iter in seq_len(15L)) {
    missing <- is.na(family) & !is.na(parent_idx)
    if (!any(missing)) break
    parent_fam <- family[parent_idx[missing]]
    resolved <- !is.na(parent_fam)
    if (!any(resolved)) break
    idx_missing <- which(missing)
    family[idx_missing[resolved]] <- parent_fam[resolved]
  }

  # Step 3: Fill remaining via genericName → genus family lookup
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
#' @param sci_name Character vector of scientificName values.
#' @param authorship Character vector of scientificNameAuthorship values.
#' @return Character vector of canonical names.
#' @noRd
col_strip_authorship <- function(sci_name, authorship) {
  canonical <- sci_name
  has_both <- !is.na(sci_name) & !is.na(authorship) & nzchar(authorship)
  if (any(has_both)) {
    sn <- sci_name[has_both]
    au <- authorship[has_both]
    sn_len <- nchar(sn)
    au_len <- nchar(au)
    strip_len <- sn_len - au_len
    can_strip <- strip_len > 0L
    canonical[has_both][can_strip] <- trimws(
      substr(sn[can_strip], 1L, strip_len[can_strip])
    )
  }
  canonical
}


#' @exportS3Method
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
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_col <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .col_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_col <- function(backend, unmatched_df, backbone,
                                   method = "dl", threshold = 0.2,
                                   names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw' (Jaro-Winkler range is 0-1)")
  }

  # Main pass: genus-blocked fuzzy join
  result <- fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                                 .col_col_map)

  # Prefix fallback for remaining unmatched (misspelled genus)
  still_unmatched <- which(is.na(result$match_type) & !is.na(result$input_name))
  if (length(still_unmatched) > 0L) {
    for (i in still_unmatched) {
      cleaned <- if (!is.null(names_df)) {
        cl <- names_df$cleaned[i]
        if (!is.na(cl) && nzchar(cl)) cl else clean_one(result$input_name[i])$cleaned
      } else {
        clean_one(result$input_name[i])$cleaned
      }
      if (is.na(cleaned) || !nzchar(cleaned)) next

      prefix <- substr(cleaned, 1L, 3L)
      candidates <- run_col_fuzzy_query(bb_path, prefix, cleaned, method,
                                        threshold, by_genus = FALSE)
      if (nrow(candidates) == 0L) next

      if (method == "jw") candidates$dist <- 1.0 - candidates$dist
      candidates <- candidates[order(candidates$dist), , drop = FALSE]

      candidates$taxonID <- candidates$taxonID
      candidates$taxonRank <- candidates$taxonRank
      candidates$taxonomicStatus <- candidates$taxonomicStatus

      best <- pick_best(candidates)
      result$matched_name[i]  <- best$canonicalName
      result$taxon_id[i]      <- best$taxonID
      result$rank[i]          <- tolower(best$taxonRank)
      result$accepted_name[i] <- best$accepted_name
      result$accepted_id[i]   <- best$accepted_taxon_id
      result$family[i]        <- best$accepted_family
      result$genus[i]         <- best$accepted_genus
      result$epithet[i]       <- best$specificEpithet
      result$authorship[i]    <- best$scientificNameAuthorship
      result$is_synonym[i]    <- best$is_synonym
      result$match_type[i]    <- "fuzzy"
      result$fuzzy_dist[i]    <- best$dist
    }
  }

  result
}


#' Run a single fuzzy query against the COL backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character.
#' @param target Character.
#' @param method Character.
#' @param threshold Numeric.
#' @param by_genus Logical.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_col_fuzzy_query <- function(bb_path, filter_value, target,
                                method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(taxonID, canonicalName, taxonRank, taxonomicStatus,
                     family, genericName, specificEpithet,
                     scientificNameAuthorship,
                     accepted_name, accepted_family, accepted_genus,
                     accepted_taxon_id, is_synonym)

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

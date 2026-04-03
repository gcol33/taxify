# ---- WFO (World Flora Online) backend ----
#
# Offline matching against WFO Darwin Core snapshots from Zenodo.
# Downloads classification.txt, compiles to .vtr with precomputed keys
# and embedded accepted info, queries via vectra.

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

# Column map for shared matching engine
.wfo_col_map <- list(
  name       = "scientificName",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus",
  id         = "taxonID",
  rank       = "taxonRank",
  status     = "taxonomicStatus",
  acc_id     = "acceptedNameUsageID",
  family     = "family",
  genus_out  = "genus",
  epithet    = "specificEpithet",
  authorship = "scientificNameAuthorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a WFO backend object
#'
#' @return A taxify_backend object of class `"taxify_wfo"`.
#' @noRd
wfo_backend <- function() {
  new_backend(
    name = "wfo",
    version = .wfo_version,
    genus_col = "genus",
    col_map = .wfo_col_map,
    class = "taxify_wfo"
  )
}


#' @export
taxify_download.taxify_wfo <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("wfo", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "wfo.vtr")
  url <- .wfo_url
  zip_path <- file.path(dest, "wfo_download.zip")

  # Download
  if (verbose) {
    message(sprintf("Downloading WFO backbone (%s) from Zenodo (~120 MB)...",
                    backend$version))
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, zip_path, mode = "wb", quiet = !verbose)

  # Extract classification file
  if (verbose) message("Extracting classification file...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  txt_target <- txt_files[grepl("classification\\.(txt|csv)$", txt_files)]
  if (length(txt_target) == 0L) {
    stop("classification.txt/.csv not found in downloaded archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = txt_target[1L], exdir = dest, junkpaths = TRUE)
  txt_path <- file.path(dest, basename(txt_target[1L]))

  # Read TSV
  if (verbose) message("Reading classification file...")
  df <- utils::read.delim(
    txt_path,
    fileEncoding = "latin1",
    stringsAsFactors = FALSE,
    na.strings = ""
  )

  # Select needed columns
  keep <- intersect(c(.wfo_match_cols, .wfo_extra_cols), names(df))
  df <- df[, keep, drop = FALSE]

  # Normalize status and rank to uppercase
  if ("taxonomicStatus" %in% names(df))
    df$taxonomicStatus <- toupper(df$taxonomicStatus)
  if ("taxonRank" %in% names(df))
    df$taxonRank <- toupper(df$taxonRank)

  # Fix mojibake: UTF-8 × misread as Latin-1
  text_cols <- intersect(
    c("scientificName", "family", "genus", "specificEpithet",
      "scientificNameAuthorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
    df[[col]] <- gsub("\u00c3\u0097", "\u00d7", df[[col]], fixed = TRUE)
  }

  # ---- Compile: precompute keys ----
  if (verbose) message("Precomputing match keys...")
  df$normalizedName <- normalize_epithets(df$scientificName)
  df <- precompute_keys(df, "scientificName", "genus", "specificEpithet")

  # ---- Compile: embed accepted info (synonym self-join) ----
  if (verbose) message("Embedding accepted taxon info...")
  df <- embed_accepted(df,
    id_col    = "taxonID",
    acc_id_col = "acceptedNameUsageID",
    name_col  = "scientificName",
    family_col = "family",
    genus_col = "genus",
    status_col = "taxonomicStatus"
  )

  # ---- Sort by genus for zone-map pruning ----
  if ("genus" %in% names(df)) {
    df <- df[order(df$genus, na.last = TRUE), ]
    rownames(df) <- NULL
  }

  # ---- Write with controlled row-group size ----
  if (verbose) message("Writing compiled backbone...")
  vectra::write_vtr(df, vtr_path, batch_size = 50000L)
  write_backbone_meta(vtr_path, "wfo", backend$version, url, nrow(df))
  write_version_meta(dest, "wfo", backend$version, pinned = FALSE)

  # ---- Build indexes ----
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "scientificName", "genus")

  # Clean up
  unlink(zip_path)
  unlink(txt_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf("WFO backbone saved: %s (%.0f MB)", vtr_path, size_mb))
  }

  invisible(vtr_path)
}


#' @exportS3Method
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
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_wfo <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .wfo_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_wfo <- function(backend, unmatched_df, backbone,
                                   method = "dl", threshold = 0.2,
                                   names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw' (Jaro-Winkler range is 0-1)")
  }

  # Main pass: genus-blocked fuzzy join
  result <- fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                                 .wfo_col_map)

  # Unblocked fallback for remaining unmatched (misspelled genus)
  # Single fuzzy_join without genus blocking instead of per-name loop
  result <- fuzzy_match_unblocked(result, names_df, bb_path, method, threshold,
                                  .wfo_col_map)

  result
}


#' Run a single fuzzy query against the backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character. Genus name (if by_genus) or prefix string.
#' @param target Character. The cleaned name to match against.
#' @param method Character. "dl", "levenshtein", or "jw".
#' @param threshold Numeric. Maximum distance.
#' @param by_genus Logical.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_fuzzy_query <- function(bb_path, filter_value, target,
                            method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                     family, genus, specificEpithet,
                     scientificNameAuthorship,
                     accepted_name, accepted_family, accepted_genus,
                     accepted_taxon_id, is_synonym)

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

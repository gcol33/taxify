# ---- GBIF (Global Biodiversity Information Facility) backbone backend ----
#
# Offline matching against GBIF backbone taxonomy (simple.txt.gz).
# Downloads from hosted-datasets.gbif.org, compiles to .vtr with precomputed
# keys and embedded accepted info, queries via vectra.
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

# Column map for shared matching engine
.gbif_col_map <- list(
  name       = "canonical_name",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus_or_above",
  id         = "id",
  rank       = "rank",
  status     = "status",
  acc_id     = "accepted_id",
  family     = "family",
  genus_out  = "genus_or_above",
  epithet    = "specific_epithet",
  authorship = "authorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a GBIF backend object
#'
#' @return A taxify_backend object of class `"taxify_gbif"`.
#' @noRd
gbif_backend <- function() {
  new_backend(
    name = "gbif",
    version = .gbif_version,
    genus_col = "genus_or_above",
    col_map = .gbif_col_map,
    class = "taxify_gbif"
  )
}


#' @export
taxify_download.taxify_gbif <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("gbif", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "gbif.vtr")
  url <- .gbif_url
  gz_path <- file.path(dest, "gbif_download.txt.gz")

  # Download
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

  # Build accepted_id: for synonyms, parent_key = accepted taxon ID
  df$is_synonym_flag <- df$is_synonym == "t"
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

  # Normalize GBIF status to standard form for the compiled schema.
  # Map all synonym-type statuses to "SYNONYM" for embed_accepted.
  df$status <- gbif_status_to_standard(df$status)

  # ---- Compile: precompute keys ----
  if (verbose) message("Precomputing match keys...")
  df <- precompute_keys(df, "canonical_name", "genus_or_above",
                        "specific_epithet")

  # ---- Compile: embed accepted info (synonym self-join) ----
  if (verbose) message("Embedding accepted taxon info...")
  df <- embed_accepted(df,
    id_col     = "id",
    acc_id_col = "accepted_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus_or_above",
    status_col = "status"
  )

  # ---- Sort by genus_or_above for zone-map pruning ----
  if ("genus_or_above" %in% names(df)) {
    df <- df[order(df$genus_or_above, na.last = TRUE), ]
    rownames(df) <- NULL
  }

  # ---- Write with controlled row-group size ----
  if (verbose) message("Writing compiled backbone...")
  vectra::write_vtr(df, vtr_path, batch_size = 50000L)
  write_backbone_meta(vtr_path, "gbif", backend$version, url, nrow(df))
  write_version_meta(dest, "gbif", backend$version, pinned = FALSE)

  # ---- Build indexes ----
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonical_name", "genus_or_above")

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
#' @param df The full GBIF data.frame.
#' @param key_col Integer vector of keys to resolve.
#' @return Character vector of resolved names.
#' @noRd
gbif_resolve_higher <- function(df, key_col) {
  lookup <- stats::setNames(df$canonical_name, as.character(df$id))
  resolved <- lookup[as.character(key_col)]
  unname(resolved)
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


#' @exportS3Method
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
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_gbif <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .gbif_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_gbif <- function(backend, unmatched_df, backbone,
                                    method = "dl", threshold = 0.2,
                                    names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  # Main pass: genus-blocked fuzzy join
  result <- fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                                 .gbif_col_map)

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
      candidates <- run_gbif_fuzzy_query(bb_path, prefix, cleaned, method,
                                         threshold, by_genus = FALSE)
      if (nrow(candidates) == 0L) next

      if (method == "jw") candidates$dist <- 1.0 - candidates$dist
      candidates <- candidates[order(candidates$dist), , drop = FALSE]

      candidates$taxonID <- candidates$id
      candidates$taxonRank <- candidates$rank
      candidates$taxonomicStatus <- candidates$status

      best <- pick_best(candidates)
      result$matched_name[i]  <- best$canonical_name
      result$taxon_id[i]      <- best$id
      result$rank[i]          <- tolower(best$rank)
      result$accepted_name[i] <- best$accepted_name
      result$accepted_id[i]   <- best$accepted_taxon_id
      result$family[i]        <- best$accepted_family
      result$genus[i]         <- best$accepted_genus
      result$epithet[i]       <- best$specific_epithet
      result$authorship[i]    <- best$authorship
      result$is_synonym[i]    <- best$is_synonym
      result$match_type[i]    <- "fuzzy"
      result$fuzzy_dist[i]    <- best$dist
    }
  }

  result
}


#' Run a single fuzzy query against the GBIF backbone
#'
#' @param bb_path Path to backbone .vtr.
#' @param filter_value Character.
#' @param target Character.
#' @param method Character.
#' @param threshold Numeric.
#' @param by_genus Logical.
#' @return A data.frame of candidates (may be empty).
#' @noRd
run_gbif_fuzzy_query <- function(bb_path, filter_value, target,
                                 method, threshold, by_genus) {
  tryCatch({
    bb <- vectra::tbl(bb_path) |>
      vectra::select(id, canonical_name, rank, status,
                     family, genus_or_above, specific_epithet, authorship,
                     accepted_name, accepted_family, accepted_genus,
                     accepted_taxon_id, is_synonym)

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

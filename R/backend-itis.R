# ---- ITIS (Integrated Taxonomic Information System) backend ----
#
# Offline matching against ITIS SQLite snapshots. Pre-built .vtr backbones
# are downloaded from GitHub Releases via the manifest. Build-from-source
# requires RSQLite (in Suggests).
#
# ITIS strengths: North American fauna (insects, fish, mammals), all kingdoms.
# Complements WFO (plants-focused) and COL (broader but slower to update).

# ITIS source URL and version
.itis_url <- "https://www.itis.gov/downloads/itisSqlite.zip"
.itis_version <- "2025.04"

# Column map for shared matching engine
# These map to the unified backbone schema produced by taxify-backbones
.itis_col_map <- list(
  name       = "canonical_name",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus",
  id         = "taxon_id",
  rank       = "taxon_rank",
  status     = "taxonomic_status",
  acc_id     = "accepted_name_usage_id",
  family     = "family",
  genus_out  = "genus",
  epithet    = "specific_epithet",
  authorship = "authorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create an ITIS backend object
#'
#' @return A taxify_backend object of class `"taxify_itis"`.
#' @noRd
itis_backend <- function() {
  new_backend(
    name = "itis",
    version = .itis_version,
    genus_col = "genus",
    col_map = .itis_col_map,
    class = "taxify_itis"
  )
}


#' @export
taxify_download.taxify_itis <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  if (!requireNamespace("RSQLite", quietly = TRUE)) {
    stop(
      "RSQLite is required to build ITIS from source.\n",
      "Install with: install.packages('RSQLite')\n",
      "Or use taxify_download_vtr('itis') to download a pre-built backbone.",
      call. = FALSE
    )
  }

  dest <- dest %||% versioned_dir("itis", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "itis.vtr")
  zip_path <- file.path(dest, "itisSqlite.zip")

  # Download (use curl for reliable large file download)
  if (verbose) message("Downloading ITIS SQLite dump (~212 MB)...")
  curl::curl_download(.itis_url, zip_path, quiet = !verbose)

  if (verbose) message("Extracting...")
  utils::unzip(zip_path, exdir = dest)

  # Find .sqlite file
  sqlite_files <- list.files(dest, pattern = "\\.sqlite$",
                             recursive = TRUE, full.names = TRUE)
  if (length(sqlite_files) == 0L) {
    stop("No .sqlite file found in ITIS download.", call. = FALSE)
  }
  sqlite_path <- sqlite_files[1L]

  # Convert SQLite to normalized data.frame
  if (verbose) message("Converting ITIS database...")
  df <- itis_sqlite_to_df(sqlite_path, verbose = verbose)

  # Precompute keys
  if (verbose) message("Precomputing match keys...")
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")

  # Embed accepted info
  if (verbose) message("Embedding accepted taxon info...")
  df <- embed_accepted(df,
    id_col     = "taxon_id",
    acc_id_col = "accepted_name_usage_id",
    name_col   = "canonical_name",
    family_col = "family",
    genus_col  = "genus",
    status_col = "taxonomic_status"
  )

  # Sort by genus
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL

  # Write .vtr
  if (verbose) message("Writing compiled backbone...")
  vectra::write_vtr(df, vtr_path, batch_size = 50000L)
  write_backbone_meta(vtr_path, "itis", backend$version, .itis_url, nrow(df))
  write_version_meta(dest, "itis", backend$version, pinned = FALSE)

  # Build indexes
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonical_name", "genus")

  # Clean up
  unlink(zip_path)
  unlink(sqlite_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf("ITIS backbone saved: %s (%.0f MB, %s rows)",
                    vtr_path, size_mb, format(nrow(df), big.mark = ",")))
  }

  invisible(vtr_path)
}


#' Convert ITIS SQLite database to a normalized data.frame
#'
#' Reads the key tables, resolves the parent-child hierarchy for family/genus,
#' maps synonym relationships, and produces the unified backbone schema.
#'
#' @param sqlite_path Character. Path to the ITIS .sqlite file.
#' @param verbose Logical.
#' @return A normalized data.frame (not yet precomputed — no key_ci etc.).
#' @noRd
itis_sqlite_to_df <- function(sqlite_path, verbose = TRUE) {
  con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  # ---- Read tables ----
  if (verbose) message("  Reading taxonomic_units...")
  taxa <- DBI::dbGetQuery(con, "
    SELECT tsn, complete_name, rank_id, name_usage, parent_tsn,
           unit_name1, unit_name2, unit_name3, unit_name4,
           taxon_author_id, kingdom_id
    FROM taxonomic_units
  ")
  if (verbose) message(sprintf("    %s rows",
                               format(nrow(taxa), big.mark = ",")))

  # Rank names
  if (verbose) message("  Joining rank names...")
  ranks <- DBI::dbGetQuery(con, "
    SELECT rank_id, rank_name, kingdom_id FROM taxon_unit_types
  ")
  ranks$key <- paste(ranks$rank_id, ranks$kingdom_id, sep = "_")
  taxa$key <- paste(taxa$rank_id, taxa$kingdom_id, sep = "_")
  taxa$rank_name <- ranks$rank_name[match(taxa$key, ranks$key)]
  taxa$key <- NULL

  # Authors
  if (verbose) message("  Joining authors...")
  authors <- DBI::dbGetQuery(con, "
    SELECT taxon_author_id, taxon_author FROM taxon_authors_lkp
  ")
  taxa$authorship <- authors$taxon_author[match(taxa$taxon_author_id,
                                                 authors$taxon_author_id)]

  # Synonyms
  if (verbose) message("  Resolving synonyms...")
  syn_links <- DBI::dbGetQuery(con, "
    SELECT tsn, tsn_accepted FROM synonym_links
  ")
  taxa$accepted_tsn <- syn_links$tsn_accepted[match(taxa$tsn, syn_links$tsn)]

  # Map name_usage to standard status
  taxa$taxonomic_status <- ifelse(
    tolower(taxa$name_usage) %in% c("valid", "accepted"),
    "ACCEPTED", "SYNONYM"
  )
  taxa$accepted_name_usage_id <- ifelse(
    !is.na(taxa$accepted_tsn),
    as.character(taxa$accepted_tsn),
    ifelse(taxa$taxonomic_status == "SYNONYM",
           as.character(taxa$parent_tsn),
           NA_character_)
  )

  # ---- Hierarchy walk for family/genus ----
  if (verbose) message("  Walking hierarchy for family/genus...")
  taxa$id <- as.character(taxa$tsn)
  taxa$parent_id <- as.character(taxa$parent_tsn)

  # Build parent lookup
  parent_row <- match(taxa$parent_id, taxa$id)
  rank_lower <- tolower(taxa$rank_name)

  # Initialize
  taxa$family <- ifelse(rank_lower == "family", taxa$complete_name,
                         NA_character_)
  taxa$genus <- ifelse(rank_lower == "genus", taxa$complete_name,
                        NA_character_)

  # Walk up (max 25 hops covers kingdom->species)
  current_parent <- parent_row
  for (depth in seq_len(25L)) {
    needs_family <- is.na(taxa$family) & !is.na(current_parent)
    needs_genus <- is.na(taxa$genus) & !is.na(current_parent)

    if (!any(needs_family) && !any(needs_genus)) break

    if (any(needs_family)) {
      is_family <- rank_lower[current_parent[needs_family]] == "family"
      match_idx <- which(needs_family)[is_family]
      if (length(match_idx) > 0L) {
        taxa$family[match_idx] <- taxa$complete_name[current_parent[match_idx]]
      }
    }

    if (any(needs_genus)) {
      is_genus <- rank_lower[current_parent[needs_genus]] == "genus"
      match_idx <- which(needs_genus)[is_genus]
      if (length(match_idx) > 0L) {
        taxa$genus[match_idx] <- taxa$complete_name[current_parent[match_idx]]
      }
    }

    # Move up
    next_parent <- rep(NA_integer_, nrow(taxa))
    has_p <- !is.na(current_parent)
    next_parent[has_p] <- match(taxa$parent_id[current_parent[has_p]], taxa$id)
    current_parent <- next_parent
  }

  # ---- Parse epithet components ----
  taxa$specific_epithet <- ifelse(
    !is.na(taxa$unit_name2) & nzchar(trimws(taxa$unit_name2)),
    trimws(taxa$unit_name2), NA_character_
  )
  taxa$infraspecific_epithet <- ifelse(
    !is.na(taxa$unit_name3) & nzchar(trimws(taxa$unit_name3)),
    trimws(taxa$unit_name3),
    ifelse(!is.na(taxa$unit_name4) & nzchar(trimws(taxa$unit_name4)),
           trimws(taxa$unit_name4), NA_character_)
  )

  # ---- Build output ----
  data.frame(
    taxon_id                = taxa$id,
    canonical_name          = trimws(taxa$complete_name),
    taxon_rank              = toupper(trimws(taxa$rank_name)),
    taxonomic_status        = taxa$taxonomic_status,
    accepted_name_usage_id  = taxa$accepted_name_usage_id,
    family                  = trimws(taxa$family),
    genus                   = trimws(taxa$genus),
    specific_epithet        = taxa$specific_epithet,
    authorship              = trimws(taxa$authorship),
    infraspecific_epithet   = taxa$infraspecific_epithet,
    stringsAsFactors        = FALSE
  )
}


#' @exportS3Method
taxify_load.taxify_itis <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "itis.vtr")
  if (!file.exists(path)) {
    stop(sprintf(
      "ITIS backbone not found at: %s\nRun taxify_download('itis') first.",
      path
    ), call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_itis <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .itis_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_itis <- function(backend, unmatched_df, backbone,
                                    method = "dl", threshold = 0.2,
                                    names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw'")
  }

  fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                       .itis_col_map)
}

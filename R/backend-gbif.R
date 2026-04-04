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
    unblocked_fallback = TRUE,
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

  # Compile and write
  compile_backbone(df, vtr_path, backend, url, verbose = verbose)

  # Clean up
  unlink(gz_path)
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



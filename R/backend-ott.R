# ---- Open Tree of Life (OTT) backend ----
#
# Offline matching against Open Tree Taxonomy snapshots. Pre-built .vtr
# backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads the OTT taxonomy archive from
# files.opentreeoflife.org.
#
# OTT strengths: synthetic taxonomy combining NCBI, GBIF, WoRMS, IRMNG,
# and others. Broadest coverage of any single source. Cross-references
# to source databases via sourceinfo column.

# OTT source URL and version
.ott_url <- "https://files.opentreeoflife.org/ott/ott3.7/ott3.7.tgz"
.ott_version <- "3.7"

# Column map for shared matching engine
.ott_col_map <- list(
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


#' Create an OTT backend object
#'
#' @return A taxify_backend object of class `"taxify_ott"`.
#' @noRd
ott_backend <- function() {
  new_backend(
    name = "ott",
    version = .ott_version,
    genus_col = "genus",
    col_map = .ott_col_map,
    class = "taxify_ott"
  )
}


#' @export
taxify_download.taxify_ott <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("ott", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "ott.vtr")
  tar_path <- file.path(dest, "ott.tgz")

  # Download
  if (verbose) message("Downloading OTT taxonomy (~110 MB)...")
  utils::download.file(.ott_url, tar_path, mode = "wb", quiet = !verbose)

  if (verbose) message("Extracting...")
  utils::untar(tar_path, exdir = dest)

  # Find extracted directory (e.g., ott3.7/)
  ott_dirs <- list.dirs(dest, recursive = FALSE, full.names = TRUE)
  ott_dir <- ott_dirs[grepl("^ott", basename(ott_dirs))][1L]
  if (is.na(ott_dir)) {
    stop("Could not find OTT directory in extracted archive.", call. = FALSE)
  }

  # Convert to normalized data.frame
  if (verbose) message("Converting OTT taxonomy...")
  df <- ott_to_df(ott_dir, verbose = verbose)

  # Compile and write
  compile_backbone(df, vtr_path, backend, .ott_url, verbose = verbose)

  # Clean up
  unlink(tar_path)
  unlink(ott_dir, recursive = TRUE)
}


#' Parse OTT taxonomy.tsv and synonyms.tsv to a normalized data.frame
#'
#' OTT uses pipe-delimited fields (tab-pipe-tab) despite .tsv extension.
#' taxonomy.tsv contains accepted names; synonyms.tsv contains synonym
#' mappings. Hierarchy walk resolves family/genus from parent_uid.
#'
#' @param ott_dir Character. Path to extracted OTT directory.
#' @param verbose Logical.
#' @return A normalized data.frame.
#' @noRd
ott_to_df <- function(ott_dir, verbose = TRUE) {
  # ---- Read taxonomy.tsv (accepted names) ----
  # Columns: uid | parent_uid | name | rank | sourceinfo | uniqname | flags
  if (verbose) message("  Reading taxonomy.tsv...")
  tax_raw <- readLines(file.path(ott_dir, "taxonomy.tsv"), warn = FALSE)

  # First line is header — skip it
  tax_raw <- tax_raw[-1L]

  tax_split <- strsplit(tax_raw, "\t\\|\t?", perl = TRUE)
  taxa <- data.frame(
    uid        = vapply(tax_split, `[`, character(1L), 1L),
    parent_uid = vapply(tax_split, `[`, character(1L), 2L),
    name       = trimws(vapply(tax_split, `[`, character(1L), 3L)),
    rank       = trimws(vapply(tax_split, `[`, character(1L), 4L)),
    flags      = trimws(vapply(tax_split, function(x) {
      if (length(x) >= 7L) x[7L] else ""
    }, character(1L))),
    stringsAsFactors = FALSE
  )
  # Clean trailing pipe from flags
  taxa$flags <- sub("\\|$", "", taxa$flags)

  if (verbose) message(sprintf("    %s accepted taxa",
                               format(nrow(taxa), big.mark = ",")))

  # ---- Read synonyms.tsv ----
  # Columns: name | uid | type | uniqname
  if (verbose) message("  Reading synonyms.tsv...")
  syn_raw <- readLines(file.path(ott_dir, "synonyms.tsv"), warn = FALSE)
  syn_raw <- syn_raw[-1L]  # skip header

  syn_split <- strsplit(syn_raw, "\t\\|\t?", perl = TRUE)
  syns <- data.frame(
    name = trimws(vapply(syn_split, `[`, character(1L), 1L)),
    uid  = trimws(vapply(syn_split, `[`, character(1L), 2L)),
    type = trimws(vapply(syn_split, function(x) {
      if (length(x) >= 3L) x[3L] else ""
    }, character(1L))),
    stringsAsFactors = FALSE
  )
  if (verbose) message(sprintf("    %s synonyms",
                               format(nrow(syns), big.mark = ",")))

  # ---- Hierarchy walk for family/genus ----
  if (verbose) message("  Walking hierarchy for family/genus...")
  rank_lower <- tolower(taxa$rank)
  parent_row <- match(taxa$parent_uid, taxa$uid)

  taxa$family <- ifelse(rank_lower == "family", taxa$name, NA_character_)
  taxa$genus <- ifelse(rank_lower == "genus", taxa$name, NA_character_)

  current_parent <- parent_row
  for (depth in seq_len(25L)) {
    needs_family <- is.na(taxa$family) & !is.na(current_parent)
    needs_genus <- is.na(taxa$genus) & !is.na(current_parent)

    if (!any(needs_family) && !any(needs_genus)) break

    if (any(needs_family)) {
      is_family <- rank_lower[current_parent[needs_family]] == "family"
      match_idx <- which(needs_family)[is_family]
      if (length(match_idx) > 0L) {
        taxa$family[match_idx] <- taxa$name[current_parent[match_idx]]
      }
    }

    if (any(needs_genus)) {
      is_genus <- rank_lower[current_parent[needs_genus]] == "genus"
      match_idx <- which(needs_genus)[is_genus]
      if (length(match_idx) > 0L) {
        taxa$genus[match_idx] <- taxa$name[current_parent[match_idx]]
      }
    }

    next_parent <- rep(NA_integer_, nrow(taxa))
    has_p <- !is.na(current_parent)
    next_parent[has_p] <- match(
      taxa$parent_uid[current_parent[has_p]], taxa$uid)
    current_parent <- next_parent
  }

  # ---- Parse epithet ----
  words <- strsplit(taxa$name, " ", fixed = TRUE)
  taxa$specific_epithet <- vapply(words, function(w) {
    if (length(w) >= 2L) w[2L] else NA_character_
  }, character(1L))
  species_ranks <- c("species", "subspecies", "varietas", "variety",
                     "forma", "form", "infraspecies")
  taxa$specific_epithet[!rank_lower %in% species_ranks] <- NA_character_

  # ---- Build accepted rows ----
  accepted_df <- data.frame(
    taxon_id                = taxa$uid,
    canonical_name          = taxa$name,
    taxon_rank              = toupper(taxa$rank),
    taxonomic_status        = "ACCEPTED",
    accepted_name_usage_id  = NA_character_,
    family                  = taxa$family,
    genus                   = taxa$genus,
    specific_epithet        = taxa$specific_epithet,
    authorship              = NA_character_,
    infraspecific_epithet   = NA_character_,
    stringsAsFactors        = FALSE
  )

  # ---- Build synonym rows ----
  # Keep only taxonomic synonyms (skip common names, authority, etc.)
  syn_types <- c("synonym", "equivalent name", "genbank synonym",
                 "anamorph", "teleomorph", "misspelling")
  syns <- syns[syns$type %in% syn_types, ]

  if (nrow(syns) > 0L) {
    syn_node_row <- match(syns$uid, taxa$uid)
    valid_syn <- !is.na(syn_node_row)
    syns <- syns[valid_syn, ]
    syn_node_row <- syn_node_row[valid_syn]

    # Parse epithet from synonym name
    syn_words <- strsplit(syns$name, " ", fixed = TRUE)
    syn_epithet <- vapply(syn_words, function(w) {
      if (length(w) >= 2L) w[2L] else NA_character_
    }, character(1L))
    syn_ranks <- rank_lower[syn_node_row]
    syn_epithet[!syn_ranks %in% species_ranks] <- NA_character_

    syn_df <- data.frame(
      taxon_id                = paste0(syns$uid, "_syn_",
                                       seq_len(nrow(syns))),
      canonical_name          = syns$name,
      taxon_rank              = toupper(taxa$rank[syn_node_row]),
      taxonomic_status        = "SYNONYM",
      accepted_name_usage_id  = syns$uid,
      family                  = taxa$family[syn_node_row],
      genus                   = taxa$genus[syn_node_row],
      specific_epithet        = syn_epithet,
      authorship              = NA_character_,
      infraspecific_epithet   = NA_character_,
      stringsAsFactors        = FALSE
    )

    df <- rbind(accepted_df, syn_df)
  } else {
    df <- accepted_df
  }

  rownames(df) <- NULL
  df
}



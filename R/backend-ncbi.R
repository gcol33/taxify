# ---- NCBI Taxonomy backend ----
#
# Offline matching against NCBI Taxonomy taxdump snapshots. Pre-built .vtr
# backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads taxdump.tar.gz from NCBI FTP.
#
# NCBI strengths: comprehensive coverage of all life (bacteria, viruses,
# eukaryotes), sequence-linked taxonomy, gold standard for molecular studies.

# NCBI source URL and version
.ncbi_url <- "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz"
.ncbi_version <- "2025.04"

# Column map for shared matching engine
.ncbi_col_map <- list(
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


#' Create an NCBI Taxonomy backend object
#'
#' @return A taxify_backend object of class `"taxify_ncbi"`.
#' @noRd
ncbi_backend <- function() {
  new_backend(
    name = "ncbi",
    version = .ncbi_version,
    genus_col = "genus",
    col_map = .ncbi_col_map,
    class = "taxify_ncbi"
  )
}


#' @export
taxify_download.taxify_ncbi <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("ncbi", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "ncbi.vtr")
  tar_path <- file.path(dest, "taxdump.tar.gz")

  # Download
  if (verbose) message("Downloading NCBI taxdump (~60 MB)...")
  utils::download.file(.ncbi_url, tar_path, mode = "wb", quiet = !verbose)

  if (verbose) message("Extracting...")
  utils::untar(tar_path, exdir = dest)

  # Convert dump files to normalized data.frame
  if (verbose) message("Converting NCBI taxonomy...")
  df <- ncbi_dump_to_df(dest, verbose = verbose)

  # Compile and write
  compile_backbone(df, vtr_path, backend, .ncbi_url, verbose = verbose)

  # Clean up dump files
  dump_files <- list.files(dest, pattern = "\\.dmp$", full.names = TRUE)
  unlink(c(tar_path, dump_files))
  unlink(file.path(dest, "gc.prt"))
  unlink(file.path(dest, "readme.txt"))
}


#' Parse NCBI taxdump .dmp files to a normalized data.frame
#'
#' Reads nodes.dmp and names.dmp, walks the parent hierarchy for family/genus,
#' and produces the unified backbone schema. Synonyms in NCBI are alternative
#' name strings for the same tax_id — they are emitted as separate rows with
#' accepted_name_usage_id pointing to the same tax_id's scientific name row.
#'
#' @param dump_dir Character. Directory containing the extracted .dmp files.
#' @param verbose Logical.
#' @return A normalized data.frame.
#' @noRd
ncbi_dump_to_df <- function(dump_dir, verbose = TRUE) {
  # ---- Read nodes.dmp ----
  # Format: tax_id | parent_tax_id | rank | ... (13+ columns, \t|\t delimited)
  if (verbose) message("  Reading nodes.dmp...")
  nodes_raw <- readLines(file.path(dump_dir, "nodes.dmp"), warn = FALSE)
  nodes_split <- strsplit(nodes_raw, "\t\\|\t?", perl = TRUE)
  nodes <- data.frame(
    tax_id        = vapply(nodes_split, `[`, character(1L), 1L),
    parent_tax_id = vapply(nodes_split, `[`, character(1L), 2L),
    rank          = trimws(vapply(nodes_split, `[`, character(1L), 3L)),
    stringsAsFactors = FALSE
  )
  if (verbose) message(sprintf("    %s nodes",
                               format(nrow(nodes), big.mark = ",")))

  # ---- Read names.dmp ----
  # Format: tax_id | name_txt | unique_name | name_class
  if (verbose) message("  Reading names.dmp...")
  names_raw <- readLines(file.path(dump_dir, "names.dmp"), warn = FALSE)
  names_split <- strsplit(names_raw, "\t\\|\t?", perl = TRUE)
  names_df <- data.frame(
    tax_id     = vapply(names_split, `[`, character(1L), 1L),
    name_txt   = trimws(vapply(names_split, `[`, character(1L), 2L)),
    name_class = trimws(vapply(names_split, `[`, character(1L), 4L)),
    stringsAsFactors = FALSE
  )
  if (verbose) message(sprintf("    %s name entries",
                               format(nrow(names_df), big.mark = ",")))

  # ---- Separate scientific names and synonyms ----
  sci <- names_df[names_df$name_class == "scientific name", ]
  syn_classes <- c("synonym", "equivalent name", "genbank synonym",
                   "anamorph", "teleomorph")
  syns <- names_df[names_df$name_class %in% syn_classes, ]

  # Build scientific name lookup: tax_id -> scientific name
  sci_name_lookup <- sci$name_txt
  names(sci_name_lookup) <- sci$tax_id

  # ---- Merge nodes + scientific names ----
  sci_row <- match(nodes$tax_id, sci$tax_id)
  nodes$canonical_name <- sci$name_txt[sci_row]

  # Drop nodes without a scientific name (shouldn't happen, but defensive)
  nodes <- nodes[!is.na(nodes$canonical_name), ]

  # ---- Hierarchy walk for family/genus ----
  if (verbose) message("  Walking hierarchy for family/genus...")
  rank_lower <- tolower(nodes$rank)
  parent_row <- match(nodes$parent_tax_id, nodes$tax_id)

  nodes$family <- ifelse(rank_lower == "family", nodes$canonical_name,
                         NA_character_)
  nodes$genus <- ifelse(rank_lower == "genus", nodes$canonical_name,
                        NA_character_)

  current_parent <- parent_row
  for (depth in seq_len(25L)) {
    needs_family <- is.na(nodes$family) & !is.na(current_parent)
    needs_genus <- is.na(nodes$genus) & !is.na(current_parent)

    if (!any(needs_family) && !any(needs_genus)) break

    if (any(needs_family)) {
      is_family <- rank_lower[current_parent[needs_family]] == "family"
      match_idx <- which(needs_family)[is_family]
      if (length(match_idx) > 0L) {
        nodes$family[match_idx] <- nodes$canonical_name[
          current_parent[match_idx]]
      }
    }

    if (any(needs_genus)) {
      is_genus <- rank_lower[current_parent[needs_genus]] == "genus"
      match_idx <- which(needs_genus)[is_genus]
      if (length(match_idx) > 0L) {
        nodes$genus[match_idx] <- nodes$canonical_name[
          current_parent[match_idx]]
      }
    }

    next_parent <- rep(NA_integer_, nrow(nodes))
    has_p <- !is.na(current_parent)
    next_parent[has_p] <- match(
      nodes$parent_tax_id[current_parent[has_p]], nodes$tax_id)
    current_parent <- next_parent
  }

  # ---- Parse epithet from canonical_name ----
  words <- strsplit(nodes$canonical_name, " ", fixed = TRUE)
  nodes$specific_epithet <- vapply(words, function(w) {
    if (length(w) >= 2L) w[2L] else NA_character_
  }, character(1L))
  # Only keep epithet for species-level and below
  species_ranks <- c("species", "subspecies", "varietas", "variety",
                     "forma", "form", "subvariety")
  nodes$specific_epithet[!rank_lower %in% species_ranks] <- NA_character_

  # ---- Build accepted rows (one per node) ----
  accepted_df <- data.frame(
    taxon_id                = nodes$tax_id,
    canonical_name          = nodes$canonical_name,
    taxon_rank              = toupper(nodes$rank),
    taxonomic_status        = "ACCEPTED",
    accepted_name_usage_id  = NA_character_,
    family                  = nodes$family,
    genus                   = nodes$genus,
    specific_epithet        = nodes$specific_epithet,
    authorship              = NA_character_,
    infraspecific_epithet   = NA_character_,
    stringsAsFactors        = FALSE
  )

  # ---- Build synonym rows ----
  if (nrow(syns) > 0L) {
    # Each synonym gets a synthetic ID: "tax_id_syn_N"
    syn_node_row <- match(syns$tax_id, nodes$tax_id)
    valid_syn <- !is.na(syn_node_row)
    syns <- syns[valid_syn, ]
    syn_node_row <- syn_node_row[valid_syn]

    # Parse epithet from synonym name
    syn_words <- strsplit(syns$name_txt, " ", fixed = TRUE)
    syn_epithet <- vapply(syn_words, function(w) {
      if (length(w) >= 2L) w[2L] else NA_character_
    }, character(1L))
    # Only keep for species-level nodes
    syn_ranks <- rank_lower[syn_node_row]
    syn_epithet[!syn_ranks %in% species_ranks] <- NA_character_

    syn_df <- data.frame(
      taxon_id                = paste0(syns$tax_id, "_syn_",
                                       seq_len(nrow(syns))),
      canonical_name          = syns$name_txt,
      taxon_rank              = toupper(nodes$rank[syn_node_row]),
      taxonomic_status        = "SYNONYM",
      accepted_name_usage_id  = syns$tax_id,
      family                  = nodes$family[syn_node_row],
      genus                   = nodes$genus[syn_node_row],
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



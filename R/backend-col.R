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
    unblocked_fallback = TRUE,
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

  # Compile and write (COL uses MISAPPLIED in addition to SYNONYM)
  compile_backbone(df, vtr_path, backend, url, verbose = verbose,
                   synonym_pattern = "SYNONYM|MISAPPLIED")

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



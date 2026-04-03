# ---- WoRMS (World Register of Marine Species) backend ----
#
# Offline matching against WoRMS Darwin Core Archive snapshots. Pre-built .vtr
# backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads the WoRMS DwC-A from GBIF ChecklistBank.
#
# WoRMS strengths: authoritative taxonomy for marine species, curated by
# taxonomic experts, includes habitat flags (marine/brackish/freshwater/
# terrestrial) and extinction status.

# WoRMS via GBIF ChecklistBank (dataset key: 2d59e5db-57ad-41ff-97d6-11f5fb264527)
.worms_url <- "https://api.checklistbank.org/dataset/2011/archive"
.worms_version <- "2025.04"

# Column map for shared matching engine
.worms_col_map <- list(
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


#' Create a WoRMS backend object
#'
#' @return A taxify_backend object of class `"taxify_worms"`.
#' @noRd
worms_backend <- function() {
  new_backend(
    name = "worms",
    version = .worms_version,
    genus_col = "genus",
    col_map = .worms_col_map,
    class = "taxify_worms"
  )
}


#' @export
taxify_download.taxify_worms <- function(backend, dest = NULL,
                                         verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("worms", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "worms.vtr")
  zip_path <- file.path(dest, "worms_dwca.zip")

  # Download
  if (verbose) {
    message("Downloading WoRMS DwC-A from ChecklistBank...")
    message(sprintf("  URL: %s", .worms_url))
  }
  utils::download.file(.worms_url, zip_path, mode = "wb", quiet = !verbose)

  # Extract Taxon.tsv
  if (verbose) message("Extracting Taxon.tsv...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  taxon_target <- txt_files[grepl("Taxon\\.tsv$|taxon\\.txt$", txt_files,
                                  ignore.case = TRUE)]
  if (length(taxon_target) == 0L) {
    stop("Taxon file not found in WoRMS DwC-A archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = taxon_target[1L], exdir = dest,
               junkpaths = TRUE)
  tsv_path <- file.path(dest, basename(taxon_target[1L]))

  # Also extract SpeciesProfile if present
  sp_target <- txt_files[grepl("SpeciesProfile|speciesprofile",
                               txt_files, ignore.case = TRUE)]
  sp_path <- NULL
  if (length(sp_target) > 0L) {
    if (verbose) message("Extracting SpeciesProfile...")
    utils::unzip(zip_path, files = sp_target[1L], exdir = dest,
                 junkpaths = TRUE)
    sp_path <- file.path(dest, basename(sp_target[1L]))
  }

  # Read Taxon file
  if (verbose) message("Reading taxon data...")
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

  # Convert to unified schema
  if (verbose) message("Normalizing to unified schema...")
  df <- worms_normalize(df)

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
  write_backbone_meta(vtr_path, "worms", backend$version,
                      .worms_url, nrow(df))
  write_version_meta(dest, "worms", backend$version, pinned = FALSE)

  # Build indexes
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonical_name", "genus")

  # Convert SpeciesProfile if present
  if (!is.null(sp_path) && file.exists(sp_path)) {
    sp_vtr <- file.path(dest, "worms_species_profile.vtr")
    if (verbose) message("Converting SpeciesProfile to .vtr format...")
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
    message(sprintf("WoRMS backbone saved: %s (%.0f MB, %s rows)",
                    vtr_path, size_mb, format(nrow(df), big.mark = ",")))
  }

  invisible(vtr_path)
}


#' Normalize WoRMS DwC-A data.frame to unified schema
#'
#' WoRMS uses DwC column names with some differences from COL:
#' - taxonomicStatus uses "accepted"/"unaccepted" (lowercase, non-standard)
#' - taxonID may be LSID (urn:lsid:marinespecies.org:taxname:NNNNN)
#' - scientificName includes authorship
#' - family, genus are denormalized (no hierarchy walk needed)
#'
#' @param df Data.frame read from WoRMS Taxon.tsv.
#' @return A normalized data.frame with unified schema columns.
#' @noRd
worms_normalize <- function(df) {
  # Extract numeric AphiaID from LSID if needed
  tid <- df$taxonID
  is_lsid <- grepl("^urn:lsid:", tid, perl = TRUE)
  if (any(is_lsid)) {
    tid[is_lsid] <- sub("^.*:", "", tid[is_lsid])
  }

  # Build canonical name by stripping authorship
  canonical <- df$scientificName
  auth <- if ("scientificNameAuthorship" %in% names(df)) {
    df$scientificNameAuthorship
  } else {
    NA_character_
  }

  has_both <- !is.na(canonical) & !is.na(auth) & nzchar(auth)
  if (any(has_both)) {
    sn <- canonical[has_both]
    au <- auth[has_both]
    sn_len <- nchar(sn)
    au_len <- nchar(au)
    strip_len <- sn_len - au_len
    can_strip <- strip_len > 0L
    canonical[has_both][can_strip] <- trimws(
      substr(sn[can_strip], 1L, strip_len[can_strip])
    )
  }

  # Map status: accepted/valid -> ACCEPTED, everything else -> SYNONYM
  raw_status <- tolower(df$taxonomicStatus)
  status <- ifelse(raw_status %in% c("accepted", "valid"),
                   "ACCEPTED", "SYNONYM")

  # Resolve accepted_name_usage_id: strip LSID if present
  acc_id <- df$acceptedNameUsageID
  if (!is.null(acc_id)) {
    is_lsid_acc <- !is.na(acc_id) & grepl("^urn:lsid:", acc_id, perl = TRUE)
    if (any(is_lsid_acc)) {
      acc_id[is_lsid_acc] <- sub("^.*:", "", acc_id[is_lsid_acc])
    }
  } else {
    acc_id <- NA_character_
  }

  # Get genus — WoRMS DwC-A has denormalized classification columns
  genus_col <- if ("genus" %in% names(df)) {
    df$genus
  } else if ("genericName" %in% names(df)) {
    df$genericName
  } else {
    # Parse from canonical name
    sub(" .*", "", canonical)
  }

  # Get family
  family_col <- if ("family" %in% names(df)) df$family else NA_character_

  # Get epithet
  epithet <- if ("specificEpithet" %in% names(df)) {
    df$specificEpithet
  } else {
    NA_character_
  }

  # Get infraspecific epithet
  infra <- if ("infraspecificEpithet" %in% names(df)) {
    df$infraspecificEpithet
  } else {
    NA_character_
  }

  # Get rank
  rank <- if ("taxonRank" %in% names(df)) toupper(df$taxonRank) else
    NA_character_

  data.frame(
    taxon_id                = tid,
    canonical_name          = trimws(canonical),
    taxon_rank              = rank,
    taxonomic_status        = status,
    accepted_name_usage_id  = acc_id,
    family                  = trimws(family_col),
    genus                   = trimws(genus_col),
    specific_epithet        = trimws(epithet),
    authorship              = trimws(auth),
    infraspecific_epithet   = trimws(infra),
    stringsAsFactors        = FALSE
  )
}


#' @exportS3Method
taxify_load.taxify_worms <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "worms.vtr")
  if (!file.exists(path)) {
    stop(sprintf(
      "WoRMS backbone not found at: %s\nRun taxify_download('worms') first.",
      path
    ), call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_worms <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .worms_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_worms <- function(backend, unmatched_df, backbone,
                                     method = "dl", threshold = 0.2,
                                     names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw'")
  }

  fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                       .worms_col_map)
}

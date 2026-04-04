# ---- Species Fungorum Plus backend ----
#
# Offline matching against Species Fungorum Plus (curated fungal taxonomy).
# Pre-built .vtr backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads the DwC-A from GBIF ChecklistBank (dataset 2073).
#
# Species Fungorum Plus: curated checklist with 95% completeness, CC BY license,
# denormalized classification (kingdom through genus), ~329k names.

# ChecklistBank dataset 2073
.fungorum_url <- "https://api.checklistbank.org/dataset/2073/export?format=DWCA"
.fungorum_version <- "2025.04"

# Column map for shared matching engine
.fungorum_col_map <- list(
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


#' Create a Species Fungorum Plus backend object
#'
#' @return A taxify_backend object of class `"taxify_fungorum"`.
#' @noRd
fungorum_backend <- function() {
  new_backend(
    name = "fungorum",
    version = .fungorum_version,
    genus_col = "genus",
    col_map = .fungorum_col_map,
    class = "taxify_fungorum"
  )
}


#' @export
taxify_download.taxify_fungorum <- function(backend, dest = NULL,
                                         verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("fungorum", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "fungorum.vtr")
  zip_path <- file.path(dest, "fungorum_dwca.zip")

  # Download
  if (verbose) {
    message("Downloading Species Fungorum Plus DwC-A from ChecklistBank...")
    message(sprintf("  URL: %s", .fungorum_url))
  }
  utils::download.file(.fungorum_url, zip_path, mode = "wb", quiet = !verbose)

  # Extract TSV — archive uses dataset-2073.tsv (no Taxon.tsv)
  if (verbose) message("Extracting taxon data...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  taxon_target <- txt_files[grepl("Taxon\\.tsv$|taxon\\.txt$|^dataset-.*\\.tsv$",
                                  txt_files, ignore.case = TRUE)]
  if (length(taxon_target) == 0L) {
    stop("Taxon file not found in Species Fungorum Plus DwC-A archive",
         call. = FALSE)
  }
  utils::unzip(zip_path, files = taxon_target[1L], exdir = dest,
               junkpaths = TRUE)
  tsv_path <- file.path(dest, basename(taxon_target[1L]))

  # Read
  if (verbose) message("Reading taxon data...")
  df <- utils::read.delim(
    tsv_path,
    fileEncoding = "UTF-8",
    stringsAsFactors = FALSE,
    quote = "",
    na.strings = "",
    check.names = FALSE
  )

  # Strip namespace prefixes (dwc:taxonID -> taxonID, clb:taxGroup -> taxGroup)
  names(df) <- sub("^[a-z]+:", "", names(df))

  # Convert to unified schema
  if (verbose) message("Normalizing to unified schema...")
  df <- fungorum_normalize(df)

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
  write_backbone_meta(vtr_path, "fungorum", backend$version,
                      .fungorum_url, nrow(df))
  write_version_meta(dest, "fungorum", backend$version, pinned = FALSE)

  # Build indexes
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonical_name", "genus")

  # Clean up
  unlink(zip_path)
  unlink(tsv_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf(
      "Species Fungorum Plus backbone saved: %s (%.0f MB, %s rows)",
      vtr_path, size_mb, format(nrow(df), big.mark = ",")))
  }

  invisible(vtr_path)
}


#' Normalize Species Fungorum Plus data.frame to unified schema
#'
#' Species Fungorum Plus has denormalized classification (kingdom through genus),
#' scientificName is canonical (no embedded authorship), authorship is separate.
#'
#' @param df Data.frame read from the TSV.
#' @return A normalized data.frame with unified schema columns.
#' @noRd
fungorum_normalize <- function(df) {
  # Map status: accepted -> ACCEPTED, everything else -> SYNONYM
  raw_status <- tolower(df$taxonomicStatus)
  status <- ifelse(raw_status %in% c("accepted", "provisionally accepted"),
                   "ACCEPTED", "SYNONYM")

  # scientificName is already canonical in this dataset
  canonical <- trimws(df$scientificName)

  # Authorship
  auth <- if ("scientificNameAuthorship" %in% names(df)) {
    df$scientificNameAuthorship
  } else {
    NA_character_
  }

  # Genus — denormalized column available
  genus_col <- if ("genus" %in% names(df)) {
    df$genus
  } else {
    sub(" .*", "", canonical)
  }

  # Family — denormalized column available
  family_col <- if ("family" %in% names(df)) df$family else NA_character_

  # Epithet — parse from name for species-rank taxa
  words <- strsplit(canonical, " ", fixed = TRUE)
  epithet <- vapply(words, function(w) {
    if (length(w) >= 2L) w[2L] else NA_character_
  }, character(1L))
  rank_lower <- tolower(df$taxonRank)
  species_ranks <- c("species", "subspecies", "variety", "varietas",
                     "forma", "form", "infraspecies")
  epithet[!rank_lower %in% species_ranks] <- NA_character_

  # Infraspecific epithet
  infra <- vapply(words, function(w) {
    if (length(w) >= 3L) w[length(w)] else NA_character_
  }, character(1L))
  infra_ranks <- c("subspecies", "variety", "varietas", "forma", "form")
  infra[!rank_lower %in% infra_ranks] <- NA_character_

  data.frame(
    taxon_id                = as.character(df$taxonID),
    canonical_name          = canonical,
    taxon_rank              = toupper(df$taxonRank),
    taxonomic_status        = status,
    accepted_name_usage_id  = as.character(df$acceptedNameUsageID),
    family                  = trimws(family_col),
    genus                   = trimws(genus_col),
    specific_epithet        = trimws(epithet),
    authorship              = trimws(auth),
    infraspecific_epithet   = trimws(infra),
    stringsAsFactors        = FALSE
  )
}


#' @exportS3Method
taxify_load.taxify_fungorum <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "fungorum.vtr")
  if (!file.exists(path)) {
    stop(sprintf(
      "Species Fungorum Plus backbone not found at: %s\nRun taxify_download('fungorum') first.",
      path
    ), call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_fungorum <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .fungorum_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_fungorum <- function(backend, unmatched_df, backbone,
                                     method = "dl", threshold = 0.2,
                                     names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw'")
  }

  fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                       .fungorum_col_map)
}

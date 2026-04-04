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

  # Compile and write
  compile_backbone(df, vtr_path, backend, .fungorum_url, verbose = verbose)

  # Clean up
  unlink(zip_path)
  unlink(tsv_path)
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




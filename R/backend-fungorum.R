# ---- Species Fungorum Plus backend ----
#
# Offline matching against Species Fungorum Plus (curated fungal taxonomy).
# Pre-built .vtr backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads the DwC-A from GBIF ChecklistBank (dataset 2073).
#
# Species Fungorum Plus: curated checklist with 95% completeness, CC BY license,
# denormalized classification (kingdom through genus), ~329k names.

# ChecklistBank dataset 2073 — /archive serves the cached DwC-A zip directly
# (the /export endpoint returns the JSON tree, not a downloadable archive)
.fungorum_url <- "https://api.checklistbank.org/dataset/2073/archive"
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
  zip_path <- file.path(dest, "fungorum_coldp.zip")

  # Download
  if (verbose) {
    message("Downloading Species Fungorum Plus archive from ChecklistBank...")
    message(sprintf("  URL: %s", .fungorum_url))
  }
  utils::download.file(.fungorum_url, zip_path, mode = "wb", quiet = !verbose)

  # Extract the three ColDP files we need (Reference.tsv is unused)
  if (verbose) message("Extracting ColDP files...")
  needed <- c("Taxon.tsv", "Name.tsv", "Synonym.tsv")
  utils::unzip(zip_path, files = needed, exdir = dest, junkpaths = TRUE)

  read_coldp <- function(name) {
    utils::read.delim(
      file.path(dest, name),
      fileEncoding = "UTF-8",
      stringsAsFactors = FALSE,
      quote = "",
      na.strings = "",
      check.names = FALSE
    )
  }

  if (verbose) message("Reading Taxon.tsv ...")
  taxon <- read_coldp("Taxon.tsv")
  if (verbose) message("Reading Name.tsv ...")
  name <- read_coldp("Name.tsv")
  if (verbose) message("Reading Synonym.tsv ...")
  synonym <- read_coldp("Synonym.tsv")

  if (verbose) {
    message(sprintf("  taxa=%s  names=%s  synonyms=%s",
                    format(nrow(taxon), big.mark = ","),
                    format(nrow(name), big.mark = ","),
                    format(nrow(synonym), big.mark = ",")))
    message("Building unified schema (Taxon ⋈ Name, Synonym ⋈ Name ⋈ Taxon)...")
  }
  df <- fungorum_build_unified(taxon, name, synonym)

  # Compile and write
  compile_backbone(df, vtr_path, backend, .fungorum_url, verbose = verbose)

  # Clean up
  unlink(zip_path)
  unlink(file.path(dest, needed))
}


# ColDP rank token -> unified rank vocabulary.
# Anything below subspecies (Greek letters, digit codes, asterisks, single
# letters) is collapsed to INFRASPECIFIC; the original token is lost. Higher
# ranks (genus and above) never appear here because Fungorum's Name.tsv
# only catalogues species-and-below names.
.fungorum_rank_map <- c(
  "sp."        = "SPECIES",
  "sp"         = "SPECIES",
  "subsp."     = "SUBSPECIES",
  "var."       = "VARIETY",
  "var"        = "VARIETY",
  "subvar."    = "SUBVARIETY",
  "f."         = "FORM",
  "f"          = "FORM",
  "subf."      = "SUBFORM",
  "subsubf."   = "SUBFORM",
  "f.sp."      = "FORMA SPECIALIS",
  "subgen."    = "SUBGENUS",
  "sect."      = "SECTION",
  "subsect."   = "SUBSECTION",
  "ser."       = "SERIES",
  "nothosp."   = "NOTHOSPECIES",
  "[unranked]" = "UNRANKED"
)


#' Build the unified backbone data.frame from ColDP Taxon/Name/Synonym tables
#'
#' Fungorum's archive is ColDP (not DwC-A): Taxon rows hold denormalized higher
#' classification but reference their scientific name via `nameID` -> Name.ID.
#' Synonym rows link an accepted Taxon (`taxonID`) to a synonym Name (`nameID`).
#'
#' @noRd
fungorum_build_unified <- function(taxon, name, synonym) {
  # Index Name table by ID for vectorised lookups
  name_idx <- match(taxon$nameID, name$ID)
  if (anyNA(name_idx)) {
    n_missing <- sum(is.na(name_idx))
    warning(sprintf("Fungorum: %d Taxon rows reference unknown nameID", n_missing),
            call. = FALSE)
  }

  # ---- Accepted rows ----
  acc_canonical <- name$scientificName[name_idx]
  acc_rank_raw  <- tolower(name$rank[name_idx])
  acc_rank      <- unname(.fungorum_rank_map[acc_rank_raw])
  acc_rank[is.na(acc_rank) & !is.na(acc_rank_raw)] <- "INFRASPECIFIC"

  accepted <- data.frame(
    taxon_id                = as.character(taxon$ID),
    canonical_name          = trimws(acc_canonical),
    taxon_rank              = acc_rank,
    taxonomic_status        = "ACCEPTED",
    accepted_name_usage_id  = NA_character_,
    family                  = trimws(taxon$family),
    genus                   = trimws(taxon$genus),
    specific_epithet        = trimws(name$specificEpithet[name_idx]),
    authorship              = trimws(name$authorship[name_idx]),
    infraspecific_epithet   = trimws(name$infraspecificEpithet[name_idx]),
    stringsAsFactors        = FALSE
  )

  # ---- Synonym rows ----
  # Synonym table has no own ID; mint synthetic taxon_id from (taxonID, nameID)
  syn_name_idx <- match(synonym$nameID, name$ID)
  syn_taxon_idx <- match(synonym$taxonID, taxon$ID)

  if (anyNA(syn_name_idx) || anyNA(syn_taxon_idx)) {
    bad <- sum(is.na(syn_name_idx) | is.na(syn_taxon_idx))
    warning(sprintf("Fungorum: %d Synonym rows have unresolved name/taxon refs", bad),
            call. = FALSE)
  }

  syn_canonical <- name$scientificName[syn_name_idx]
  syn_rank_raw  <- tolower(name$rank[syn_name_idx])
  syn_rank      <- unname(.fungorum_rank_map[syn_rank_raw])
  syn_rank[is.na(syn_rank) & !is.na(syn_rank_raw)] <- "INFRASPECIFIC"

  synonyms <- data.frame(
    taxon_id                = paste0("syn_", as.character(synonym$taxonID),
                                     "_", as.character(synonym$nameID)),
    canonical_name          = trimws(syn_canonical),
    taxon_rank              = syn_rank,
    taxonomic_status        = "SYNONYM",
    accepted_name_usage_id  = as.character(synonym$taxonID),
    family                  = trimws(taxon$family[syn_taxon_idx]),
    genus                   = trimws(name$genus[syn_name_idx]),
    specific_epithet        = trimws(name$specificEpithet[syn_name_idx]),
    authorship              = trimws(name$authorship[syn_name_idx]),
    infraspecific_epithet   = trimws(name$infraspecificEpithet[syn_name_idx]),
    stringsAsFactors        = FALSE
  )

  # Drop rows with no canonical name (corrupt / orphan refs)
  out <- rbind(accepted, synonyms)
  out <- out[!is.na(out$canonical_name) & nzchar(out$canonical_name), ]
  rownames(out) <- NULL
  out
}




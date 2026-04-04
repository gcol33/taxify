# ---- WFO (World Flora Online) backend ----
#
# Offline matching against WFO Darwin Core snapshots from Zenodo.
# Downloads classification.txt, compiles to .vtr with precomputed keys
# and embedded accepted info, queries via vectra.

# Latest WFO backbone URL and version (updated with package releases)
.wfo_url <- "https://zenodo.org/records/14538251/files/_DwC_backbone_R.zip"
.wfo_version <- "2024-12"

# Columns needed for matching (core + authorship + infraspecific)
.wfo_match_cols <- c(
  "taxonID",
  "scientificName",
  "taxonRank",
  "taxonomicStatus",
  "acceptedNameUsageID",
  "family",
  "genus",
  "specificEpithet",
  "scientificNameAuthorship",
  "infraspecificEpithet"
)

# Extra columns for add_wfo_info() — additional columns in classification file
.wfo_extra_cols <- c(
  "scientificNameID",
  "parentNameUsageID",
  "namePublishedIn",
  "nomenclaturalStatus",
  "taxonRemarks",
  "subfamily",
  "tribe",
  "subtribe",
  "subgenus"
)

# Column map for shared matching engine
.wfo_col_map <- list(
  name       = "scientificName",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus",
  id         = "taxonID",
  rank       = "taxonRank",
  status     = "taxonomicStatus",
  acc_id     = "acceptedNameUsageID",
  family     = "family",
  genus_out  = "genus",
  epithet    = "specificEpithet",
  authorship = "scientificNameAuthorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a WFO backend object
#'
#' @return A taxify_backend object of class `"taxify_wfo"`.
#' @noRd
wfo_backend <- function() {
  new_backend(
    name = "wfo",
    version = .wfo_version,
    genus_col = "genus",
    col_map = .wfo_col_map,
    unblocked_fallback = TRUE,
    class = "taxify_wfo"
  )
}


#' @export
taxify_download.taxify_wfo <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("wfo", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "wfo.vtr")
  url <- .wfo_url
  zip_path <- file.path(dest, "wfo_download.zip")

  # Download
  if (verbose) {
    message(sprintf("Downloading WFO backbone (%s) from Zenodo (~120 MB)...",
                    backend$version))
    message(sprintf("  URL: %s", url))
  }
  utils::download.file(url, zip_path, mode = "wb", quiet = !verbose)

  # Extract classification file
  if (verbose) message("Extracting classification file...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  txt_target <- txt_files[grepl("classification\\.(txt|csv)$", txt_files)]
  if (length(txt_target) == 0L) {
    stop("classification.txt/.csv not found in downloaded archive", call. = FALSE)
  }
  utils::unzip(zip_path, files = txt_target[1L], exdir = dest, junkpaths = TRUE)
  txt_path <- file.path(dest, basename(txt_target[1L]))

  # Read TSV
  if (verbose) message("Reading classification file...")
  df <- utils::read.delim(
    txt_path,
    fileEncoding = "latin1",
    stringsAsFactors = FALSE,
    na.strings = ""
  )

  # Select needed columns
  keep <- intersect(c(.wfo_match_cols, .wfo_extra_cols), names(df))
  df <- df[, keep, drop = FALSE]

  # Normalize status and rank to uppercase
  if ("taxonomicStatus" %in% names(df))
    df$taxonomicStatus <- toupper(df$taxonomicStatus)
  if ("taxonRank" %in% names(df))
    df$taxonRank <- toupper(df$taxonRank)

  # Fix mojibake: UTF-8 × misread as Latin-1
  text_cols <- intersect(
    c("scientificName", "family", "genus", "specificEpithet",
      "scientificNameAuthorship"),
    names(df)
  )
  for (col in text_cols) {
    df[[col]] <- trimws(df[[col]])
    df[[col]] <- gsub("\u00c3\u0097", "\u00d7", df[[col]], fixed = TRUE)
  }

  # WFO-specific: extra normalized name column
  df$normalizedName <- normalize_epithets(df$scientificName)

  # Compile and write
  compile_backbone(df, vtr_path, backend, url, verbose = verbose)

  # Clean up
  unlink(zip_path)
  unlink(txt_path)
}



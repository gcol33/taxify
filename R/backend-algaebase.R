# ---- AlgaeBase backend ----
#
# Offline matching against AlgaeBase algal taxonomy snapshots. Pre-built .vtr
# backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source downloads the DwC-A from GBIF ChecklistBank (dataset 304756).
#
# AlgaeBase: curated algal taxonomy (~172k names). Authoritative for
# micro/macroalgae, cyanobacteria, and some protists.
#
# NOTE: AlgaeBase is licensed CC BY-NC. This means the backbone data may
# only be used for non-commercial purposes. Academic and research use is fine.

# ChecklistBank dataset 304756
.algaebase_url <- "https://api.checklistbank.org/dataset/304756/export?format=DWCA"
.algaebase_version <- "2025.04"

# Column map for shared matching engine
.algaebase_col_map <- list(
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


#' Create an AlgaeBase backend object
#'
#' @return A taxify_backend object of class `"taxify_algaebase"`.
#' @noRd
algaebase_backend <- function() {
  new_backend(
    name = "algaebase",
    version = .algaebase_version,
    genus_col = "genus",
    col_map = .algaebase_col_map,
    class = "taxify_algaebase"
  )
}


#' @export
taxify_download.taxify_algaebase <- function(backend, dest = NULL,
                                             verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("algaebase", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "algaebase.vtr")
  zip_path <- file.path(dest, "algaebase_dwca.zip")

  # License warning
  if (verbose) {
    message("NOTE: AlgaeBase is licensed CC BY-NC (non-commercial use only).")
    message("Downloading AlgaeBase DwC-A from ChecklistBank...")
    message(sprintf("  URL: %s", .algaebase_url))
  }
  utils::download.file(.algaebase_url, zip_path, mode = "wb", quiet = !verbose)

  # Extract Taxon.tsv
  if (verbose) message("Extracting Taxon.tsv...")
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  taxon_target <- txt_files[grepl("Taxon\\.tsv$|taxon\\.txt$|^dataset-.*\\.tsv$",
                                  txt_files, ignore.case = TRUE)]
  if (length(taxon_target) == 0L) {
    stop("Taxon file not found in AlgaeBase DwC-A archive", call. = FALSE)
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

  # Strip namespace prefixes (dwc:taxonID -> taxonID)
  names(df) <- sub("^[a-z]+:", "", names(df))

  # Convert to unified schema (includes hierarchy walk for family/genus)
  if (verbose) message("Normalizing to unified schema (hierarchy walk)...")
  df <- algaebase_normalize(df, verbose = verbose)

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
  write_backbone_meta(vtr_path, "algaebase", backend$version,
                      .algaebase_url, nrow(df))
  write_version_meta(dest, "algaebase", backend$version, pinned = FALSE)

  # Build indexes
  if (verbose) message("Building indexes...")
  create_backbone_indexes(vtr_path, "canonical_name", "genus")

  # Clean up
  unlink(zip_path)
  unlink(tsv_path)

  if (verbose) {
    size_mb <- file.size(vtr_path) / (1024 * 1024)
    message(sprintf(
      "AlgaeBase backbone saved: %s (%.0f MB, %s rows)",
      vtr_path, size_mb, format(nrow(df), big.mark = ",")))
  }

  invisible(vtr_path)
}


#' Normalize AlgaeBase DwC-A data.frame to unified schema
#'
#' AlgaeBase has only 7 columns with no denormalized classification.
#' Family and genus are resolved via hierarchy walk on parentNameUsageID.
#' scientificName is already canonical (no embedded authorship).
#'
#' @param df Data.frame read from AlgaeBase Taxon.tsv.
#' @param verbose Logical. Print progress messages.
#' @return A normalized data.frame with unified schema columns.
#' @noRd
algaebase_normalize <- function(df, verbose = TRUE) {
  # Map status
  raw_status <- tolower(df$taxonomicStatus)
  status <- ifelse(raw_status %in% c("accepted", "provisionally accepted"),
                   "ACCEPTED", "SYNONYM")

  # scientificName is already canonical
  canonical <- trimws(df$scientificName)

  # Authorship
  auth <- if ("scientificNameAuthorship" %in% names(df)) {
    df$scientificNameAuthorship
  } else {
    NA_character_
  }

  # Rank
  rank <- if ("taxonRank" %in% names(df)) toupper(df$taxonRank) else
    NA_character_

  # ---- Hierarchy walk for family/genus ----
  # AlgaeBase has no denormalized classification columns; resolve from
  # parentNameUsageID tree
  if (verbose) message("  Walking hierarchy for family/genus...")
  rank_lower <- tolower(df$taxonRank)
  id <- as.character(df$taxonID)
  parent_id <- as.character(df$parentNameUsageID)

  parent_row <- match(parent_id, id)

  family <- ifelse(rank_lower == "family", canonical, NA_character_)
  genus <- ifelse(rank_lower == "genus", canonical, NA_character_)

  current_parent <- parent_row
  for (depth in seq_len(25L)) {
    needs_family <- is.na(family) & !is.na(current_parent)
    needs_genus <- is.na(genus) & !is.na(current_parent)

    if (!any(needs_family) && !any(needs_genus)) break

    if (any(needs_family)) {
      is_family <- rank_lower[current_parent[needs_family]] == "family"
      match_idx <- which(needs_family)[is_family]
      if (length(match_idx) > 0L) {
        family[match_idx] <- canonical[current_parent[match_idx]]
      }
    }

    if (any(needs_genus)) {
      is_genus <- rank_lower[current_parent[needs_genus]] == "genus"
      match_idx <- which(needs_genus)[is_genus]
      if (length(match_idx) > 0L) {
        genus[match_idx] <- canonical[current_parent[match_idx]]
      }
    }

    next_parent <- rep(NA_integer_, nrow(df))
    has_p <- !is.na(current_parent)
    next_parent[has_p] <- match(parent_id[current_parent[has_p]], id)
    current_parent <- next_parent
  }

  # Fallback: parse genus from first word of canonical name for species-rank
  no_genus <- is.na(genus) & rank_lower %in% c("species", "subspecies",
                                                 "variety", "varietas",
                                                 "forma", "form")
  if (any(no_genus)) {
    genus[no_genus] <- sub(" .*", "", canonical[no_genus])
  }

  # Epithet
  words <- strsplit(canonical, " ", fixed = TRUE)
  epithet <- vapply(words, function(w) {
    if (length(w) >= 2L) w[2L] else NA_character_
  }, character(1L))
  species_ranks <- c("species", "subspecies", "variety", "varietas",
                     "forma", "form", "infraspecies")
  epithet[!rank_lower %in% species_ranks] <- NA_character_

  # Infraspecific epithet
  infra <- vapply(words, function(w) {
    if (length(w) >= 3L) w[length(w)] else NA_character_
  }, character(1L))
  infra_ranks <- c("subspecies", "variety", "varietas", "forma", "form")
  infra[!rank_lower %in% infra_ranks] <- NA_character_

  # Accepted name usage ID
  acc_id <- as.character(df$acceptedNameUsageID)

  data.frame(
    taxon_id                = id,
    canonical_name          = canonical,
    taxon_rank              = rank,
    taxonomic_status        = status,
    accepted_name_usage_id  = acc_id,
    family                  = trimws(family),
    genus                   = trimws(genus),
    specific_epithet        = trimws(epithet),
    authorship              = trimws(auth),
    infraspecific_epithet   = trimws(infra),
    stringsAsFactors        = FALSE
  )
}


#' @exportS3Method
taxify_load.taxify_algaebase <- function(backend, path = NULL, ...) {
  path <- path %||% file.path(taxify_data_dir(), "algaebase.vtr")
  if (!file.exists(path)) {
    stop(sprintf(
      "AlgaeBase backbone not found at: %s\nRun taxify_download('algaebase') first.",
      path
    ), call. = FALSE)
  }
  path
}


# ------------------------------------------------------------------
# Matching — delegates to shared compiled engine
# ------------------------------------------------------------------

#' @exportS3Method
match_exact.taxify_algaebase <- function(backend, names_df, backbone, ...) {
  bb_path <- backbone
  n <- nrow(names_df)
  result <- empty_match_result(n)
  result$input_name <- names_df$original
  result$is_hybrid  <- names_df$is_hybrid

  match_exact_compiled(result, names_df, bb_path, .algaebase_col_map)
}


#' @exportS3Method
match_fuzzy.taxify_algaebase <- function(backend, unmatched_df, backbone,
                                         method = "dl", threshold = 0.2,
                                         names_df = NULL, ...) {
  bb_path <- backbone
  result  <- unmatched_df

  if (method == "jw" && threshold >= 1) {
    stop("fuzzy_threshold must be < 1 for fuzzy_method = 'jw'")
  }

  fuzzy_match_via_join(result, names_df, bb_path, method, threshold,
                       .algaebase_col_map)
}

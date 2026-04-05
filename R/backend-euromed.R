# ---- Euro+Med PlantBase backend ----
#
# Offline matching against Euro+Med PlantBase, the taxonomic reference for
# European and Mediterranean vascular plants (~133k taxa). Used by EVA
# (European Vegetation Archive).
#
# Source: semicolon-delimited CSV, UUID-based IDs, 2020 v1.2 snapshot.
# License: CC-BY-SA-3.0 (applies to derived .vtr data file).
#
# Euro+Med strengths: authoritative for European/Mediterranean flora,
# fine-grained infraspecific taxonomy (subspecies, varieties, forms).

# Euro+Med source URL and version
.euromed_url <- "https://germansl.infinitenature.org/EuroMed/version1/EuroMed.zip"
.euromed_version <- "2020.1"

# Column map for shared matching engine
# These map to the unified backbone schema produced by taxify-backbones
.euromed_col_map <- list(
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


#' Create a Euro+Med backend object
#'
#' @return A taxify_backend object of class `"taxify_euromed"`.
#' @noRd
euromed_backend <- function() {
  new_backend(
    name = "euromed",
    version = .euromed_version,
    genus_col = "genus",
    col_map = .euromed_col_map,
    class = "taxify_euromed"
  )
}


#' @export
taxify_download.taxify_euromed <- function(backend, dest = NULL,
                                           verbose = TRUE, ...) {
  dest <- dest %||% versioned_dir("euromed", "latest")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)

  vtr_path <- file.path(dest, "euromed.vtr")
  zip_path <- file.path(dest, "EuroMed.zip")

  # Download
  if (verbose) message("Downloading Euro+Med PlantBase (~8 MB)...")
  curl::curl_download(.euromed_url, zip_path, quiet = !verbose)

  if (verbose) message("Extracting...")
  utils::unzip(zip_path, exdir = dest)

  # Find CSV
  csv_files <- list.files(dest, pattern = "\\.csv$",
                          recursive = TRUE, full.names = TRUE)
  if (length(csv_files) == 0L) {
    stop("No .csv file found in Euro+Med download.", call. = FALSE)
  }
  csv_path <- csv_files[1L]

  # Convert CSV to normalized data.frame
  if (verbose) message("Converting Euro+Med database...")
  df <- euromed_csv_to_df(csv_path, verbose = verbose)

  # Compile and write
  compile_backbone(df, vtr_path, backend, .euromed_url, verbose = verbose)

  # Clean up
  unlink(zip_path)
  unlink(csv_path)
}


#' Convert Euro+Med CSV to a normalized data.frame
#'
#' Reads the semicolon-delimited CSV, resolves the parent-child hierarchy
#' for family/genus, maps synonym relationships via TaxonConceptID, and
#' produces the unified backbone schema.
#'
#' @param csv_path Character. Path to the EuroMed.csv file.
#' @param verbose Logical.
#' @return A normalized data.frame (not yet precomputed -- no key_ci etc.).
#' @noRd
euromed_csv_to_df <- function(csv_path, verbose = TRUE) {

  # ---- Read CSV ----
  if (verbose) message("  Reading Euro+Med CSV...")
  df <- tryCatch(
    read.csv(csv_path, sep = ";", stringsAsFactors = FALSE, fileEncoding = "UTF-8"),
    error = function(e) {
      read.csv(csv_path, sep = ";", stringsAsFactors = FALSE, fileEncoding = "latin1")
    }
  )
  if (verbose) message(sprintf("    %s rows",
                               format(nrow(df), big.mark = ",")))

  # ---- Map status ----
  # Taxon -> ACCEPTED; Synonym, Misapplication, p.p. Synonym -> SYNONYM
  df$taxonomic_status <- ifelse(df$status == "Taxon", "ACCEPTED", "SYNONYM")

  # ---- Synonym resolution via TaxonConceptID ----
  # On synonym rows, TaxonConceptID = accepted row's TaxonUsageID
  df$accepted_name_usage_id <- ifelse(
    df$taxonomic_status == "SYNONYM",
    df$TaxonConceptID,
    NA_character_
  )

  # ---- Extract authorship ----
  # fullname = canonical + authorship. For infraspecific autonyms, the species
  # authorship is inserted mid-name, so TaxonName isn't a substring of fullname.
  infra_markers <- c("subsp.", "var.", "f.", "nothosubsp.", "subvar.", "convar.",
                     "proles", "race", "grex", "subf.")
  marker_re <- paste0("\\b(", paste(gsub("\\.", "\\\\.", infra_markers),
                                     collapse = "|"), ")\\s+\\S+")

  df$authorship <- vapply(seq_len(nrow(df)), function(i) {
    fn <- df$fullname[i]
    tn <- df$TaxonName[i]
    if (is.na(fn) || !nzchar(fn)) return(NA_character_)
    auth <- trimws(sub(tn, "", fn, fixed = TRUE))
    if (nzchar(auth) && auth != fn) return(auth)
    # Autonym: find last "subsp. epithet" in fullname, take trailing text
    m <- gregexpr(marker_re, fn, perl = TRUE)[[1L]]
    if (m[1L] == -1L) return(NA_character_)
    last_end <- m[length(m)] + attr(m, "match.length")[length(m)] - 1L
    trimws(substring(fn, last_end + 1L))
  }, character(1L))
  df$authorship[!nzchar(df$authorship)] <- NA_character_

  # ---- Parse epithets from TaxonName ----
  words <- strsplit(df$TaxonName, "\\s+")
  df$specific_epithet <- vapply(words, function(w) {
    if (length(w) >= 2L) w[2L] else NA_character_
  }, character(1L))

  rank_markers <- c("subsp.", "var.", "f.", "nothosubsp.", "subvar.", "convar.",
                     "proles", "race", "grex")
  df$infraspecific_epithet <- vapply(words, function(w) {
    if (length(w) < 3L) return(NA_character_)
    marker_pos <- which(w %in% rank_markers)
    if (length(marker_pos) > 0L && marker_pos[1L] < length(w)) {
      w[marker_pos[1L] + 1L]
    } else if (length(w) >= 3L) {
      w[3L]
    } else {
      NA_character_
    }
  }, character(1L))

  # ---- Hierarchy walk for family/genus ----
  if (verbose) message("  Walking hierarchy for family/genus...")

  # Only accepted rows have parent links (IsChildTaxonOfID)
  id <- df$TaxonUsageID
  parent_id <- ifelse(
    !is.na(df$IsChildTaxonOfID) & nzchar(df$IsChildTaxonOfID),
    df$IsChildTaxonOfID,
    NA_character_
  )
  rank_lower <- tolower(df$TaxonRank)

  parent_row <- match(parent_id, id)

  # Initialize
  family <- ifelse(rank_lower == "family", df$TaxonName, NA_character_)
  genus <- ifelse(rank_lower == "genus", df$TaxonName, NA_character_)

  # Walk up (max 20 hops)
  current_parent <- parent_row
  for (depth in seq_len(20L)) {
    needs_family <- is.na(family) & !is.na(current_parent)
    needs_genus <- is.na(genus) & !is.na(current_parent)

    if (!any(needs_family) && !any(needs_genus)) break

    if (any(needs_family)) {
      is_family <- rank_lower[current_parent[needs_family]] == "family"
      match_idx <- which(needs_family)[is_family]
      if (length(match_idx) > 0L) {
        family[match_idx] <- df$TaxonName[current_parent[match_idx]]
      }
    }

    if (any(needs_genus)) {
      is_genus <- rank_lower[current_parent[needs_genus]] == "genus"
      match_idx <- which(needs_genus)[is_genus]
      if (length(match_idx) > 0L) {
        genus[match_idx] <- df$TaxonName[current_parent[match_idx]]
      }
    }

    # Move up
    next_parent <- rep(NA_integer_, nrow(df))
    has_p <- !is.na(current_parent)
    next_parent[has_p] <- match(parent_id[current_parent[has_p]], id)
    current_parent <- next_parent
  }

  # For synonyms: inherit family/genus from their accepted taxon
  is_syn <- df$taxonomic_status == "SYNONYM" & !is.na(df$accepted_name_usage_id)
  acc_row <- match(df$accepted_name_usage_id[is_syn], id)
  has_acc <- !is.na(acc_row)
  syn_idx <- which(is_syn)[has_acc]
  acc_idx <- acc_row[has_acc]

  needs_fam <- is.na(family[syn_idx])
  if (any(needs_fam)) family[syn_idx[needs_fam]] <- family[acc_idx[needs_fam]]
  needs_gen <- is.na(genus[syn_idx])
  if (any(needs_gen)) genus[syn_idx[needs_gen]] <- genus[acc_idx[needs_gen]]

  # Fallback: parse genus from first word of TaxonName for species-rank rows
  # where hierarchy walk failed (e.g., Hieracium species whose parent chain
  # skips genus via Section/Tribe nodes)
  species_ranks <- c("species", "subspecies", "variety", "form",
                     "subvariety", "proles", "race", "grex")
  needs_genus <- is.na(genus) & rank_lower %in% species_ranks
  if (any(needs_genus)) {
    genus[needs_genus] <- sub(" .*", "", df$TaxonName[needs_genus])
  }

  # ---- Build output ----
  data.frame(
    taxon_id                = df$TaxonUsageID,
    canonical_name          = trimws(df$TaxonName),
    taxon_rank              = toupper(trimws(df$TaxonRank)),
    taxonomic_status        = df$taxonomic_status,
    accepted_name_usage_id  = df$accepted_name_usage_id,
    family                  = trimws(family),
    genus                   = trimws(genus),
    specific_epithet        = df$specific_epithet,
    authorship              = df$authorship,
    infraspecific_epithet   = df$infraspecific_epithet,
    stringsAsFactors        = FALSE
  )
}

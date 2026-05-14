# ---- AlgaeBase backend ----
#
# Offline matching against AlgaeBase algal taxonomy snapshots. Pre-built .vtr
# backbones are downloaded from GitHub Releases via the manifest.
# Build-from-source paginates the ChecklistBank /nameusage/search endpoint
# (dataset 304756) sliced by (status, rank) to stay within the 100,000-offset
# cap. The /archive endpoint is disabled for this dataset (CC BY-NC).
#
# AlgaeBase: curated algal taxonomy (~172k names). Authoritative for
# micro/macroalgae, cyanobacteria, and some protists.
#
# NOTE: AlgaeBase is licensed CC BY-NC. This means the backbone data may
# only be used for non-commercial purposes. Academic and research use is fine.

# ChecklistBank dataset 304756. The /nameusage/search endpoint embeds a full
# `classification[]` trail per record, so family/genus extraction is direct
# (no parent-id walk). The hard 100k offset cap means we slice by rank within
# the only oversized status (accepted, 122k); other statuses fit unsliced.
.algaebase_search_url <-
  "https://api.checklistbank.org/dataset/304756/nameusage/search"
.algaebase_url <- .algaebase_search_url   # for compile_backbone() provenance
.algaebase_version <- "2025.04"
.algaebase_page_size <- 1000L
.algaebase_offset_cap <- 100000L

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

  if (verbose) {
    message("NOTE: AlgaeBase is licensed CC BY-NC (non-commercial use only).")
    message("Fetching AlgaeBase from ChecklistBank /nameusage/search ...")
    message(sprintf("  Endpoint: %s", .algaebase_search_url))
  }

  records <- algaebase_fetch_all(verbose = verbose)
  if (verbose) {
    message(sprintf("  %s records fetched", format(length(records),
                                                    big.mark = ",")))
    message("Flattening JSON records to data.frame...")
  }
  df <- algaebase_records_to_df(records)

  if (verbose) message("Normalizing to unified schema...")
  df <- algaebase_normalize(df, verbose = verbose)

  compile_backbone(df, vtr_path, backend, .algaebase_search_url,
                   verbose = verbose)
}


#' Fetch all AlgaeBase records via /nameusage/search, sliced to fit the cap
#'
#' Strategy:
#'   * `synonym`, `bare name`, `provisionally accepted` statuses each fit
#'     under the 100k offset cap and are paginated as a single status slice.
#'   * `accepted` (~122k) exceeds the cap, so it is sub-sliced by rank.
#'   * Each (status[, rank]) slice paginates with limit=1000 until exhausted.
#'
#' @noRd
algaebase_fetch_all <- function(verbose = TRUE) {
  records <- list()

  # Statuses small enough to paginate without a rank slice
  for (st in c("synonym", "bare name", "provisionally accepted")) {
    rs <- algaebase_paginate(
      filters = list(status = st),
      label   = sprintf("status=%s", st),
      verbose = verbose
    )
    records <- c(records, rs)
  }

  # `accepted` (~122k) is over the 100k offset cap, so slice by rank
  ranks <- algaebase_facet_ranks(status = "accepted", verbose = verbose)
  for (rk in ranks) {
    rs <- algaebase_paginate(
      filters = list(status = "accepted", rank = rk),
      label   = sprintf("status=accepted&rank=%s", rk),
      verbose = verbose
    )
    records <- c(records, rs)
  }

  records
}


#' Discover the rank values present in a status slice via the search facet API
#'
#' `facetLimit=50` overrides the default of 10 — without it, the facet
#' silently truncates and tiny ranks like `unranked`, `subgenus`, `strain`
#' get dropped (~18 records lost across the whole dataset).
#'
#' @noRd
algaebase_facet_ranks <- function(status, verbose = TRUE) {
  url <- sprintf("%s?%s&limit=0&facet=rank&facetLimit=50&facetMinCount=1",
                 .algaebase_search_url,
                 algaebase_qs(list(status = status)))
  res <- jsonlite::fromJSON(url, simplifyVector = FALSE)
  facet <- res$facets$rank %||% list()
  ranks <- vapply(facet, function(f) f$value %||% NA_character_,
                  character(1L))
  ranks <- ranks[!is.na(ranks) & nzchar(ranks)]
  if (verbose) {
    message(sprintf("  status=%s spans %d ranks", status, length(ranks)))
  }
  ranks
}


#' Paginate one (status[, rank]) slice until exhausted
#'
#' Aborts with an informative error if a slice's `total` would force an
#' offset above the 100,000 ChecklistBank cap.
#' @noRd
algaebase_paginate <- function(filters, label, verbose = TRUE) {
  page_size <- .algaebase_page_size
  base_qs <- algaebase_qs(filters)

  fetch_offset <- function(offset) {
    url <- sprintf("%s?%s&limit=%d&offset=%d",
                   .algaebase_search_url, base_qs, page_size, offset)
    jsonlite::fromJSON(url, simplifyVector = FALSE)
  }

  first <- fetch_offset(0L)
  total <- first$total %||% 0L
  if (total == 0L) return(list())

  n_pages <- as.integer(ceiling(total / page_size))
  max_offset <- (n_pages - 1L) * page_size
  if (max_offset > .algaebase_offset_cap) {
    stop(sprintf(
      "Slice [%s] needs offset=%d which exceeds ChecklistBank's %d cap; refine filters",
      label, max_offset, .algaebase_offset_cap), call. = FALSE)
  }

  if (verbose) {
    message(sprintf("  [%s] %s records, %d page(s)",
                    label, format(total, big.mark = ","), n_pages))
  }

  pages <- vector("list", n_pages)
  pages[[1]] <- first$result
  for (i in seq_len(n_pages - 1L)) {
    pages[[i + 1L]] <- fetch_offset(i * page_size)$result
  }
  unlist(pages, recursive = FALSE)
}


# Build a URL-encoded query string from a named list of filters.
algaebase_qs <- function(filters) {
  paste(
    vapply(names(filters), function(k) {
      sprintf("%s=%s", k,
              utils::URLencode(as.character(filters[[k]]), reserved = TRUE))
    }, character(1L)),
    collapse = "&"
  )
}


# Pull a (possibly nested) field from each record; NA if path missing/empty.
.algaebase_pluck <- function(records, ...) {
  path <- c(...)
  vapply(records, function(r) {
    val <- r
    for (key in path) {
      if (is.null(val)) return(NA_character_)
      val <- val[[key]]
    }
    if (is.null(val) || length(val) == 0L) NA_character_ else as.character(val)
  }, character(1L))
}


# Pull family/genus directly from each record's classification[] trail.
.algaebase_pluck_classification_rank <- function(records, target_rank) {
  vapply(records, function(r) {
    cls <- r$classification
    if (is.null(cls) || length(cls) == 0L) return(NA_character_)
    for (entry in cls) {
      if (identical(entry$rank, target_rank)) {
        return(entry$name %||% NA_character_)
      }
    }
    NA_character_
  }, character(1L))
}


#' Flatten /nameusage/search records into a wide data.frame
#'
#' Each record has top-level `id`, a nested `usage` with `name.{...}`,
#' `status`, `parentId`, optional `accepted.id`, plus `classification[]`.
#'
#' @noRd
algaebase_records_to_df <- function(records) {
  data.frame(
    taxon_id              = .algaebase_pluck(records, "usage", "id"),
    canonical_name        = .algaebase_pluck(records, "usage", "name",
                                             "scientificName"),
    taxon_rank_raw        = .algaebase_pluck(records, "usage", "name", "rank"),
    raw_status            = .algaebase_pluck(records, "usage", "status"),
    accepted_id           = .algaebase_pluck(records, "usage", "accepted",
                                             "id"),
    name_genus            = .algaebase_pluck(records, "usage", "name",
                                             "genus"),
    cls_genus             = .algaebase_pluck_classification_rank(records,
                                                                  "genus"),
    cls_family            = .algaebase_pluck_classification_rank(records,
                                                                  "family"),
    specific_epithet      = .algaebase_pluck(records, "usage", "name",
                                             "specificEpithet"),
    authorship            = .algaebase_pluck(records, "usage", "name",
                                             "authorship"),
    infraspecific_epithet = .algaebase_pluck(records, "usage", "name",
                                             "infraspecificEpithet"),
    stringsAsFactors      = FALSE
  )
}


#' Normalize the flattened search frame to the unified taxify schema
#'
#' Family/genus come straight from the embedded classification trail; for
#' rows that ARE family or genus rank, the canonical name fills its own
#' classification field.
#'
#' @noRd
algaebase_normalize <- function(df, verbose = TRUE) {
  rank_lower <- tolower(df$taxon_rank_raw)
  status_lower <- tolower(df$raw_status)

  status <- ifelse(
    status_lower %in% c("accepted", "provisionally accepted"),
    "ACCEPTED", "SYNONYM"
  )
  is_synonym <- status == "SYNONYM"

  # accepted_name_usage_id is meaningful only for synonyms
  acc_id <- ifelse(is_synonym, df$accepted_id, NA_character_)

  family <- df$cls_family
  family[rank_lower == "family"] <- df$canonical_name[rank_lower == "family"]

  # Prefer the parsed name's `genus` field; fall back to classification trail.
  genus <- ifelse(is.na(df$name_genus) | !nzchar(df$name_genus),
                  df$cls_genus, df$name_genus)
  genus[rank_lower == "genus"] <- df$canonical_name[rank_lower == "genus"]

  species_ranks <- c("species", "subspecies", "variety", "varietas",
                     "form", "forma", "infraspecies",
                     "infraspecific name", "infrasubspecific name")
  no_genus <- is.na(genus) & rank_lower %in% species_ranks
  if (any(no_genus)) {
    genus[no_genus] <- sub(" .*", "", df$canonical_name[no_genus])
  }

  data.frame(
    taxon_id                = df$taxon_id,
    canonical_name          = trimws(df$canonical_name),
    taxon_rank              = toupper(df$taxon_rank_raw),
    taxonomic_status        = status,
    accepted_name_usage_id  = acc_id,
    family                  = trimws(family),
    genus                   = trimws(genus),
    specific_epithet        = trimws(df$specific_epithet),
    authorship              = trimws(df$authorship),
    infraspecific_epithet   = trimws(df$infraspecific_epithet),
    stringsAsFactors        = FALSE
  )
}

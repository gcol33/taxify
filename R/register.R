# ---- Unified genus register ----
#
# Cross-backend genus-level index. Built from the union of WFO, COL, and GBIF
# genera. Stored in taxify_data_dir()/unified/latest/ as two .vtr files:
#
#   genus_register.vtr   — one row per genus, with classification + life_form
#   backend_coverage.vtr — long format: one row per (genus x backend)
#
# Design: small enough to cache in memory (~100k rows). Loaded into
# .taxify_env$register on first access.


# ---- Path helpers ----

#' Path to the unified register directory
#' @noRd
register_dir <- function() {
  file.path(taxify_data_dir(), "unified", "latest")
}

#' Path to genus_register.vtr
#' @noRd
register_vtr_path <- function() {
  file.path(register_dir(), "genus_register.vtr")
}

#' Path to backend_coverage.vtr
#' @noRd
coverage_vtr_path <- function() {
  file.path(register_dir(), "backend_coverage.vtr")
}


# ---- Backbone genus extraction ----

#' Extract genus rows from WFO backbone
#'
#' @param bb_path Character. Path to WFO .vtr file.
#' @return data.frame with columns: genus, kingdom, phylum, class, order,
#'   family (kingdom/phylum/class/order are NA for WFO — not stored in backbone).
#' @noRd
extract_wfo_genera <- function(bb_path) {
  df <- vectra::tbl(bb_path) |>
    vectra::filter(taxonRank == "GENUS") |>
    vectra::select(scientificName, family, genus) |>
    vectra::collect()

  if (nrow(df) == 0L) return(empty_genus_df())

  data.frame(
    genus   = df$scientificName,
    kingdom = NA_character_,
    phylum  = NA_character_,
    class   = NA_character_,
    order   = NA_character_,
    family  = df$family,
    stringsAsFactors = FALSE
  )
}


#' Extract genus rows from COL backbone
#'
#' COL stores kingdom/phylum/class/order as direct columns.
#'
#' @param bb_path Character. Path to COL .vtr file.
#' @return data.frame with columns: genus, kingdom, phylum, class, order, family.
#' @noRd
extract_col_genera <- function(bb_path) {
  # Collect genus rows — vectra select() uses bare names; collect all columns
  # then subset in R to handle the optionally-present higher-classification cols.
  df <- vectra::tbl(bb_path) |>
    vectra::filter(taxonRank == "GENUS") |>
    vectra::collect()

  if (nrow(df) == 0L) return(empty_genus_df())

  result <- data.frame(
    genus  = df$canonicalName,
    family = df$family,
    stringsAsFactors = FALSE
  )
  for (col in c("kingdom", "phylum", "class", "order")) {
    result[[col]] <- if (col %in% names(df)) df[[col]] else NA_character_
  }
  result[, c("genus", "kingdom", "phylum", "class", "order", "family"),
         drop = FALSE]
}


#' Extract genus rows from GBIF backbone
#'
#' GBIF backbone stores kingdom/phylum/class/order as separate taxonomy keys
#' that are not present in the converted .vtr. We do have `genus_or_above` and
#' `family`. Higher classification columns are absent; they need to be provided
#' via the GBIF hierarchy.
#'
#' Strategy: GBIF simple.txt does not carry kingdom/class text in genus rows
#' directly. We use what is available — family — and leave higher columns NA.
#' The conflict-resolution step will fill in COL/WFO classification for
#' genera shared across backends.
#'
#' @param bb_path Character. Path to GBIF .vtr file.
#' @return data.frame with columns: genus, kingdom, phylum, class, order, family.
#' @noRd
extract_gbif_genera <- function(bb_path) {
  df <- vectra::tbl(bb_path) |>
    vectra::filter(rank == "GENUS") |>
    vectra::select(canonical_name, family, genus_or_above) |>
    vectra::collect()

  if (nrow(df) == 0L) return(empty_genus_df())

  data.frame(
    genus   = df$canonical_name,
    kingdom = NA_character_,
    phylum  = NA_character_,
    class   = NA_character_,
    order   = NA_character_,
    family  = df$family,
    stringsAsFactors = FALSE
  )
}


#' Empty genus data.frame (zero rows, correct schema)
#' @noRd
empty_genus_df <- function() {
  data.frame(
    genus   = character(0L),
    kingdom = character(0L),
    phylum  = character(0L),
    class   = character(0L),
    order   = character(0L),
    family  = character(0L),
    stringsAsFactors = FALSE
  )
}


# ---- Classification conflict resolution ----

#' Resolve classification conflicts across backends
#'
#' Merges genera from multiple backends, preferring COL > GBIF > WFO for
#' each classification column. When the same genus appears in multiple
#' backends, the first non-NA value in priority order is used.
#'
#' @param genera_list Named list of data.frames, each with columns
#'   genus, kingdom, phylum, class, order, family.
#'   Names should be backend identifiers (e.g., "col", "gbif", "wfo").
#' @return data.frame with deduplicated genera and resolved classification.
#' @noRd
resolve_genus_classification <- function(genera_list) {
  priority <- c("col", "gbif", "wfo")

  # Combine all genera, tagging each with its source backend
  all_rows <- lapply(priority, function(be) {
    df <- genera_list[[be]]
    if (is.null(df) || nrow(df) == 0L) return(NULL)
    df$source_backend <- be
    df
  })
  all_rows <- Filter(Negate(is.null), all_rows)
  if (length(all_rows) == 0L) return(empty_genus_df())

  combined <- do.call(rbind, all_rows)

  # For each unique genus, pick the best row using priority order
  # Priority is encoded in source_backend already (list is in priority order)
  genera_unique <- unique(combined$genus)
  genera_unique <- genera_unique[!is.na(genera_unique) & nzchar(genera_unique)]

  # Vectorized approach: split by genus, resolve column by column
  # For each classification column, first non-NA value in priority order wins
  resolve_col <- function(genus_subset, col) {
    val <- genus_subset[[col]]
    first_non_na <- val[!is.na(val) & nzchar(val)]
    if (length(first_non_na) == 0L) NA_character_ else first_non_na[1L]
  }

  # Order combined so priority order (col < gbif < wfo) is preserved
  combined$priority_rank <- match(combined$source_backend, priority)
  combined <- combined[order(combined$genus, combined$priority_rank), ]

  result_rows <- lapply(split(combined, combined$genus), function(sub) {
    data.frame(
      genus   = sub$genus[1L],
      kingdom = resolve_col(sub, "kingdom"),
      phylum  = resolve_col(sub, "phylum"),
      class   = resolve_col(sub, "class"),
      order   = resolve_col(sub, "order"),
      family  = resolve_col(sub, "family"),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, result_rows)
}


# ---- Build functions (maintainer-facing, unexported) ----

#' Resolve unknown genera to kingdom_group via GBIF parent_key traversal
#'
#' For genera where taxon_group is "unknown", walks the GBIF backbone
#' parent_key chain upward until a KINGDOM-rank row is found, then maps
#' the kingdom name to kingdom_group and taxon_group.
#'
#' This runs only during build_genus_register() — one-time build cost.
#'
#' @param unknown_genera Character vector of genus names with unknown classification.
#' @param resolved data.frame with genus/kingdom_group/taxon_group columns
#'   (modified in-place via environment — returns updated resolved).
#' @param gbif_path Character. Path to GBIF .vtr file.
#' @return Updated resolved data.frame.
#' @noRd
resolve_kingdom_via_gbif <- function(resolved, gbif_path) {
  if (!file.exists(gbif_path)) return(resolved)

  unknown_idx <- which(resolved$taxon_group == "unknown" |
                       resolved$kingdom_group == "unknown")
  if (length(unknown_idx) == 0L) return(resolved)

  unknown_genera <- resolved$genus[unknown_idx]
  if (length(unknown_genera) == 0L) return(resolved)

  # Load the GBIF backbone columns needed for traversal
  # id, parent_key, rank, canonical_name — subset to minimize memory
  if (is.null(.taxify_env$gbif_hierarchy_cache)) {
    gbif_df <- tryCatch({
      vectra::tbl(gbif_path) |>
        vectra::select(id, parent_key, rank, canonical_name) |>
        vectra::collect()
    }, error = function(e) NULL)
    if (is.null(gbif_df) || nrow(gbif_df) == 0L) return(resolved)
    .taxify_env$gbif_hierarchy_cache <- gbif_df
  } else {
    gbif_df <- .taxify_env$gbif_hierarchy_cache
  }

  # Build hash maps for fast traversal
  id_to_parent   <- stats::setNames(gbif_df$parent_key,    gbif_df$id)
  id_to_rank     <- stats::setNames(gbif_df$rank,          gbif_df$id)
  id_to_canonical <- stats::setNames(gbif_df$canonical_name, gbif_df$id)

  # Kingdom name → kingdom_group mapping
  kingdom_group_map <- c(
    "Plantae"   = "plantae",
    "Fungi"     = "fungi",
    "Animalia"  = "animalia",
    "Chromista" = "chromista",
    "Protozoa"  = "protozoa",
    "Bacteria"  = "bacteria",
    "Archaea"   = "archaea",
    "Viruses"   = "viruses"
  )
  kingdom_taxon_map <- c(
    "Plantae"   = "unknown",
    "Fungi"     = "fungus",
    "Animalia"  = "animal",
    "Chromista" = "unknown",
    "Protozoa"  = "unknown",
    "Bacteria"  = "unknown",
    "Archaea"   = "unknown",
    "Viruses"   = "unknown"
  )

  # Vectorized parent_key traversal — repeated joins instead of a per-genus loop.
  # Start: match each unknown genus name to its GBIF id.
  genus_rows <- gbif_df[!is.na(gbif_df$rank) & gbif_df$rank == "GENUS" &
                          gbif_df$canonical_name %in% unknown_genera, ,
                        drop = FALSE]

  if (nrow(genus_rows) == 0L) return(resolved)

  # working table: genus_name | current_id | kingdom_name (NA until resolved)
  work <- data.frame(
    genus_name   = genus_rows$canonical_name,
    current_id   = genus_rows$id,
    kingdom_name = NA_character_,
    stringsAsFactors = FALSE
  )
  # deduplicate: one row per genus (take first GBIF hit)
  work <- work[!duplicated(work$genus_name), , drop = FALSE]

  # pre-build lookup vectors once
  id_to_parent    <- stats::setNames(gbif_df$parent_key,    gbif_df$id)
  id_to_rank      <- stats::setNames(gbif_df$rank,          gbif_df$id)
  id_to_canonical <- stats::setNames(gbif_df$canonical_name, gbif_df$id)

  # iteratively hop to parent until all rows hit KINGDOM or exhaust depth
  for (step in seq_len(20L)) {
    pending <- is.na(work$kingdom_name)
    if (!any(pending)) break

    cur_ids  <- work$current_id[pending]
    cur_rank <- id_to_rank[cur_ids]

    # rows that reached KINGDOM this step
    at_kingdom <- !is.na(cur_rank) & cur_rank == "KINGDOM"
    if (any(at_kingdom)) {
      idx <- which(pending)[at_kingdom]
      work$kingdom_name[idx] <- id_to_canonical[work$current_id[idx]]
    }

    # rows still pending: hop to parent
    still_pending <- pending & is.na(work$kingdom_name)
    if (!any(still_pending)) break
    parents <- id_to_parent[work$current_id[still_pending]]
    # stop rows that hit NA parent or self-loop
    dead <- is.na(parents) | parents == work$current_id[still_pending]
    if (any(dead)) work$kingdom_name[which(still_pending)[dead]] <- "unknown_stop"
    work$current_id[still_pending] <- parents
  }

  # map kingdom names to kingdom_group / taxon_group
  kg_vec <- kingdom_group_map[work$kingdom_name]
  tg_vec <- kingdom_taxon_map[work$kingdom_name]
  kg_vec[is.na(kg_vec)] <- "unknown"
  tg_vec[is.na(tg_vec)] <- "unknown"

  # apply to resolved data.frame via match (vectorized)
  m <- match(resolved$genus[unknown_idx], work$genus_name)
  hit <- !is.na(m)
  if (any(hit)) {
    update_idx <- unknown_idx[hit]
    resolved$kingdom_group[update_idx] <- unname(kg_vec[m[hit]])
    resolved$taxon_group[update_idx]   <- unname(tg_vec[m[hit]])
    resolved$life_form[update_idx]     <-
      gsub("_", " ", unname(tg_vec[m[hit]]), fixed = TRUE)
  }

  resolved
}


#' Build the genus register from installed backbones
#'
#' Reads genus-rank rows from each installed backbone, unions them, resolves
#' classification conflicts (COL > GBIF > WFO), assigns kingdom_group,
#' taxon_group, and life_form, and writes `genus_register.vtr` to
#' `taxify_data_dir()/unified/latest/`.
#'
#' Only processes backbones that are actually installed (i.e., their .vtr
#' exists on disk). Silently skips missing backbones.
#'
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return Path to `genus_register.vtr` (invisibly).
#' @noRd
build_genus_register <- function(verbose = TRUE) {
  dir.create(register_dir(), recursive = TRUE, showWarnings = FALSE)

  backends <- list(
    wfo  = list(be = wfo_backend(),  extract_fn = extract_wfo_genera),
    col  = list(be = col_backend(),  extract_fn = extract_col_genera),
    gbif = list(be = gbif_backend(), extract_fn = extract_gbif_genera)
  )

  genera_list <- list()
  gbif_path   <- NULL

  for (be_name in names(backends)) {
    be   <- backends[[be_name]]$be
    path <- tryCatch(ensure_backbone(be, verbose = FALSE),
                     error = function(e) NULL)
    if (is.null(path) || !file.exists(path)) {
      if (verbose) message(sprintf("  [%s] Not installed, skipping.", be_name))
      next
    }
    if (be_name == "gbif") gbif_path <- path
    if (verbose) message(sprintf("  [%s] Extracting genus rows...", be_name))
    genera_list[[be_name]] <- backends[[be_name]]$extract_fn(path)
    if (verbose) {
      message(sprintf("  [%s] %d genera found.", be_name,
                      nrow(genera_list[[be_name]])))
    }
  }

  if (length(genera_list) == 0L) {
    stop("No installed backbones found. Run taxify_download() for at least one backend.",
         call. = FALSE)
  }

  if (verbose) message("Resolving classification conflicts (COL > GBIF > WFO)...")
  resolved <- resolve_genus_classification(genera_list)

  if (verbose) message("Assigning life forms...")
  lf <- assign_life_form(resolved$family, resolved$kingdom)
  resolved$kingdom_group <- lf$kingdom_group
  resolved$taxon_group   <- lf$taxon_group
  resolved$life_form     <- lf$life_form

  # Second pass: use GBIF parent_key traversal to resolve remaining unknowns
  n_unknown_before <- sum(resolved$taxon_group == "unknown", na.rm = TRUE)
  if (n_unknown_before > 0L && !is.null(gbif_path)) {
    if (verbose) message(sprintf(
      "  Resolving %d unknown genera via GBIF hierarchy...", n_unknown_before
    ))
    resolved <- resolve_kingdom_via_gbif(resolved, gbif_path)
    n_unknown_after <- sum(resolved$taxon_group == "unknown", na.rm = TRUE)
    if (verbose) message(sprintf(
      "  %d resolved; %d still unknown.",
      n_unknown_before - n_unknown_after, n_unknown_after
    ))
  }

  # Reorder columns
  resolved <- resolved[, c("genus", "kingdom", "phylum", "class", "order",
                            "family", "kingdom_group", "taxon_group",
                            "life_form"), drop = FALSE]
  resolved <- resolved[order(resolved$genus), , drop = FALSE]
  rownames(resolved) <- NULL

  out_path <- register_vtr_path()
  vectra::write_vtr(resolved, out_path)

  # Write meta.json so use_local_manifest() can read the version.
  # Version is derived from the most recent backend version used.
  register_version <- format(Sys.Date(), "%Y.%m")
  write_version_meta(register_dir(), "register", register_version,
                     pinned = FALSE)

  if (verbose) {
    message(sprintf("Genus register written: %s (%d genera)", out_path,
                    nrow(resolved)))
  }
  invisible(out_path)
}


#' Build the backend coverage table
#'
#' For each installed backend, extracts the genus list and writes a long-format
#' `backend_coverage.vtr` recording which genera are covered by which backend
#' and at what version/date.
#'
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return Path to `backend_coverage.vtr` (invisibly).
#' @noRd
build_backend_coverage <- function(verbose = TRUE) {
  dir.create(register_dir(), recursive = TRUE, showWarnings = FALSE)

  backends <- list(
    wfo  = list(be = wfo_backend(),  extract_fn = extract_wfo_genera),
    col  = list(be = col_backend(),  extract_fn = extract_col_genera),
    gbif = list(be = gbif_backend(), extract_fn = extract_gbif_genera)
  )

  coverage_rows <- list()

  for (be_name in names(backends)) {
    be   <- backends[[be_name]]$be
    path <- tryCatch(ensure_backbone(be, verbose = FALSE),
                     error = function(e) NULL)
    if (is.null(path) || !file.exists(path)) {
      if (verbose) message(sprintf("  [%s] Not installed, skipping.", be_name))
      next
    }

    meta <- read_backbone_meta(path)
    version    <- if (!is.null(meta$version))       meta$version       else be$version
    date_added <- if (!is.null(meta$download_date)) meta$download_date else NA_character_

    if (verbose) message(sprintf("  [%s] Building coverage (v%s)...",
                                 be_name, version))
    genera_df <- backends[[be_name]]$extract_fn(path)
    genera <- unique(genera_df$genus)
    genera <- genera[!is.na(genera) & nzchar(genera)]

    if (length(genera) == 0L) next

    coverage_rows[[be_name]] <- data.frame(
      genus      = genera,
      backend    = be_name,
      version    = version,
      date_added = date_added,
      stringsAsFactors = FALSE
    )
    if (verbose) message(sprintf("  [%s] %d genera.", be_name, length(genera)))
  }

  if (length(coverage_rows) == 0L) {
    stop("No installed backbones found.", call. = FALSE)
  }

  coverage <- do.call(rbind, coverage_rows)
  coverage <- coverage[order(coverage$genus, coverage$backend), , drop = FALSE]
  rownames(coverage) <- NULL

  out_path <- coverage_vtr_path()
  vectra::write_vtr(coverage, out_path)

  if (verbose) {
    message(sprintf("Backend coverage written: %s (%d rows)",
                    out_path, nrow(coverage)))
  }
  invisible(out_path)
}


#' Build both genus register and backend coverage
#'
#' Convenience wrapper that calls `build_genus_register()` and
#' `build_backend_coverage()` in sequence.
#'
#' @param verbose Logical. Default `TRUE`.
#' @return Named list with paths to `genus_register.vtr` and
#'   `backend_coverage.vtr` (invisibly).
#' @noRd
build_unified_register <- function(verbose = TRUE) {
  if (verbose) message("=== Building genus register ===")
  reg_path <- build_genus_register(verbose = verbose)

  if (verbose) message("\n=== Building backend coverage ===")
  cov_path <- build_backend_coverage(verbose = verbose)

  invisible(list(register = reg_path, coverage = cov_path))
}


# ---- User-facing functions (exported) ----

#' Load the unified genus register into memory
#'
#' Reads `genus_register.vtr` from disk and caches it as a data.frame in
#' `.taxify_env$register`. Subsequent calls reuse the cached version unless
#' `force = TRUE`.
#'
#' The register contains one row per genus with columns: `genus`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `life_form`.
#'
#' @param force Logical. If `TRUE`, reloads from disk even if already cached.
#'   Default `FALSE`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return The register data.frame (invisibly).
#' @export
taxify_load_register <- function(force = FALSE, verbose = TRUE) {
  if (!force && !is.null(.taxify_env$register)) {
    return(invisible(.taxify_env$register))
  }

  path <- register_vtr_path()
  if (!file.exists(path)) {
    stop(sprintf(
      "Genus register not found at: %s\nRun build_unified_register() to build it.",
      path
    ), call. = FALSE)
  }

  if (verbose) message("Loading genus register from disk...")
  reg <- vectra::tbl(path) |> vectra::collect()
  .taxify_env$register <- reg

  if (verbose) message(sprintf("  %d genera loaded.", nrow(reg)))
  invisible(reg)
}


#' Look up a genus in the register
#'
#' Returns the register row for the given genus, or `NULL` if not found.
#' Auto-loads the register on first call.
#'
#' @param genus Character scalar. The genus name to look up.
#' @return A one-row data.frame, or `NULL` if the genus is not in the register.
#' @export
lookup_genus <- function(genus) {
  if (!is.character(genus) || length(genus) != 1L) {
    stop("genus must be a character scalar", call. = FALSE)
  }

  if (is.null(.taxify_env$register)) {
    taxify_load_register(verbose = FALSE)
  }

  reg <- .taxify_env$register
  hit <- reg[reg$genus == genus, , drop = FALSE]
  if (nrow(hit) == 0L) NULL else hit
}


#' Show backend coverage for a genus
#'
#' Queries `backend_coverage.vtr` to determine which backends contain the
#' given genus, along with the backbone version at time of indexing.
#'
#' @param genus Character scalar. The genus name to query.
#' @return A data.frame with columns `genus`, `backend`, `version`,
#'   `date_added`. Returns a zero-row data.frame if the genus is not found
#'   in any backend.
#' @export
taxify_register_coverage <- function(genus) {
  if (!is.character(genus) || length(genus) != 1L) {
    stop("genus must be a character scalar", call. = FALSE)
  }

  path <- coverage_vtr_path()
  if (!file.exists(path)) {
    stop(sprintf(
      "Backend coverage not found at: %s\nRun build_unified_register() to build it.",
      path
    ), call. = FALSE)
  }

  query_df <- data.frame(query_genus = genus, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(query_df, tmp)

  result <- vectra::inner_join(
    vectra::tbl(tmp),
    vectra::tbl(path),
    by = c("query_genus" = "genus")
  ) |> vectra::collect()

  if (nrow(result) == 0L) {
    return(data.frame(
      genus      = character(0L),
      backend    = character(0L),
      version    = character(0L),
      date_added = character(0L),
      stringsAsFactors = FALSE
    ))
  }

  result$genus <- result$query_genus
  result[, c("genus", "backend", "version", "date_added"), drop = FALSE]
}

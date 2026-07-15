# ---- Enrichment layer infrastructure ----
#
# Enrichment layers join external trait/status data to taxify results via
# accepted_name. The .vtr files are built by CI in taxifydb and
# distributed via GitHub Releases (same manifest system as matching backbones).
#
# Disk layout:
#   taxify_data_dir()/
#     enrichment/
#       conservation_status/
#         latest/conservation_status.vtr + meta.json
#       griis/
#         latest/griis.vtr + meta.json
#       ...


# ---- Path helpers ----

#' Enrichments taxify builds locally and never redistributes
#'
#' taxify only ships a pre-built `.vtr` for a source whose licence permits
#' redistribution. These sources do not qualify -- their terms are citation-only
#' or unstated -- so no asset is published, they carry no manifest entry, and no
#' version can be checked. Their doors reach them through taxifydb, which builds
#' the `.vtr` from the original source on the user's own machine. taxify
#' redistributes none of the data.
#'
#' ccdb has no door yet: its counts pool gametic and sporophytic records, so the
#' column taxifydb names chromosome_number_2n predominantly carries n. Blocked on
#' gcol33/taxifydb#12; the chromosome_number trait ships from kew_cvalues alone
#' until then.
#'
#' @return Character vector of enrichment identifiers.
#' @noRd
.build_only_enrichments <- function() {
  c("ccdb", "gmpd", "plantatt", "bryoatt", "clopla")
}


#' Return the versioned directory for an enrichment
#' @noRd
enrichment_dir <- function(name, version = "latest") {
  file.path(taxify_data_dir(), "enrichment", name, version)
}


#' Return the .vtr path for an enrichment
#' @noRd
enrichment_vtr_path <- function(name, version = "latest") {
  file.path(enrichment_dir(name, version), paste0(name, ".vtr"))
}


# ---- Enrichment metadata ----

#' Read meta.json from an enrichment directory
#'
#' @param vtr_path Character. Path to the enrichment `.vtr` file.
#' @return A named list with source, version, license, etc., or NULL.
#' @noRd
read_enrichment_meta <- function(vtr_path) {
  meta_path <- file.path(dirname(vtr_path), "meta.json")
  if (!file.exists(meta_path)) return(NULL)
  jsonlite::read_json(meta_path, simplifyVector = TRUE)
}


# ---- Version checking ----

#' Check whether a local enrichment version is current
#'
#' Compares the version in the local meta.json against the manifest.
#' Returns TRUE if an update is needed.
#'
#' @param name Character. Enrichment identifier.
#' @return Logical. TRUE means a newer version is available.
#' @noRd
# Content identity of a built .vtr: the md5 of the file, used to detect a
# same-tag republish (rebuilt asset re-uploaded under an unchanged release tag).
# tools::md5sum is base R, so this adds no dependency.
content_id_of <- function(vtr_path) {
  if (is.null(vtr_path) || !file.exists(vtr_path)) return(NA_character_)
  unname(tools::md5sum(vtr_path))
}

# Adopt a content id into an existing cache's meta.json (idempotent metadata
# upgrade for a legacy cache whose bytes already match the shipped asset), so
# later sessions compare the stored id instead of re-hashing the file. Works
# for enrichments and backbones alike -- both keep a meta.json beside the .vtr.
write_content_id_meta <- function(vtr_path, content_id) {
  meta_path <- file.path(dirname(vtr_path), "meta.json")
  meta <- if (file.exists(meta_path)) {
    tryCatch(jsonlite::read_json(meta_path, simplifyVector = TRUE),
             error = function(e) list())
  } else list()
  meta$content_id <- content_id
  tryCatch(
    jsonlite::write_json(meta, meta_path, pretty = TRUE, auto_unbox = TRUE),
    error = function(e) NULL
  )
  invisible(content_id)
}

# Shared refresh decision by content identity, used by both the enrichment and
# backbone version checks. Returns TRUE/FALSE, or NA when no content id is
# shipped (the caller then keeps its legacy behaviour). A legacy cache with no
# stored id is hashed in place when `hash_missing = TRUE` and, if its bytes
# already match the shipped id, the id is adopted via `adopt` so later sessions
# skip the hash. Backbones pass `hash_missing = FALSE` to avoid rehashing a
# multi-GB file: they compare only the id their downloaded meta already carries.
reconcile_content_id <- function(vtr_path, local_cid, bundled_cid,
                                 adopt = NULL, hash_missing = TRUE) {
  if (is.null(bundled_cid)) return(NA)
  if (is.null(local_cid)) {
    if (!isTRUE(hash_missing)) return(NA)
    local_cid <- content_id_of(vtr_path)
    if (identical(as.character(local_cid), as.character(bundled_cid)) &&
        !is.null(adopt)) {
      adopt(local_cid)
    }
  }
  !identical(as.character(local_cid), as.character(bundled_cid))
}

check_enrichment_version <- function(name) {
  # Never refresh against the read-only example database (offline fixtures).
  if (is_example_data_dir()) return(FALSE)

  # A build-only source publishes no asset and has no manifest entry, so there
  # is no version to compare against: the local build is the only copy.
  if (name %in% .build_only_enrichments()) return(FALSE)

  vtr_path <- enrichment_vtr_path(name)
  meta <- read_enrichment_meta(vtr_path)

  if (is.null(meta)) return(TRUE)  # No local copy

  # Static enrichments never phone home, but a same-tag republish would leave
  # the cache stale forever. Reconcile against the bundled manifest's content
  # id (a hash of the built .vtr) entirely offline: a package update ships a
  # changed content id for any rebuilt asset, which forces a one-time refresh.
  # A legacy cache with no stored id is hashed in place, so an unchanged asset
  # is adopted without any download. When the bundled manifest carries no
  # content id (older manifest), the historical "never update" behaviour holds.
  if (isTRUE(meta$static)) {
    # Only reconcile caches the runtime actually downloaded (downloaded_at is
    # written by download_enrichment). Bundled example data and staged test
    # mocks lack it and are deliberately left untouched -- they are subsets or
    # fixtures whose bytes intentionally differ from the released asset, and
    # must never be silently replaced by a full download.
    if (is.null(meta$downloaded_at)) return(FALSE)
    entry <- tryCatch(resolve_enrichment_entry(local_manifest(), name),
                      error = function(e) NULL)
    s <- reconcile_content_id(
      vtr_path, meta$content_id, entry$content_id,
      adopt = function(cid) write_content_id_meta(vtr_path, cid))
    return(if (is.na(s)) FALSE else s)
  }

  manifest <- fetch_manifest()
  entry <- resolve_enrichment_entry(manifest, name)
  if (is.null(entry)) return(FALSE)

  isTRUE(meta$version != entry$latest)
}


# ---- Ensure / download ----

#' Ensure an enrichment .vtr is available
#'
#' Resolution order:
#' 1. Once-per-session version check (download update if needed)
#' 2. Session cache
#' 3. On disk
#' 4. Download pre-built .vtr from manifest
#' 5. Build from source (if enrichment is in the build registry)
#' 6. Error with report link
#'
#' @param name Character. Enrichment identifier (e.g., "iucn").
#' @param verbose Logical.
#' @return Character. Path to the .vtr file, or NULL if all paths failed
#'   (only when called with `allow_null = TRUE` internally).
#' @noRd
ensure_enrichment <- function(name, verbose = TRUE) {
  cache_key <- paste0("enrichment_", name)

  # 1. Version freshness check (once per session)
  check_key <- paste0(".enrichment_version_checked.", name)
  if (!isTRUE(.taxify_env[[check_key]])) {
    .taxify_env[[check_key]] <- TRUE
    tryCatch(
      {
        if (check_enrichment_version(name)) {
          if (verbose) {
            message(sprintf(
              "Enrichment '%s' has a newer version. Updating...", name
            ))
          }
          download_enrichment(name, verbose = verbose)
          set_backbone_path(cache_key, NULL)
        }
      },
      error = function(e) {
        warning(
          sprintf(
            "Could not update enrichment '%s': %s\nUsing existing local version.",
            name, conditionMessage(e)
          ),
          call. = FALSE
        )
      }
    )
  }

  # 2. In-session cache
  cached <- get_backbone_path(cache_key)
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # 3. On disk
  vtr_path <- enrichment_vtr_path(name)
  if (file.exists(vtr_path)) {
    set_backbone_path(cache_key, vtr_path)
    return(vtr_path)
  }

  # 4. Download from manifest (a build-only source publishes no asset, so this
  #    step is skipped rather than attempted and swallowed).
  if (!name %in% .build_only_enrichments()) {
    path <- tryCatch(
      download_enrichment(name, verbose = verbose),
      error = function(e) NULL
    )
    if (!is.null(path) && file.exists(path)) {
      set_backbone_path(cache_key, path)
      return(path)
    }
  }

  # 5. Build from source via taxifydb (if installed)
  if (requireNamespace("taxifydb", quietly = TRUE)) {
    available <- tryCatch(taxifydb::list_enrichments(),
                          error = function(e) character(0L))
    if (name %in% available) {
      if (verbose) {
        message(sprintf(
          if (name %in% .build_only_enrichments()) {
            "Enrichment '%s' is not redistributed by taxify. Building it from the original source via taxifydb (one time)..."
          } else {
            "Pre-built .vtr not available for enrichment '%s'. Building from source via taxifydb..."
          },
          name
        ))
      }
      path <- tryCatch(
        taxifydb::build_enrichment(name,
                                   output_dir = enrichment_dir(name),
                                   verbose = verbose),
        error = function(e) {
          if (verbose) {
            message(sprintf(
              "Build-from-source failed for '%s': %s",
              name, conditionMessage(e)
            ))
          }
          NULL
        }
      )
      if (!is.null(path) && file.exists(path)) {
        set_backbone_path(cache_key, path)
        return(path)
      }
    }
  }

  # 6. Return NULL — caller (enrich_simple/enrich_by_group) handles
  #    emergency fallback or error
  NULL
}


#' Download an enrichment .vtr from the manifest
#'
#' @param name Character. Enrichment identifier.
#' @param version Character. "latest" or a specific version.
#' @param verbose Logical.
#' @return Path to the downloaded .vtr (invisibly).
#' @noRd
download_enrichment <- function(name, version = "latest", verbose = TRUE) {
  dest_dir <- enrichment_dir(name, version)
  vtr_path <- file.path(dest_dir, paste0(name, ".vtr"))

  # Pinned versions: never overwrite

  if (version != "latest" && file.exists(vtr_path)) {
    if (verbose) {
      message(sprintf(
        "\u2713 Enrichment '%s' v%s already present (pinned). Skipping.",
        name, version
      ))
    }
    return(invisible(vtr_path))
  }

  # Resolve from manifest
  manifest <- fetch_manifest()
  entry <- resolve_enrichment_entry(manifest, name)
  if (is.null(entry)) {
    stop(sprintf("Enrichment '%s' not found in manifest.", name),
         call. = FALSE)
  }

  actual_version <- if (version == "latest") entry$latest else version
  url <- entry$full_url %||% entry$url

  if (verbose) {
    message(sprintf(
      "\u2139 Downloading enrichment '%s' v%s...", name, actual_version
    ))
  }

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  tmp_path <- tempfile(tmpdir = dest_dir, fileext = ".vtr.tmp")
  on.exit(if (file.exists(tmp_path)) unlink(tmp_path), add = TRUE)

  tryCatch(
    {
      if (startsWith(url, "file://")) {
        local_src <- sub("^file:///", "/", url)
        if (.Platform$OS.type == "windows" &&
            grepl("^/[A-Za-z]:/", local_src)) {
          local_src <- sub("^/", "", local_src)
        }
        if (!file.exists(local_src)) {
          stop(sprintf("Local file not found: %s", local_src))
        }
        file.copy(local_src, tmp_path, overwrite = TRUE)
      } else {
        h <- curl::new_handle()
        curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
        curl::curl_download(url, tmp_path, handle = h, quiet = !verbose)
      }
    },
    error = function(e) {
      stop(sprintf(
        "Failed to download enrichment '%s' from:\n  %s\nError: %s",
        name, url, conditionMessage(e)
      ), call. = FALSE)
    }
  )

  file.rename(tmp_path, vtr_path)

  # Write meta.json. The content id is the md5 of the freshly downloaded file,
  # which matches the manifest's content_id and lets the static-cache gate
  # detect a future same-tag republish offline.
  meta <- list(
    version       = actual_version,
    static        = isTRUE(entry$static),
    pinned        = (version != "latest"),
    content_id    = content_id_of(vtr_path),
    downloaded_at = format(Sys.Date(), "%Y-%m-%d")
  )
  jsonlite::write_json(
    meta, file.path(dest_dir, "meta.json"),
    pretty = TRUE, auto_unbox = TRUE
  )

  if (verbose) {
    size_mb <- file.size(vtr_path) / 1048576
    message(sprintf(
      "\u2713 Enrichment '%s' ready (v%s, %.1f MB).",
      name, actual_version, size_mb
    ))
  }

  invisible(vtr_path)
}


#' Resolve an enrichment entry from the manifest
#'
#' Looks under `manifest$enrichments` (v2 schema) for the named enrichment.
#'
#' @param manifest The parsed manifest list.
#' @param name Character.
#' @return The entry list, or NULL.
#' @noRd
resolve_enrichment_entry <- function(manifest, name) {
  if (!is.null(manifest$enrichments)) {
    manifest$enrichments[[name]]
  } else {
    NULL
  }
}


#' Download one or more enrichment .vtr files
#'
#' Downloads pre-built enrichment `.vtr` files from the taxify manifest.
#'
#' @param enrichment Character. One or more enrichment names (e.g.,
#'   `"iucn"`, `"griis"`, `"zanne"`).
#' @param version Character. `"latest"` (default) or a specific version string.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#'
#' @details
#' Available enrichments:
#' \describe{
#'   \item{iucn}{IUCN conservation status (LC/NT/VU/EN/CR/EW/EX)}
#'   \item{griis}{GRIIS invasive species status by country}
#'   \item{zanne}{Zanne et al. 2014 woody/herbaceous classification}
#'   \item{wcvp}{WCVP native range by TDWG botanical region}
#'   \item{eive}{EIVE 1.0 ecological indicator values (European plants)}
#'   \item{diaz_traits}{Diaz et al. 2022 seed mass and plant height}
#'   \item{elton_traits}{EltonTraits 1.0 diet and foraging (birds + mammals)}
#'   \item{avonet}{AVONET bird morphology and migration}
#'   \item{pantheria}{PanTHERIA mammal life-history traits}
#'   \item{common_names}{GBIF vernacular names (multi-language)}
#'   \item{amphibio}{AmphiBIO amphibian life-history and ecological traits}
#'   \item{leda}{LEDA Traitbase NW European plant traits (Kleyer et al. 2008)}
#' }
#'
#' @export
taxify_download_enrichment <- function(enrichment,
                                       version = "latest",
                                       verbose = TRUE) {
  paths <- vapply(enrichment, function(name) {
    download_enrichment(name, version = version, verbose = verbose)
  }, character(1L))
  invisible(paths)
}


# ---- Shared enrichment join helpers ----


#' NA sentinel matching a column's storage type
#'
#' Returns the typed `NA` that keeps an output column the same type as its
#' source column, so a door never has to hand-declare `na_types`.
#'
#' @param v A prototype value (one element of the source column).
#' @return `NA_integer_`, `NA_real_`, `NA` (logical), or `NA_character_`.
#' @noRd
na_sentinel_for <- function(v) {
  if (is.integer(v)) NA_integer_
  else if (is.numeric(v)) NA_real_
  else if (is.logical(v)) NA
  else NA_character_
}


#' Build aggregate-aware candidate join keys for a species-level enrichment
#'
#' Encodes the trait-resolution rule for aggregates. A species query takes its
#' own name first, then the aggregate key (`"<binomial> aggr."`) as a downward
#' fallback -- a member inherits its aggregate's value. An aggregate query takes
#' the aggregate key first; when `binomial_fallback` is `TRUE` (the default) it
#' then falls *up* to the nominal binomial where the source carries no
#' aggregate-level value. That upward hit is the binomial's own trait standing
#' in for the aggregate, not a real aggregate-level measurement, and
#' `agg_select_idx()` records it as `basis = "binomial"`. With
#' `binomial_fallback = FALSE` an aggregate query stays unmatched when no
#' aggregate-level value exists. Aggregate markers are canonicalized so the keys
#' line up with enrichment sources regardless of spelling.
#'
#' @param acc Character vector of accepted names (the join column).
#' @param qualifier Character vector of canonical qualifiers from `taxify()`
#'   (`NA` when absent -- every row is then treated as a species query).
#' @param binomial_fallback Logical. When `TRUE`, an aggregate query with no
#'   aggregate-level value falls back to the nominal binomial's value.
#' @return A list with `primary`, `inherit`, and `is_agg` (logical) vectors,
#'   each the length of `acc`. For a species query `inherit` is the aggregate
#'   form; for an aggregate query it is the bare binomial (or `NA` when
#'   `binomial_fallback = FALSE`).
#' @noRd
agg_join_keys <- function(acc, qualifier, binomial_fallback = TRUE) {
  if (is.null(qualifier)) qualifier <- rep(NA_character_, length(acc))
  is_agg   <- !is.na(qualifier) & qualifier %in% .aggregate_tokens
  binom    <- strip_agg_marker(acc)
  agg_form <- ifelse(!is.na(binom), paste0(binom, " aggr."), NA_character_)
  agg_inherit <- if (isTRUE(binomial_fallback)) binom else NA_character_
  list(
    primary = ifelse(is_agg, agg_form, canon_agg_marker(acc)),
    inherit = ifelse(is_agg, agg_inherit, agg_form),
    is_agg  = is_agg
  )
}


#' Resolve aggregate-aware join keys against an enrichment key vector
#'
#' Picks the primary-key hit when present, else the inherited hit, and records
#' the basis of each filled value.
#'
#' @param keys List from `agg_join_keys()`.
#' @param enr_key Character vector of canonicalized enrichment lookup keys.
#' @return A list with `idx` (row index into `enr_key` per query row, `NA` for
#'   no match), `inherited` (logical; `TRUE` where the value came from an
#'   inherited key rather than a same-level hit), and `basis` (character:
#'   `"primary"` a same-level hit, `"aggregate"` a species inheriting its
#'   aggregate's value downward, `"binomial"` an aggregate falling back to the
#'   nominal binomial upward, `NA` no match).
#' @noRd
agg_select_idx <- function(keys, enr_key) {
  idx_p <- match(keys$primary, enr_key)
  idx_i <- match(keys$inherit, enr_key)
  inherited <- is.na(idx_p) & !is.na(idx_i)
  idx <- ifelse(!is.na(idx_p), idx_p, idx_i)
  is_agg <- keys$is_agg
  if (is.null(is_agg)) is_agg <- rep(FALSE, length(idx))
  basis <- rep(NA_character_, length(idx))
  basis[!is.na(idx_p)]       <- "primary"
  basis[inherited & !is_agg] <- "aggregate"
  basis[inherited &  is_agg] <- "binomial"
  list(idx = idx, inherited = inherited, basis = basis)
}


#' In-memory enrichment join from a data.frame (emergency fallback)
#'
#' Joins an in-memory data.frame (from `enrichment_emergency_fallback()`) to
#' a taxify result using `accepted_name == canonical_name`. Does NOT write to
#' disk — results are ephemeral.
#'
#' @param x A taxify_result data.frame.
#' @param df Data.frame with at least `canonical_name` plus trait columns.
#' @param enrichment_name Character. Enrichment identifier.
#' @param col_map Named character vector. Names = output columns,
#'   values = source columns in `df`.
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @return The enriched data.frame.
#' @noRd
enrich_from_dataframe <- function(x, df, enrichment_name, col_map,
                                  source_label, na_types = NULL,
                                  join_col = "accepted_name") {
  # Filter col_map to columns that exist in df
  col_map <- col_map[col_map %in% names(df)]
  if (length(col_map) == 0L) return(x)

  # Initialize output columns, typing each NA sentinel from its source column
  # (numeric -> NA_real_, else NA_character_) unless na_types overrides it.
  if (is.null(na_types)) na_types <- list()
  for (out_col in names(col_map)) {
    if (is.null(na_types[[out_col]])) {
      src <- col_map[[out_col]]
      na_types[[out_col]] <- if (src %in% names(df)) {
        na_sentinel_for(df[[src]])
      } else {
        NA_character_
      }
    }
    x[[out_col]] <- na_types[[out_col]]
  }

  # License lookup is delegated to taxifydb; emergency fallback leaves it unset.
  lic <- NA_character_

  # Determine the df-side join key: genus-level uses "genus", else canonical_name
  df_join_key <- if (join_col == "genus") "genus" else "canonical_name"

  valid_rows <- which(!is.na(x[[join_col]]))
  if (length(valid_rows) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  # Resolve a per-row index into df (aggregate-aware for species-level joins)
  if (join_col == "accepted_name") {
    keys    <- agg_join_keys(x[[join_col]], x[["qualifier"]],
                             binomial_fallback =
                               getOption("taxify.aggregate_trait_fallback", TRUE))
    enr_key <- canon_agg_marker(df[[df_join_key]])
    keep    <- !duplicated(enr_key)
    df      <- df[keep, , drop = FALSE]
    enr_key <- enr_key[keep]
    sel <- agg_select_idx(keys, enr_key)
    idx <- sel$idx
    if (isTRUE(getOption("taxify.trait_provenance", FALSE))) {
      x[[paste0(enrichment_name, "_basis")]] <- sel$basis
    }
  } else {
    df  <- df[!duplicated(df[[df_join_key]]), , drop = FALSE]
    idx <- match(x[[join_col]], df[[df_join_key]])
  }

  matched <- which(!is.na(idx))
  for (out_col in names(col_map)) {
    src_col <- col_map[[out_col]]
    if (src_col %in% names(df)) {
      x[[out_col]][matched] <- df[[src_col]][idx[matched]]
    }
  }

  n_enriched <- sum(
    rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, "emergency", n_enriched,
                      license = lic)
}


#' In-memory group-based enrichment join (emergency fallback)
#'
#' Group-based variant of `enrich_from_dataframe()` for enrichments that
#' filter/pivot by a grouping column (country, language, etc.).
#'
#' @param x A taxify_result data.frame.
#' @param df Data.frame with canonical_name, group_col, and value columns.
#' @param enrichment_name Character.
#' @param group_col Character. Column to filter/pivot on.
#' @param groups Character vector of group values.
#' @param value_cols Named character vector. Names = base output column names,
#'   values = source columns in df.
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @return The enriched data.frame.
#' @noRd
enrich_from_dataframe_grouped <- function(x, df, enrichment_name, group_col,
                                          groups, value_cols, source_label,
                                          na_types = NULL) {
  if (!group_col %in% names(df)) return(x)

  # License lookup is delegated to taxifydb; emergency fallback leaves it unset.
  lic <- NA_character_

  # Resolve "all" groups
  if (length(groups) == 1L && !anyNA(groups) && groups == "all") {
    groups <- sort(unique(df[[group_col]]))
    groups <- groups[!is.na(groups)]
  }

  # Build output column names, typing each NA sentinel from its source column
  # in df (unless na_types overrides it), then initialize per group.
  if (is.null(na_types)) na_types <- list()
  for (base_col in names(value_cols)) {
    if (is.null(na_types[[base_col]])) {
      src <- value_cols[[base_col]]
      na_types[[base_col]] <- if (src %in% names(df)) {
        na_sentinel_for(df[[src]])
      } else {
        NA_character_
      }
    }
  }
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      out_cols <- c(out_cols, out_col)
      x[[out_col]] <- na_types[[base_col]]
    }
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  # Filter to requested groups
  df <- df[df[[group_col]] %in% groups, , drop = FALSE]
  if (nrow(df) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  for (g in groups) {
    g_data <- df[df[[group_col]] == g, , drop = FALSE]
    if (nrow(g_data) == 0L) next
    g_data <- g_data[!duplicated(g_data$canonical_name), , drop = FALSE]
    idx <- match(x$accepted_name, g_data$canonical_name)
    matched <- which(!is.na(idx))
    if (length(matched) == 0L) next
    for (base_col in names(value_cols)) {
      src_col <- value_cols[[base_col]]
      if (!src_col %in% names(g_data)) next
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      x[[out_col]][matched] <- g_data[[src_col]][idx[matched]]
    }
  }

  n_enriched <- sum(
    rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
  )
  x <- register_enrichment(x, enrichment_name, source_label, "emergency",
                            n_enriched, license = lic)

  # Stamp reshape metadata so taxify_long() can auto-detect
  reshape_entry <- list(cols = names(value_cols), group_col = group_col)
  prev <- attr(x, "taxify_reshape") %||% list()
  attr(x, "taxify_reshape") <- c(prev, list(reshape_entry))

  x
}


#' Try emergency fallback for an enrichment
#'
#' Attempts to build the enrichment from source in memory. Returns the
#' data.frame on success, or stops with an informative error.
#'
#' @param name Character. Enrichment identifier.
#' @param download_error Character or NULL. The error that caused the fallback.
#' @param verbose Logical.
#' @return A data.frame with canonical_name + trait columns.
#' @noRd
try_emergency_fallback <- function(name, download_error = NULL, verbose = TRUE) {
  if (!requireNamespace("taxifydb", quietly = TRUE)) {
    if (name %in% .build_only_enrichments()) {
      stop(sprintf(
        paste0("Enrichment '%s' requires the 'taxifydb' package.\n",
               "  Its licence does not permit redistribution, so taxify ships no\n",
               "  pre-built copy: taxifydb builds it from the original source on\n",
               "  your own machine.\n",
               "  Install with: remotes::install_github(\"gcol33/taxifydb\")"),
        name
      ), call. = FALSE)
    }
    stop(sprintf(
      paste0("Enrichment '%s' is not available:\n",
             "  %s\n",
             "  Build-from-source requires the 'taxifydb' package.\n",
             "  Install with: remotes::install_github(\"gcol33/taxifydb\")\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      if (!is.null(download_error)) download_error else "download failed"
    ), call. = FALSE)
  }

  available <- tryCatch(taxifydb::list_enrichments(),
                        error = function(e) character(0L))
  if (!name %in% available) {
    stop(sprintf(
      paste0("Enrichment '%s' is not available:\n",
             "  %s\n",
             "  No build-from-source recipe available in taxifydb.\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      if (!is.null(download_error)) download_error else "download failed"
    ), call. = FALSE)
  }

  df <- tryCatch(
    taxifydb::enrichment_emergency_fallback(name, verbose = verbose),
    error = function(e) {
      stop(sprintf(
        paste0("Enrichment '%s' is not available.\n",
               "  Pre-built download: %s\n",
               "  Build-from-source: %s\n",
               "  Report issues: https://github.com/gcol33/taxify/issues"),
        name,
        if (!is.null(download_error)) download_error else "failed",
        conditionMessage(e)
      ), call. = FALSE)
    }
  )

  if (verbose) {
    warning(sprintf(
      paste0("[enrichment/%s] Using emergency in-memory fallback.\n",
             "  Rows: %s\n",
             "  Reason: %s\n",
             "  This is temporary and will not be cached to disk.\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      format(nrow(df), big.mark = ","),
      if (!is.null(download_error)) download_error else "pre-built .vtr unavailable"
    ), call. = FALSE, immediate. = TRUE)
  }

  df
}


#' Simple name-based enrichment join
#'
#' Joins an enrichment .vtr on `accepted_name == canonical_name`. Used by
#' enrichment functions that add columns without filtering (iucn,
#' zanne, indicator_values, etc.).
#'
#' @param x A taxify_result data.frame.
#' @param enrichment_name Character. Enrichment identifier for ensure/download.
#' @param col_map Named character vector. Names = output columns in x,
#'   values = source columns in .vtr.
#' @param source_label Character. Human-readable source for register_enrichment.
#' @param na_types Named list of NA sentinel values for output columns. Defaults
#'   to NA_character_ for all columns. Use NA_real_ for numeric columns, etc.
#' @param join_col Character. Column in `x` to join on. Default `"accepted_name"`
#'   for species-level enrichments. Use `"genus"` for genus-level enrichments.
#' @param genus_fallback Logical. For a mixed-resolution source keyed at both
#'   species and genus level, fill rows that found no species-level match from
#'   their genus-level row (species resolution still wins). Only applies when
#'   `join_col = "accepted_name"` and `x` has a `genus` column. Default `FALSE`.
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
# Read the attachable trait columns of an enrichment .vtr: every column bar the
# join keys, with its type ("numeric"/"character"). Optionally restrict to a
# name prefix. Returns data.frame(column, type), or NULL if the enrichment is
# unavailable (no download and no taxifydb to build it). Shared by add_gift(),
# the enrichment_cols() browse, and any door offering a cols= selector.
.enrichment_available_cols <- function(enrichment_name, prefix = NULL,
                                       verbose = TRUE) {
  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)
  if (is.null(vtr_path)) return(NULL)
  head1 <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  cols  <- setdiff(names(head1), c("canonical_name", "accepted_name", "genus"))
  if (!is.null(prefix)) cols <- grep(paste0("^", prefix), cols, value = TRUE)
  if (length(cols) == 0L) return(NULL)
  types <- vapply(cols, function(cc)
    if (is.numeric(head1[[cc]])) "numeric" else "character", character(1))
  data.frame(column = cols, type = unname(types), stringsAsFactors = FALSE)
}


# Resolve a user `cols` selection to a subset of `col_map` (names = the output
# columns a door attaches). NULL -> default_cols, or every column when no
# default; "all" -> every column; a character vector -> those columns, tolerant
# of a missing `prefix` (so gift's "plant_height_max" resolves to
# "gift_plant_height_max"). Errors with a browse pointer on unknown names.
.apply_col_selection <- function(col_map, cols, default_cols, prefix,
                                 enrichment_name) {
  out <- names(col_map)
  if (is.null(cols)) {
    sel <- if (is.null(default_cols)) out else intersect(default_cols, out)
    return(col_map[sel])
  }
  if (length(cols) == 1L && identical(tolower(cols), "all")) return(col_map)
  want <- as.character(cols)
  cand <- if (is.null(prefix)) want else
    ifelse(grepl(paste0("^", prefix), want), want, paste0(prefix, want))
  idx  <- match(tolower(cand), tolower(out))
  if (anyNA(idx)) {
    stop(sprintf(paste0(
      "add_%s(): unknown column(s): %s. Pass column names, \"all\", or NULL ",
      "for the default set. See enrichment_cols(\"%s\")."),
      enrichment_name, paste(want[is.na(idx)], collapse = ", "),
      enrichment_name), call. = FALSE)
  }
  col_map[out[idx]]
}


#' Browse the trait columns an enrichment door can attach
#'
#' Lists the columns available from an enrichment's pre-built `.vtr`, so you can
#' choose which to attach through the doors that accept a `cols` argument (such
#' as [add_gift()] and [add_floraweb()]). Read offline from the local `.vtr`;
#' the first call may trigger the one-time download.
#'
#' @param source Character. An enrichment name (see [list_enrichments()]).
#' @return A data.frame with one row per column: `column` (the name) and `type`
#'   (`"numeric"` or `"character"`).
#' @seealso [add_gift()], [add_floraweb()], [list_enrichments()]
#' @examples
#' \donttest{
#' old <- options(taxify.data_dir = taxify_example_data())
#' enrichment_cols("gift")
#' options(old)
#' }
#' @export
enrichment_cols <- function(source) {
  ac <- .enrichment_available_cols(source, verbose = FALSE)
  if (is.null(ac)) {
    stop(sprintf(paste0(
      "enrichment_cols(): enrichment '%s' is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      source), call. = FALSE)
  }
  ac
}


#' Browse the group values a grouped enrichment can filter on
#'
#' Some enrichment doors attach data per group: GRIIS invasive status by country
#' ([add_griis()]), WCVP native ranges by TDWG region ([add_wcvp()]), vernacular
#' names by language ([add_common_names()]), alien first records by country
#' ([add_alien_first_records()]). This lists the valid group values for such a
#' door, the way [enrichment_cols()] lists a door's columns, so a country,
#' region, or language code need not be guessed. Read offline from the local
#' `.vtr` metadata (falling back to the manifest, then a scan of the `.vtr`); the
#' first call may trigger the one-time download.
#'
#' @param source Character. A grouped enrichment name (see [list_enrichments()]).
#' @param verbose Logical. Print the group column and count. Default `TRUE`.
#' @return A character vector of the available group values, sorted. Stops with a
#'   pointer to [enrichment_cols()] when `source` is a flat (non-grouped)
#'   enrichment, which has no group values.
#' @seealso [enrichment_cols()], [list_enrichments()], [add_griis()],
#'   [add_wcvp()], [add_common_names()], [add_alien_first_records()]
#' @examples
#' \donttest{
#' old <- options(taxify.data_dir = taxify_example_data())
#' enrichment_groups("griis")   # ISO country codes GRIIS covers
#' options(old)
#' }
#' @export
enrichment_groups <- function(source, verbose = TRUE) {
  vtr_path <- ensure_enrichment(source, verbose = verbose)
  if (is.null(vtr_path)) {
    stop(sprintf(paste0(
      "enrichment_groups(): enrichment '%s' is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      source), call. = FALSE)
  }

  meta      <- read_enrichment_meta(vtr_path)
  group_col <- meta$group_col
  if (is.null(group_col) || length(group_col) == 0L ||
      is.na(group_col) || !nzchar(group_col)) {
    stop(sprintf(paste0(
      "enrichment_groups(): '%s' is not a grouped enrichment (no group ",
      "column). Use enrichment_cols(\"%s\") to see its columns."),
      source, source), call. = FALSE)
  }

  # Group values: local meta.json (O(1)) -> manifest -> distinct scan of the .vtr.
  groups <- meta$available_groups
  if (is.null(groups) || length(groups) == 0L) {
    manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)
    entry <- if (!is.null(manifest)) {
      resolve_enrichment_entry(manifest, source)
    } else {
      NULL
    }
    groups <- entry$available_groups
    if (is.null(groups) || length(groups) == 0L) {
      grp <- vectra::tbl(vtr_path) |>
        vectra::select(!!as.name(group_col)) |>
        vectra::distinct() |>
        vectra::collect()
      groups <- grp[[group_col]]
    }
  }

  groups <- sort(unique(as.character(groups[!is.na(groups)])))
  if (verbose) {
    message(sprintf("%s: %d group value(s) in column '%s'.",
                    source, length(groups), group_col))
  }
  groups
}


# Resolve a set of parent binomials to their accepted names against backend(s).
# Memoized per (backend, parent-set) within a session so a chain of add_trait
# sources over the same hybrids resolves the parents only once.
.resolve_parents_accepted <- function(parents, backend) {
  parents <- unique(parents[!is.na(parents) & nzchar(parents)])
  if (length(parents) == 0L) {
    return(stats::setNames(character(0L), character(0L)))
  }
  be_key <- paste(as.character(backend), collapse = "+")
  key    <- paste0(".pacc_", be_key, "_", paste(sort(parents), collapse = "|"))
  cached <- .taxify_env[[key]]
  if (!is.null(cached)) return(cached)
  pr  <- taxify(parents, backend = backend, verbose = FALSE)
  acc <- stats::setNames(pr$accepted_name, pr$input_name)
  .taxify_env[[key]] <- acc
  acc
}

# Look up a set of names in an enrichment .vtr, returning the joined rows.
.enrichment_vtr_lookup <- function(vtr_path, join_key, keys, src_cols) {
  keys <- unique(keys[!is.na(keys)])
  if (length(keys) == 0L) return(NULL)
  nd  <- data.frame(lookup_name = keys, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(nd, tmp)
  select_cols <- unique(c(join_key, src_cols))
  vectra::inner_join(
    vectra::tbl(tmp),
    vectra::tbl(vtr_path) |> vectra::select(!!!lapply(select_cols, as.name)),
    by = stats::setNames(join_key, "lookup_name")
  ) |> vectra::collect()
}

# Hybrid trait ladder: for a formula-hybrid row whose trait is still missing
# after the direct join, fill it from the two parents -- numeric averaged, a
# categorical taken as the shared value or "A x B" on disagreement (with a
# warning on the door path). When the parents were materialized as columns
# (add_hybrid_info) and the door exposes all columns, per-parent trait values
# are added as `<trait>_parent1` / `<trait>_parent2`.
.hybrid_trait_fallback <- function(x, col_map, join_key, vtr_path,
                                   expose_all = TRUE, verbose = TRUE) {
  if (!all(c("hybrid_type", "input_name") %in% names(x))) return(x)
  hf <- which(!is.na(x$hybrid_type) & x$hybrid_type == "formula")
  if (length(hf) == 0L) return(x)

  pf <- lapply(x$input_name[hf], parse_hybrid_formula)
  p1 <- vapply(pf, function(z) z$parent_1 %||% NA_character_, character(1L))
  p2 <- vapply(pf, function(z) z$parent_2 %||% NA_character_, character(1L))

  meta    <- attr(x, "taxify_meta")
  backend <- if (!is.null(meta$backend)) meta$backend else "wfo"
  acc <- .resolve_parents_accepted(c(p1, p2), backend)
  a1  <- unname(acc[p1]); a2 <- unname(acc[p2])

  lk <- .enrichment_vtr_lookup(vtr_path, join_key, c(a1, a2), unname(col_map))
  if (is.null(lk) || nrow(lk) == 0L) return(x)
  lk  <- lk[!duplicated(lk$lookup_name), , drop = FALSE]
  ix1 <- match(a1, lk$lookup_name)
  ix2 <- match(a2, lk$lookup_name)

  show_parents <- isTRUE(expose_all) && "hybrid_parent_1" %in% names(x)
  conflict <- character(0L)

  for (out_col in names(col_map)) {
    src <- col_map[[out_col]]
    if (!src %in% names(lk)) next
    v1 <- lk[[src]][ix1]
    v2 <- lk[[src]][ix2]
    numeric_col <- is.numeric(x[[out_col]])

    for (k in seq_along(hf)) {
      r <- hf[k]
      if (!is.na(x[[out_col]][r])) next            # a direct value wins
      w1 <- v1[k]; w2 <- v2[k]
      if (is.na(w1) && is.na(w2)) next
      if (is.na(w1)) {
        x[[out_col]][r] <- w2
      } else if (is.na(w2)) {
        x[[out_col]][r] <- w1
      } else if (numeric_col) {
        x[[out_col]][r] <- mean(c(w1, w2))
      } else if (identical(as.character(w1), as.character(w2))) {
        x[[out_col]][r] <- w1
      } else {
        x[[out_col]][r] <- paste(w1, "x", w2)
        conflict <- c(conflict, out_col)
      }
    }

    if (show_parents) {
      p1col <- paste0(out_col, "_parent1")
      p2col <- paste0(out_col, "_parent2")
      x[[p1col]] <- if (numeric_col) NA_real_ else NA_character_
      x[[p2col]] <- if (numeric_col) NA_real_ else NA_character_
      x[[p1col]][hf] <- v1
      x[[p2col]][hf] <- v2
    }
  }

  if (length(conflict) > 0L && isTRUE(expose_all)) {
    warning(sprintf(
      "Hybrid parents disagree on categorical trait(s): %s; combined as \"A x B\".",
      paste(unique(conflict), collapse = ", ")), call. = FALSE)
  }
  x
}


enrich_simple <- function(x, enrichment_name, col_map, source_label,
                          na_types = NULL, join_col = "accepted_name",
                          cols = NULL, default_cols = NULL, col_prefix = NULL,
                          out_prefix = NULL,
                          expose_all = TRUE, verbose = TRUE,
                          genus_fallback = FALSE,
                          aggregate_trait_fallback =
                            getOption("taxify.aggregate_trait_fallback", TRUE)) {
  if (!join_col %in% names(x)) {
    stop(sprintf("x must have a '%s' column (from taxify())", join_col),
         call. = FALSE)
  }

  # Expose every other column the .vtr carries (the sources were widened at
  # build time so no trait is dropped), while keeping the door's curated
  # col_map as the default output. One place makes all doors cols=-aware: the
  # default attaches the curated set, cols = "all" attaches everything, cols =
  # <names> picks any. Doors that manage selection themselves (default_cols
  # given, e.g. add_gift) opt out.
  if (isTRUE(expose_all) && is.null(default_cols)) {
    av <- tryCatch(.enrichment_available_cols(enrichment_name, verbose = FALSE),
                   error = function(e) NULL)
    if (!is.null(av)) {
      extra <- setdiff(av$column, unname(col_map))
      if (length(extra) > 0L) {
        default_cols <- names(col_map)               # curated output = default
        # Auto-exposed extras keep their raw .vtr names unless the door sets an
        # out_prefix (namespacing every exposed column, so two sibling sources
        # -- e.g. combine + combine_imputed -- never collide on a shared extra).
        raw_out <- if (is.null(out_prefix)) extra else paste0(out_prefix, extra)
        ex_out  <- make.unique(c(names(col_map), raw_out))[-seq_along(col_map)]
        col_map <- c(col_map, stats::setNames(extra, ex_out))
        if (is.null(na_types)) na_types <- list()
        et <- av$type[match(extra, av$column)]
        for (k in seq_along(ex_out)) {
          na_types[[ex_out[k]]] <-
            if (identical(et[k], "numeric")) NA_real_ else NA_character_
        }
      }
    }
  }

  # User column selection (only engaged when a door forwards cols/default_cols).
  if (!is.null(cols) || !is.null(default_cols)) {
    full_n  <- length(col_map)
    col_map <- .apply_col_selection(col_map, cols, default_cols, col_prefix,
                                    enrichment_name)
    if (is.null(cols) && !is.null(default_cols) && verbose &&
        length(col_map) < full_n &&
        is.null(.taxify_env[[paste0(".cols_notice.", enrichment_name)]])) {
      message(sprintf(paste0(
        "add_%s(): attaching %d of %d columns. Pass cols = \"all\" for all, ",
        "or see enrichment_cols(\"%s\")."),
        enrichment_name, length(col_map), full_n, enrichment_name))
      .taxify_env[[paste0(".cols_notice.", enrichment_name)]] <- TRUE
    }
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Emergency fallback: ensure_enrichment() returned NULL → all paths failed

  if (is.null(vtr_path)) {
    df <- try_emergency_fallback(enrichment_name, verbose = verbose)
    return(enrich_from_dataframe(x, df, enrichment_name, col_map,
                                 source_label, na_types,
                                 join_col = join_col))
  }

  # Read the .vtr schema once: it types the output columns and confirms which
  # source columns exist. NA sentinels are derived from the source column's type
  # (numeric -> NA_real_, else NA_character_), so a door never hand-declares
  # na_types; an explicit na_types entry still wins.
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  if (is.null(na_types)) na_types <- list()
  for (out_col in names(col_map)) {
    if (is.null(na_types[[out_col]])) {
      src <- col_map[[out_col]]
      na_types[[out_col]] <- if (src %in% names(schema)) {
        na_sentinel_for(schema[[src]])
      } else {
        NA_character_
      }
    }
    x[[out_col]] <- na_types[[out_col]]
  }

  valid_rows <- which(!is.na(x[[join_col]]))

  # A species-level join can still enrich a formula hybrid (accepted_name NA)
  # from its parents, so an empty valid_rows is not necessarily the end.
  has_formula <- join_col == "accepted_name" && "hybrid_type" %in% names(x) &&
    any(!is.na(x$hybrid_type) & x$hybrid_type == "formula")

  available_src <- intersect(unname(col_map), names(schema))
  if (length(available_src) == 0L ||
      (length(valid_rows) == 0L && !has_formula)) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Filter col_map to available columns
  col_map <- col_map[col_map %in% available_src]

  # Determine join key in enrichment .vtr
  # For genus-level enrichments, prefer the "genus" column when join_col is
  # "genus". Otherwise fall back to canonical_name / accepted_name.
  join_key <- if (join_col == "genus" && "genus" %in% names(schema)) {
    "genus"
  } else if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    stop(sprintf(
      "Enrichment '%s' .vtr has no joinable column (tried: %s, canonical_name, accepted_name).",
      enrichment_name, join_col
    ), call. = FALSE)
  }

  # Direct join (only when there are resolved rows to look up). Species-level
  # joins are aggregate-aware: an aggregate query reaches the aggregate trait
  # row, a species query inherits an aggregate-level trait when no species-level
  # one exists (downward), and -- when aggregate_trait_fallback is on -- an
  # aggregate query with no aggregate-level value falls back to the nominal
  # binomial (upward, recorded as basis = "binomial"). Genus-level joins keep
  # plain exact matching.
  if (length(valid_rows) > 0L) {
    agg_aware <- join_col == "accepted_name"
    if (agg_aware) {
      keys <- agg_join_keys(x[[join_col]], x[["qualifier"]],
                            binomial_fallback = aggregate_trait_fallback)
      lookup_pool <- unique(c(keys$primary[valid_rows], keys$inherit[valid_rows]))
      lookup_pool <- lookup_pool[!is.na(lookup_pool)]
    } else {
      lookup_pool <- unique(x[[join_col]][valid_rows])
    }

    names_df <- data.frame(lookup_name = lookup_pool, stringsAsFactors = FALSE)
    tmp <- tempfile(fileext = ".vtr")
    on.exit(unlink(tmp), add = TRUE)
    vectra::write_vtr(names_df, tmp)

    select_cols <- unique(c(join_key, unname(col_map)))
    joined <- vectra::inner_join(
      vectra::tbl(tmp),
      vectra::tbl(vtr_path) |>
        vectra::select(!!!lapply(select_cols, as.name)),
      by = stats::setNames(join_key, "lookup_name")
    ) |> vectra::collect()

    if (nrow(joined) > 0L) {
      if (agg_aware) {
        enr_key <- canon_agg_marker(joined$lookup_name)
        keep    <- !duplicated(enr_key)
        joined  <- joined[keep, , drop = FALSE]
        enr_key <- enr_key[keep]
        sel <- agg_select_idx(keys, enr_key)
        idx <- sel$idx
        if (isTRUE(getOption("taxify.trait_provenance", FALSE))) {
          x[[paste0(enrichment_name, "_basis")]] <- sel$basis
        }
      } else {
        joined <- joined[!duplicated(joined$lookup_name), , drop = FALSE]
        idx <- match(x[[join_col]], joined$lookup_name)
      }

      matched <- which(!is.na(idx))
      for (out_col in names(col_map)) {
        src_col <- col_map[[out_col]]
        if (src_col %in% names(joined)) {
          x[[out_col]][matched] <- joined[[src_col]][idx[matched]]
        }
      }
    }
  }

  # Genus fallback: a mixed-resolution source (e.g. the USEPA freshwater trait
  # table) records each trait at the finest level available -- some at species,
  # some only at genus, and often a mix within one species. After the
  # species-level join, any trait cell still empty is filled from the taxon's
  # genus-level row (x$genus matched against the same key column, where the
  # genus-rank strings live). The fill is per cell: a species-level value is
  # never overwritten, only genuine gaps inherit the coarser genus value.
  if (isTRUE(genus_fallback) && join_col == "accepted_name" &&
      "genus" %in% names(x)) {
    gap_rows <- which(
      !is.na(x[["genus"]]) &
        rowSums(is.na(x[, names(col_map), drop = FALSE])) > 0L
    )
    if (length(gap_rows) > 0L) {
      gpool <- unique(x[["genus"]][gap_rows])
      gnames <- data.frame(lookup_name = gpool, stringsAsFactors = FALSE)
      gtmp <- tempfile(fileext = ".vtr")
      on.exit(unlink(gtmp), add = TRUE)
      vectra::write_vtr(gnames, gtmp)
      select_cols <- unique(c(join_key, unname(col_map)))
      gjoin <- vectra::inner_join(
        vectra::tbl(gtmp),
        vectra::tbl(vtr_path) |>
          vectra::select(!!!lapply(select_cols, as.name)),
        by = stats::setNames(join_key, "lookup_name")
      ) |> vectra::collect()
      if (nrow(gjoin) > 0L) {
        gjoin <- gjoin[!duplicated(gjoin$lookup_name), , drop = FALSE]
        gidx  <- match(x[["genus"]], gjoin$lookup_name)
        for (out_col in names(col_map)) {
          src_col <- col_map[[out_col]]
          if (src_col %in% names(gjoin)) {
            fill <- which(is.na(x[[out_col]]) & !is.na(gidx))
            x[[out_col]][fill] <- gjoin[[src_col]][gidx[fill]]
          }
        }
      }
    }
  }

  # Hybrid ladder: a formula whose trait is still missing after the direct join
  # is filled from the average of its two parents (species-level joins only).
  if (join_col == "accepted_name") {
    x <- .hybrid_trait_fallback(x, col_map, join_key, vtr_path,
                                expose_all = expose_all, verbose = verbose)
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, ver, n_enriched,
                      license = lic)
}


#' Group-based enrichment join (country/region/language filtering + pivot)
#'
#' Joins an enrichment .vtr on accepted_name, filters by a grouping column
#' (country_code, tdwg_code, lang), and pivots to wide format.
#'
#' @param x A taxify_result data.frame.
#' @param enrichment_name Character. Enrichment identifier.
#' @param group_col Character. Column in .vtr to filter/pivot on
#'   (e.g., "country_code").
#' @param groups Character vector of group values to include, or "all".
#' @param value_cols Named character vector. Names = base output column names,
#'   values = source columns in .vtr. When length(groups) == 1, output columns
#'   use the base name; when > 1, they get a suffix (e.g., "invasive_status_AT").
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
enrich_by_group <- function(x, enrichment_name, group_col, groups,
                            value_cols, source_label,
                            na_types = NULL, cols = NULL, expose_all = TRUE,
                            verbose = TRUE) {
  if (!"accepted_name" %in% names(x)) {
    stop("x must have an 'accepted_name' column (from taxify())", call. = FALSE)
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Emergency fallback: ensure_enrichment() returned NULL → all paths failed
  if (is.null(vtr_path)) {
    df <- try_emergency_fallback(enrichment_name, verbose = verbose)
    return(enrich_from_dataframe_grouped(x, df, enrichment_name, group_col,
                                          groups, value_cols, source_label,
                                          na_types))
  }

  # Check schema
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  join_key <- if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    stop(sprintf(
      "Enrichment '%s' .vtr has no 'canonical_name' or 'accepted_name' column.",
      enrichment_name
    ), call. = FALSE)
  }

  if (!group_col %in% names(schema)) {
    stop(sprintf(
      "Enrichment '%s' .vtr has no '%s' column.", enrichment_name, group_col
    ), call. = FALSE)
  }

  # Expose every other per-(species, group) column the widened .vtr carries,
  # defaulting output to the door's curated value_cols. cols selects among them
  # ("all" or a vector); the extras keep their .vtr names.
  if (isTRUE(expose_all)) {
    reserved <- c(join_key, group_col, "canonical_name", "accepted_name",
                  "genus", unname(value_cols))
    extra <- setdiff(names(schema), reserved)
    extra <- extra[!is.na(extra) & nzchar(extra)]
    if (length(extra) > 0L) {
      default_vc <- names(value_cols)
      ex_out <- make.unique(c(names(value_cols), extra))[-seq_along(value_cols)]
      value_cols <- c(value_cols, stats::setNames(extra, ex_out))
      if (is.null(na_types)) na_types <- list()
      for (k in seq_along(ex_out)) {
        na_types[[ex_out[k]]] <-
          if (is.numeric(schema[[extra[k]]])) NA_real_ else NA_character_
      }
      sel <- if (is.null(cols)) default_vc
             else if (length(cols) == 1L && identical(tolower(cols), "all"))
               names(value_cols)
             else {
               idx <- match(tolower(cols), tolower(names(value_cols)))
               if (anyNA(idx)) stop(sprintf(
                 "add_%s(): unknown column(s): %s. Use \"all\", names, or NULL.",
                 enrichment_name, paste(cols[is.na(idx)], collapse = ", ")),
                 call. = FALSE)
               names(value_cols)[idx]
             }
      value_cols <- value_cols[sel]
    }
  }

  # Resolve "all" groups: manifest (O(1)) → vectra distinct() (fallback)
  if (length(groups) == 1L && !anyNA(groups) && groups == "all") {
    manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)
    entry <- if (!is.null(manifest)) {
      resolve_enrichment_entry(manifest, enrichment_name)
    } else {
      NULL
    }
    if (!is.null(entry$available_groups)) {
      groups <- entry$available_groups
    } else {
      all_data <- vectra::tbl(vtr_path) |>
        vectra::select(!!as.name(group_col)) |>
        vectra::distinct() |>
        vectra::collect()
      groups <- sort(all_data[[group_col]])
      groups <- groups[!is.na(groups)]
    }
  }

  if (verbose && length(groups) > 1L &&
      is.null(.taxify_env[[".taxify_long_tip_shown"]])) {
    message("Tip: pipe into taxify_long() to reshape wide columns to long format.")
    .taxify_env[[".taxify_long_tip_shown"]] <- TRUE
  }

  # Build output column names, typing each NA sentinel from its source column
  # (unless na_types overrides it), then initialize per group.
  if (is.null(na_types)) na_types <- list()
  for (base_col in names(value_cols)) {
    if (is.null(na_types[[base_col]])) {
      src <- value_cols[[base_col]]
      na_types[[base_col]] <- if (src %in% names(schema)) {
        na_sentinel_for(schema[[src]])
      } else {
        NA_character_
      }
    }
  }
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      out_cols <- c(out_cols, out_col)
      x[[out_col]] <- na_types[[base_col]]
    }
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Build temp .vtr with unique accepted names
  names_unique <- unique(x$accepted_name[valid_rows])
  names_df <- data.frame(lookup_name = names_unique, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(names_df, tmp)

  # Select needed columns
  select_cols <- unique(c(join_key, group_col, unname(value_cols)))
  select_cols <- intersect(select_cols, names(schema))

  joined <- vectra::inner_join(
    vectra::tbl(tmp),
    vectra::tbl(vtr_path) |>
      vectra::select(!!!lapply(select_cols, as.name)),
    by = stats::setNames(join_key, "lookup_name")
  ) |> vectra::collect()

  if (nrow(joined) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Filter to requested groups (NA-safe: %in% drops NA, so handle explicitly)
  has_na_group <- anyNA(groups)
  joined <- joined[
    joined[[group_col]] %in% groups |
      (has_na_group & is.na(joined[[group_col]])),
    , drop = FALSE
  ]
  if (nrow(joined) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Vectorized fill: one match() per group
  for (g in groups) {
    g_data <- if (is.na(g)) {
      joined[is.na(joined[[group_col]]), , drop = FALSE]
    } else {
      joined[!is.na(joined[[group_col]]) & joined[[group_col]] == g, , drop = FALSE]
    }
    if (nrow(g_data) == 0L) next
    g_data <- g_data[!duplicated(g_data$lookup_name), , drop = FALSE]
    idx <- match(x$accepted_name, g_data$lookup_name)
    matched <- which(!is.na(idx))
    if (length(matched) == 0L) next
    for (base_col in names(value_cols)) {
      src_col <- value_cols[[base_col]]
      if (!src_col %in% names(g_data)) next
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      x[[out_col]][matched] <- g_data[[src_col]][idx[matched]]
    }
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
  )
  x <- register_enrichment(x, enrichment_name, source_label, ver, n_enriched,
                            license = lic)

  # Stamp reshape metadata so taxify_long() can auto-detect
  reshape_entry <- list(cols = names(value_cols), group_col = group_col)
  prev <- attr(x, "taxify_reshape") %||% list()
  attr(x, "taxify_reshape") <- c(prev, list(reshape_entry))

  x
}


#' List available enrichments
#'
#' Returns a summary of all enrichment layers available in the taxify manifest,
#' including version, row count, whether the dataset is static, and which
#' trait columns are provided.
#'
#' @param verbose Logical. Default `TRUE`.
#' @return A data.frame with columns: `name`, `version`, `nrow`, `static`,
#'   `trait_cols` (comma-separated), and `source_url`.
#'
#' @examples
#' \donttest{
#' list_enrichments()
#' }
#'
#' @export
list_enrichments <- function(verbose = TRUE) {
  manifest <- fetch_manifest()
  entries <- manifest$enrichments
  if (is.null(entries) || length(entries) == 0L) {
    if (verbose) message("No enrichments found in manifest.")
    return(data.frame(
      name = character(0L), version = character(0L),
      nrow = integer(0L), static = logical(0L),
      trait_cols = character(0L), source_url = character(0L),
      stringsAsFactors = FALSE
    ))
  }

  nms <- names(entries)
  data.frame(
    name       = nms,
    version    = vapply(nms, function(n) entries[[n]]$latest %||% NA_character_, character(1L)),
    nrow       = vapply(nms, function(n) as.integer(entries[[n]]$nrow %||% NA_integer_), integer(1L)),
    static     = vapply(nms, function(n) isTRUE(entries[[n]]$static), logical(1L)),
    trait_cols = vapply(nms, function(n) {
      tc <- entries[[n]]$trait_cols
      if (is.null(tc)) NA_character_ else paste(tc, collapse = ", ")
    }, character(1L)),
    source_url = vapply(nms, function(n) entries[[n]]$source_url %||% NA_character_, character(1L)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

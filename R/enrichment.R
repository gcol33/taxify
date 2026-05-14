# ---- Enrichment layer infrastructure ----
#
# Enrichment layers join external trait/status data to taxify results via
# accepted_name. The .vtr files are built by CI in taxify-backbones and
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
check_enrichment_version <- function(name) {
  vtr_path <- enrichment_vtr_path(name)
  meta <- read_enrichment_meta(vtr_path)

  if (is.null(meta)) return(TRUE)  # No local copy

  # Static enrichments (version-locked datasets) never need updates
  if (isTRUE(meta$static)) return(FALSE)

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
#' @param name Character. Enrichment identifier (e.g., "conservation_status").
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

  # 4. Download from manifest
  path <- tryCatch(
    download_enrichment(name, verbose = verbose),
    error = function(e) NULL
  )
  if (!is.null(path) && file.exists(path)) {
    set_backbone_path(cache_key, path)
    return(path)
  }

  # 5. Build from source via taxifydb (if installed)
  if (requireNamespace("taxifydb", quietly = TRUE)) {
    available <- tryCatch(taxifydb::list_enrichments(),
                          error = function(e) character(0L))
    if (name %in% available) {
      if (verbose) {
        message(sprintf(
          "Pre-built .vtr not available for enrichment '%s'. Building from source via taxifydb...",
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

  # Write meta.json
  meta <- list(
    version       = actual_version,
    static        = isTRUE(entry$static),
    pinned        = (version != "latest"),
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
#'   `"conservation_status"`, `"griis"`, `"woodiness"`).
#' @param version Character. `"latest"` (default) or a specific version string.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#'
#' @details
#' Available enrichments:
#' \describe{
#'   \item{conservation_status}{IUCN conservation status (LC/NT/VU/EN/CR/EW/EX)}
#'   \item{griis}{GRIIS invasive species status by country}
#'   \item{woodiness}{Zanne et al. 2014 woody/herbaceous classification}
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

  # Initialize output columns
  for (out_col in names(col_map)) {
    na_val <- if (!is.null(na_types) && out_col %in% names(na_types)) {
      na_types[[out_col]]
    } else {
      NA_character_
    }
    x[[out_col]] <- na_val
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

  # Vectorized fill via match()
  df <- df[!duplicated(df[[df_join_key]]), , drop = FALSE]
  idx <- match(x[[join_col]], df[[df_join_key]])
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

  # Build output column names and initialize with correct NA types
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      out_cols <- c(out_cols, out_col)
      na_val <- if (!is.null(na_types) && base_col %in% names(na_types)) {
        na_types[[base_col]]
      } else {
        NA_character_
      }
      x[[out_col]] <- na_val
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
    stop(sprintf(
      paste0("Enrichment '%s' is not available:\n",
             "  %s\n",
             "  Build-from-source requires the 'taxifydb' package.\n",
             "  Install with: remotes::install_github(\"gcol33/taxify-backbones\")\n",
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
#' enrichment functions that add columns without filtering (conservation_status,
#' woodiness, indicator_values, etc.).
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
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
enrich_simple <- function(x, enrichment_name, col_map, source_label,
                          na_types = NULL, join_col = "accepted_name",
                          verbose = TRUE) {
  if (!join_col %in% names(x)) {
    stop(sprintf("x must have a '%s' column (from taxify())", join_col),
         call. = FALSE)
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Emergency fallback: ensure_enrichment() returned NULL → all paths failed

  if (is.null(vtr_path)) {
    df <- try_emergency_fallback(enrichment_name, verbose = verbose)
    return(enrich_from_dataframe(x, df, enrichment_name, col_map,
                                 source_label, na_types,
                                 join_col = join_col))
  }

  # Initialize output columns
  for (out_col in names(col_map)) {
    na_val <- if (!is.null(na_types) && out_col %in% names(na_types)) {
      na_types[[out_col]]
    } else {
      NA_character_
    }
    x[[out_col]] <- na_val
  }

  valid_rows <- which(!is.na(x[[join_col]]))
  if (length(valid_rows) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Check which source columns exist in the .vtr
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  available_src <- intersect(unname(col_map), names(schema))
  if (length(available_src) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Filter col_map to available columns
  col_map <- col_map[col_map %in% available_src]

  # Build temp .vtr with unique lookup values
  names_unique <- unique(x[[join_col]][valid_rows])
  names_df <- data.frame(lookup_name = names_unique, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)

  vectra::write_vtr(names_df, tmp)

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

  # Select only needed columns from enrichment .vtr
  select_cols <- unique(c(join_key, unname(col_map)))
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

  # Vectorized fill via match()
  joined <- joined[!duplicated(joined$lookup_name), , drop = FALSE]
  idx <- match(x[[join_col]], joined$lookup_name)
  matched <- which(!is.na(idx))
  for (out_col in names(col_map)) {
    src_col <- col_map[[out_col]]
    if (src_col %in% names(joined)) {
      x[[out_col]][matched] <- joined[[src_col]][idx[matched]]
    }
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
                            na_types = NULL, verbose = TRUE) {
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

  # Build output column names and initialize with correct NA types
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
      out_cols <- c(out_cols, out_col)
      na_val <- if (!is.null(na_types) && base_col %in% names(na_types)) {
        na_types[[base_col]]
      } else {
        NA_character_
      }
      x[[out_col]] <- na_val
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
#' \dontrun{
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

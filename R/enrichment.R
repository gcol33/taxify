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


# ---- Ensure / download ----

#' Ensure an enrichment .vtr is available
#'
#' Resolution order: session cache -> disk -> manifest download -> error.
#'
#' @param name Character. Enrichment identifier (e.g., "conservation_status").
#' @param verbose Logical.
#' @return Character. Path to the .vtr file.
#' @noRd
ensure_enrichment <- function(name, verbose = TRUE) {
  cache_key <- paste0("enrichment_", name)

  # 1. In-session cache
  cached <- get_backbone_path(cache_key)
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # 2. On disk
  vtr_path <- enrichment_vtr_path(name)
  if (file.exists(vtr_path)) {
    set_backbone_path(cache_key, vtr_path)
    return(vtr_path)
  }

  # 3. Download from manifest
  path <- tryCatch(
    download_enrichment(name, verbose = verbose),
    error = function(e) {
      stop(sprintf(
        paste0("Enrichment '%s' not available.\n",
               "  Install with: taxify_download_enrichment(\"%s\")\n",
               "  Error: %s"),
        name, name, conditionMessage(e)
      ), call. = FALSE)
    }
  )

  set_backbone_path(cache_key, path)
  path
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
        curl::curl_download(url, tmp_path, quiet = !verbose)
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
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
enrich_simple <- function(x, enrichment_name, col_map, source_label,
                          na_types = NULL, verbose = TRUE) {
  if (!"accepted_name" %in% names(x)) {
    stop("x must have an 'accepted_name' column (from taxify())", call. = FALSE)
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Initialize output columns
  for (out_col in names(col_map)) {
    na_val <- if (!is.null(na_types) && out_col %in% names(na_types)) {
      na_types[[out_col]]
    } else {
      NA_character_
    }
    x[[out_col]] <- na_val
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
  }

  # Check which source columns exist in the .vtr
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  available_src <- intersect(unname(col_map), names(schema))
  if (length(available_src) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
  }

  # Filter col_map to available columns
  col_map <- col_map[col_map %in% available_src]

  # Build temp .vtr with unique accepted names
  names_unique <- unique(x$accepted_name[valid_rows])
  names_df <- data.frame(lookup_name = names_unique, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)

  vectra::write_vtr(names_df, tmp)

  # Determine join key in enrichment .vtr
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
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
  }

  # Build lookup and fill
  lookup <- split(joined, joined$lookup_name)
  for (i in valid_rows) {
    info <- lookup[[x$accepted_name[i]]]
    if (!is.null(info) && nrow(info) > 0L) {
      for (out_col in names(col_map)) {
        src_col <- col_map[[out_col]]
        if (src_col %in% names(info)) {
          x[[out_col]][i] <- info[[src_col]][1L]
        }
      }
    }
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, ver, n_enriched)
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

  # Resolve "all" groups by reading distinct values
  if (length(groups) == 1L && groups == "all") {
    all_data <- vectra::tbl(vtr_path) |>
      vectra::select(!!as.name(group_col)) |>
      vectra::collect()
    groups <- sort(unique(all_data[[group_col]]))
    groups <- groups[!is.na(groups)]
  }

  # Determine output column names
  if (length(groups) == 1L) {
    out_cols <- names(value_cols)
  } else {
    out_cols <- unlist(lapply(groups, function(g) {
      paste0(names(value_cols), "_", g)
    }))
  }

  # Initialize output columns
  for (col in out_cols) {
    na_val <- NA_character_
    # Match base name for na_type lookup
    base <- sub("_[^_]+$", "", col)
    if (!is.null(na_types) && base %in% names(na_types)) {
      na_val <- na_types[[base]]
    }
    x[[col]] <- na_val
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
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
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
  }

  # Filter to requested groups
  joined <- joined[joined[[group_col]] %in% groups, , drop = FALSE]
  if (nrow(joined) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L))
  }

  # Build lookup: name -> list of group -> values
  lookup <- split(joined, joined$lookup_name)

  for (i in valid_rows) {
    info <- lookup[[x$accepted_name[i]]]
    if (is.null(info) || nrow(info) == 0L) next

    for (g in groups) {
      g_rows <- info[info[[group_col]] == g, , drop = FALSE]
      if (nrow(g_rows) == 0L) next

      for (base_col in names(value_cols)) {
        src_col <- value_cols[[base_col]]
        if (!src_col %in% names(g_rows)) next
        out_col <- if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
        x[[out_col]][i] <- g_rows[[src_col]][1L]
      }
    }
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, ver, n_enriched)
}

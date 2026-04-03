# ---- Backbone caching ----
#
# vectra nodes are single-use (consumed on collect). We cache the *path*
# to the .vtr file, and create fresh tbl() handles on demand.

#' Get a cached backbone path
#'
#' @param backend_name Character string (e.g., "wfo").
#' @return A character path or NULL if not cached.
#' @noRd
get_backbone_path <- function(backend_name) {
  if (exists(backend_name, envir = .taxify_cache, inherits = FALSE)) {
    get(backend_name, envir = .taxify_cache, inherits = FALSE)
  } else {
    NULL
  }
}


#' Store a backbone path in the cache
#'
#' @param backend_name Character string.
#' @param path Character. Path to the .vtr file, or `NULL` to remove from cache.
#' @noRd
set_backbone_path <- function(backend_name, path) {
  if (is.null(path)) {
    if (exists(backend_name, envir = .taxify_cache, inherits = FALSE)) {
      rm(list = backend_name, envir = .taxify_cache)
    }
  } else {
    assign(backend_name, path, envir = .taxify_cache)
  }
}


#' Create a fresh vectra node from a cached backbone path
#'
#' @param backend_name Character string.
#' @return A vectra node (lazy handle).
#' @noRd
backbone_node <- function(backend_name) {
  path <- get_backbone_path(backend_name)
  if (is.null(path)) {
    stop(sprintf("No backbone path cached for '%s'", backend_name),
         call. = FALSE)
  }
  vectra::tbl(path)
}


# ---- Backbone metadata (sidecar .meta files) ----

#' Write backbone metadata sidecar file
#'
#' Writes a `.meta` file alongside the `.vtr` recording download provenance:
#' backend name, version, download timestamp, source URL, and row count.
#'
#' @param vtr_path Character. Path to the `.vtr` file.
#' @param backend_name Character. Backend identifier (e.g., `"wfo"`).
#' @param version Character. Backbone version string.
#' @param url Character. Source URL the backbone was downloaded from.
#' @param nrow Integer. Number of rows in the converted backbone.
#' @return The path to the `.meta` file (invisibly).
#' @noRd
write_backbone_meta <- function(vtr_path, backend_name, version, url, nrow) {
  meta_path <- paste0(tools::file_path_sans_ext(vtr_path), ".meta")
  lines <- c(
    paste0("backend=", backend_name),
    paste0("version=", version),
    paste0("download_date=", format(Sys.time(), "%Y-%m-%d")),
    paste0("download_timestamp=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
    paste0("url=", url),
    paste0("nrow=", nrow)
  )
  writeLines(lines, meta_path)
  invisible(meta_path)
}


#' Read backbone metadata from sidecar file
#'
#' @param vtr_path Character. Path to the `.vtr` file.
#' @return A named list with fields `backend`, `version`, `download_date`,
#'   `download_timestamp`, `url`, `nrow`. Returns `NULL` if no `.meta` file
#'   exists.
#' @noRd
read_backbone_meta <- function(vtr_path) {
  meta_path <- paste0(tools::file_path_sans_ext(vtr_path), ".meta")
  if (!file.exists(meta_path)) return(NULL)
  lines <- readLines(meta_path, warn = FALSE)
  pairs <- strsplit(lines, "=", fixed = TRUE)
  keys <- vapply(pairs, `[`, character(1L), 1L)
  vals <- vapply(pairs, function(p) paste(p[-1L], collapse = "="), character(1L))
  stats::setNames(as.list(vals), keys)
}


#' Format backbone version string for output column
#'
#' Produces a string like `"wfo:2024-12 (2026-04-01)"` combining the backend
#' name, version, and download date from the `.meta` sidecar.
#'
#' @param vtr_path Character. Path to the `.vtr` file.
#' @param backend_name Character. Fallback backend name if no meta file.
#' @param version Character. Fallback version if no meta file.
#' @return A character string.
#' @noRd
format_backbone_version <- function(vtr_path, backend_name, version) {
  meta <- read_backbone_meta(vtr_path)
  if (!is.null(meta)) {
    sprintf("%s:%s (%s)", meta$backend, meta$version, meta$download_date)
  } else {
    paste0(backend_name, ":", version)
  }
}


#' Clear all cached backbones
#'
#' Removes all loaded backbone handles from memory. The next call to
#' [taxify()] will re-load from disk.
#'
#' @export
taxify_clear_cache <- function() {
  rm(list = ls(.taxify_cache), envir = .taxify_cache)
  invisible(NULL)
}


#' Get the taxify data directory
#'
#' Returns the platform-appropriate directory where taxify stores downloaded
#' backbone `.vtr` files. Uses [tools::R_user_dir()] (available since R 4.0).
#'
#' @return Character string. Path to the data directory.
#' @export
taxify_data_dir <- function() {
  tools::R_user_dir("taxify", "data")
}


#' Ensure a backbone path is cached (from cache, disk, or download)
#'
#' Resolves the path for `version = "latest"` using the versioned directory
#' layout (`<data_dir>/<backend>/latest/<backend>.vtr`). Falls back to the
#' legacy flat layout (`<data_dir>/<backend>.vtr`) for backwards compatibility
#' with backbones converted from source before the versioned layout was
#' introduced.
#'
#' @param backend A taxify_backend object.
#' @param version Character. `"latest"` or a specific version string.
#' @param verbose Logical.
#' @return Character. Path to the .vtr file.
#' @noRd
ensure_backbone <- function(backend, version = "latest", verbose = TRUE) {
  be_name <- backend$name

  # 1. In-session cache hit (set_backbone_path only stores verified paths)
  cached <- get_backbone_path(be_name)
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # 2. Versioned layout: <data_dir>/<backend>/<version>/<backend>.vtr
  versioned_path <- versioned_vtr_path(be_name, version)
  if (file.exists(versioned_path) && is_compiled_backbone(versioned_path)) {
    set_backbone_path(be_name, versioned_path)
    return(versioned_path)
  }

  # 3. Legacy flat layout: <data_dir>/<backend>.vtr
  legacy_path <- file.path(taxify_data_dir(), paste0(be_name, ".vtr"))
  if (file.exists(legacy_path) && is_compiled_backbone(legacy_path)) {
    set_backbone_path(be_name, legacy_path)
    return(legacy_path)
  }

  # 4. Auto-download (pre-built .vtr from Zenodo via manifest)
  path <- tryCatch(
    download_backbone(be_name, version = version, verbose = verbose),
    error = function(e) {
      # If pre-built download fails, fall back to build-from-source
      if (verbose) {
        message(sprintf(
          "Pre-built .vtr not available for '%s'. Building from source...",
          be_name
        ))
      }
      taxify_download(backend, verbose = verbose)
    }
  )

  set_backbone_path(be_name, path)
  path
}

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
# .meta files are written by taxifydb at build time; taxify only reads them.

#' Read backbone metadata from sidecar file
#'
#' Newer taxifydb builds label the sidecar with `build_date` /
#' `build_timestamp` / `source_url`; older ones used `download_date` /
#' `download_timestamp` / `url`. Both are normalized here so downstream
#' readers always find `download_date`, `download_timestamp`, and `url`.
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
  meta <- stats::setNames(as.list(vals), keys)

  meta$download_date      <- meta$download_date      %||% meta$build_date
  meta$download_timestamp <- meta$download_timestamp %||% meta$build_timestamp
  meta$url                <- meta$url                %||% meta$source_url
  meta
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
  be  <- (meta$backend %||% backend_name)
  ver <- (meta$version %||% version)
  dt  <- meta$download_date
  if (length(dt) == 1L && !is.na(dt) && nzchar(dt)) {
    sprintf("%s:%s (%s)", be, ver, dt)
  } else {
    paste0(be, ":", ver)
  }
}


#' Clear all cached backbones
#'
#' Removes all loaded backbone handles from memory. The next call to
#' [taxify()] will re-load from disk.
#'
#' @return No return value, called for side effects.
#' @export
taxify_clear_cache <- function() {
  rm(list = ls(.taxify_cache), envir = .taxify_cache)
  invisible(NULL)
}


#' Get the taxify data directory
#'
#' Returns the directory where taxify stores downloaded backbone and
#' enrichment `.vtr` files. By default this is the platform-appropriate
#' per-user cache returned by [tools::R_user_dir()] (available since R 4.0).
#'
#' The location can be overridden, in order of precedence, by the
#' `taxify.data_dir` option (`getOption("taxify.data_dir")`) or the
#' `TAXIFY_DATA_DIR` environment variable. This is useful to point taxify at
#' a shared cache, or at the small bundled example database returned by
#' [taxify_example_data()].
#'
#' @return Character string. Path to the data directory.
#' @export
taxify_data_dir <- function() {
  opt <- getOption("taxify.data_dir")
  if (!is.null(opt) && nzchar(opt)) return(opt)
  env <- Sys.getenv("TAXIFY_DATA_DIR", unset = "")
  if (nzchar(env)) return(env)
  tools::R_user_dir("taxify", "data")
}


#' Path to the bundled example database
#'
#' taxify ships a tiny example database (a handful of species per backbone
#' plus matching enrichment tables) so that examples and quick experiments
#' run offline, without downloading the full multi-million-row backbones.
#'
#' Point taxify at it for the current session by setting the
#' `taxify.data_dir` option:
#'
#' ```r
#' old <- options(taxify.data_dir = taxify_example_data())
#' taxify("Quercus robur") |> add_woodiness()
#' options(old)  # restore the real data directory
#' ```
#'
#' The example database is read-only and covers only the species used in the
#' package examples; use the full downloaded backbones for real work.
#'
#' @return Character string. Path to the bundled example database directory,
#'   or `""` if it is not installed.
#' @seealso [taxify_data_dir()]
#' @export
taxify_example_data <- function() {
  system.file("exampledb", package = "taxify")
}


#' Names of backbones whose compiled .vtr is present locally
#'
#' A no-download check: returns the backend names whose `.vtr` exists in the
#' current data directory, in canonical order. Used by [inspect()] when
#' `backbones = TRUE` to match against every installed backbone.
#'
#' @return Character vector of installed backend names (possibly empty).
#' @noRd
installed_backbones <- function() {
  known <- c("wfo", "col", "gbif", "itis", "ncbi", "ott", "worms",
             "fungorum", "algaebase", "euromed", "fishbase", "sealifebase")
  ok <- vapply(known, function(nm) {
    p <- versioned_vtr_path(nm, "latest")
    file.exists(p) && is_compiled_backbone(p)
  }, logical(1L))
  known[ok]
}


#' Ensure a backbone path is cached (from cache, disk, or download)
#'
#' Resolves the path for `version = "latest"` using the versioned directory
#' layout (`<data_dir>/<backend>/latest/<backend>.vtr`).
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

  # 3. Auto-download (pre-built .vtr from Zenodo via manifest)
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

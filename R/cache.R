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
#' @param path Character. Path to the .vtr file.
#' @noRd
set_backbone_path <- function(backend_name, path) {
  assign(backend_name, path, envir = .taxify_cache)
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
#' @param backend A taxify_backend object.
#' @param verbose Logical.
#' @return Character. Path to the .vtr file.
#' @noRd
ensure_backbone <- function(backend, verbose = TRUE) {
  cached <- get_backbone_path(backend$name)
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # Try finding on disk
  path <- tryCatch(
    taxify_load(backend),
    error = function(e) NULL
  )

  if (!is.null(path)) {
    set_backbone_path(backend$name, path)
    return(path)
  }

  # Auto-download
  if (verbose) message("Backbone not found locally. Downloading...")
  path <- taxify_download(backend, verbose = verbose)
  set_backbone_path(backend$name, path)
  path
}

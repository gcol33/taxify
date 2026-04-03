# ---- Manifest: remote version catalogue ----
#
# The manifest.json is shipped with the package (inst/manifest.json) and also
# hosted at the GitHub raw URL below. It records the latest available version
# and Zenodo download URL for each backend and the genus register.
#
# fetch_manifest() is called once per R session; the result is cached in
# .taxify_env$manifest so subsequent calls in the same session are free.

.manifest_url <- paste0(
  "https://raw.githubusercontent.com/gcol33/taxify/main/inst/manifest.json"
)


#' Fetch the remote manifest, with session-level caching
#'
#' Returns the parsed manifest list. On network failure, falls back to the
#' bundled `inst/manifest.json`. Never throws — returns the fallback silently
#' with a warning so callers can decide whether to proceed.
#'
#' @return A named list with one entry per backend (e.g., `$wfo$latest`,
#'   `$wfo$url`).
#' @noRd
fetch_manifest <- function() {
  # Session cache hit
  if (!is.null(.taxify_env$manifest)) return(.taxify_env$manifest)

  manifest <- tryCatch(
    {
      tmp <- tempfile(fileext = ".json")
      on.exit(unlink(tmp), add = TRUE)
      curl::curl_download(.manifest_url, tmp, quiet = TRUE)
      jsonlite::read_json(tmp, simplifyVector = FALSE)
    },
    error = function(e) {
      warning(
        "Could not fetch taxify manifest from GitHub (no network?). ",
        "Using bundled manifest. Backbone versions may be outdated.",
        call. = FALSE
      )
      local_manifest()
    }
  )

  .taxify_env$manifest <- manifest
  manifest
}


#' Read the bundled manifest shipped with the package
#'
#' Used as a fallback when the network is unavailable.
#'
#' @return A named list.
#' @noRd
local_manifest <- function() {
  path <- system.file("manifest.json", package = "taxify")
  if (!nzchar(path)) {
    stop("inst/manifest.json not found in package installation.", call. = FALSE)
  }
  jsonlite::read_json(path, simplifyVector = FALSE)
}


#' Check whether a local backbone version is current
#'
#' Compares the version recorded in `<data_dir>/<backend>/latest/meta.json`
#' (if it exists) against the manifest. Returns `TRUE` if an update is needed.
#'
#' @param backend_name Character string (e.g., `"wfo"`).
#' @return Logical scalar. `TRUE` means a newer version is available (or no
#'   local backbone exists yet).
#' @noRd
check_version <- function(backend_name) {
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backend_name)
  if (is.null(entry)) return(FALSE)  # Unknown backend — skip

  latest <- entry$latest
  meta <- read_version_meta(backend_name, "latest")

  if (is.null(meta)) return(TRUE)   # No local copy at all

  # Compare: simple string comparison works for "YYYY.MM" format
  isTRUE(meta$version != latest)
}


#' Resolve the download URL for a backend + version
#'
#' For `version = "latest"` the URL comes from the manifest. For a pinned
#' version the caller must supply an explicit URL (not yet supported via
#' manifest — placeholder).
#'
#' @param backend_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @return Character URL.
#' @noRd
manifest_url <- function(backend_name, version = "latest") {
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backend_name)
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backend_name),
         call. = FALSE)
  }
  # v2 schema uses full_url; v1 uses url
  url <- entry$full_url %||% entry$url
  if (version == "latest") {
    url
  } else {
    gsub(
      paste0(backend_name, "_[^/]+\\.vtr"),
      sprintf("%s_%s.vtr", backend_name, version),
      url
    )
  }
}


#' Resolve a manifest entry, handling both v1 and v2 schema
#'
#' v1: flat structure `{ "wfo": { "latest": ..., "url": ... } }`
#' v2: nested `{ "schema_version": 2, "backends": { "wfo": { ... } } }`
#'
#' @param manifest The parsed manifest list.
#' @param backend_name Character.
#' @return The entry list, or NULL.
#' @noRd
resolve_manifest_entry <- function(manifest, backend_name) {
  if (!is.null(manifest$schema_version) && manifest$schema_version >= 2L) {
    manifest$backends[[backend_name]]
  } else {
    manifest[[backend_name]]
  }
}


#' Get the xdelta3 patch URL for a backend (if available)
#'
#' @param backend_name Character.
#' @param version Character.
#' @return Character URL or NULL if no delta available.
#' @noRd
manifest_delta_url <- function(backend_name, version = "latest") {
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backend_name)
  if (is.null(entry)) return(NULL)
  entry$delta_url  # NULL if not present in manifest
}


#' Invalidate the session manifest cache
#'
#' Forces the next `fetch_manifest()` call to re-fetch from the network.
#' Useful after the maintainer updates the manifest between R sessions without
#' restarting R.
#'
#' @export
taxify_refresh_manifest <- function() {
  .taxify_env$manifest <- NULL
  invisible(NULL)
}


#' Activate a local manifest for dev/testing
#'
#' Scans `taxify_data_dir()` for installed backends, reads their `meta.json`
#' version files, and builds an in-memory manifest using `file://` URLs that
#' point at the local `.vtr` files.  Injects the result into
#' `.taxify_env$manifest`, overriding any network-fetched manifest for the
#' remainder of the session.
#'
#' Also clears `.taxify_env$.version_checked.*` flags so the next
#' `taxify()` call re-runs the version check against the injected manifest
#' (which will always report "current" since the local file IS the version).
#'
#' This is a dev-only helper.  Call `clear_local_manifest()` to revert.
#'
#' @return The injected manifest list (invisibly).
#' @noRd
use_local_manifest <- function() {
  data_dir <- taxify_data_dir()

  # Backend name -> vtr filename inside <backend>/latest/
  backends <- list(
    wfo      = "wfo.vtr",
    col      = "col.vtr",
    gbif     = "gbif.vtr",
    itis     = "itis.vtr",
    register = "genus_register.vtr"
  )

  manifest <- list()
  found <- character(0L)
  not_found <- character(0L)

  for (be_name in names(backends)) {
    vtr_file <- backends[[be_name]]
    vtr_path <- file.path(data_dir, be_name, "latest", vtr_file)

    # Special case: register lives under "unified/latest/"
    if (be_name == "register") {
      vtr_path <- file.path(data_dir, "unified", "latest", vtr_file)
    }

    if (!file.exists(vtr_path)) {
      not_found <- c(not_found, be_name)
      next
    }

    # Read meta.json if present, otherwise fall back to "unknown"
    meta_json <- file.path(dirname(vtr_path), "meta.json")
    if (file.exists(meta_json)) {
      meta <- jsonlite::read_json(meta_json, simplifyVector = TRUE)
      version <- meta$version %||% "unknown"
    } else {
      version <- "unknown"
    }

    # Build a file:// URL.  On Windows, paths need three slashes for absolute.
    # normalizePath() gives the canonical OS path; we convert separators.
    abs_path <- normalizePath(vtr_path, winslash = "/", mustWork = TRUE)
    file_url <- paste0("file:///", abs_path)

    manifest[[be_name]] <- list(latest = version, url = file_url)
    found <- c(found, sprintf("  %-10s v%-12s  ->  %s", be_name, version,
                              file_url))
  }

  # Inject into session cache
  .taxify_env$manifest <- manifest

  # Clear version-check flags so taxify() re-evaluates against local manifest
  for (be_name in names(backends)) {
    check_key <- paste0(".version_checked.", be_name)
    .taxify_env[[check_key]] <- NULL
  }

  # Report
  if (length(found) > 0L) {
    message("Local manifest active:")
    for (line in found) message(line)
  }
  if (length(not_found) > 0L) {
    message(sprintf("  (not installed: %s)", paste(not_found, collapse = ", ")))
  }
  if (length(found) == 0L) {
    message("Local manifest active (no backends installed yet).")
  }

  invisible(manifest)
}


#' Clear the local manifest override
#'
#' Removes the session-level manifest cache and version-check flags so the
#' next `taxify()` call fetches a fresh manifest from GitHub.
#'
#' @return `NULL` invisibly.
#' @noRd
clear_local_manifest <- function() {
  .taxify_env$manifest <- NULL

  # Clear all version-checked flags
  keys <- ls(.taxify_env, all.names = TRUE)
  check_keys <- keys[startsWith(keys, ".version_checked.")]
  for (k in check_keys) {
    .taxify_env[[k]] <- NULL
  }

  message("Local manifest cleared. Next taxify() call will fetch from GitHub.")
  invisible(NULL)
}

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
  entry <- manifest[[backend_name]]
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
  entry <- manifest[[backend_name]]
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backend_name),
         call. = FALSE)
  }
  if (version == "latest") {
    entry$url
  } else {
    # For pinned versions, derive URL by substituting the version string.
    # This assumes the URL pattern is consistent (Zenodo path ends with
    # <backend>_<version>.vtr). Maintainer should update the manifest to
    # include per-version URLs when publishing pinned releases.
    gsub(
      paste0(backend_name, "_[^/]+\\.vtr"),
      sprintf("%s_%s.vtr", backend_name, version),
      entry$url
    )
  }
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

# ---- Manifest: remote version catalogue ----
#
# The manifest.json is shipped with the package (inst/manifest.json) and also
# hosted at the GitHub raw URL below. It records the latest available version
# and download URL for each backbone and the genus register.
#
# fetch_manifest() is called once per R session; the result is cached in
# .taxify_env$manifest so subsequent calls in the same session are free.

.manifest_url <- paste0(
  "https://raw.githubusercontent.com/gcol33/taxify/main/inst/manifest.json"
)


#' Fetch the remote manifest, with session-level caching
#'
#' Returns the parsed manifest list. On network failure, falls back to the
#' bundled `inst/manifest.json`. Never throws — returns the fallback
#' with a warning so callers can decide whether to proceed.
#'
#' @return A named list with one entry per backbone (e.g., `$wfo$latest`,
#'   `$wfo$url`).
#' @noRd
fetch_manifest <- function() {
  # Session cache hit
  if (!is.null(.taxify_env$manifest)) return(.taxify_env$manifest)

  if (taxify_offline()) {
    manifest <- local_manifest()
    .taxify_env$manifest <- manifest
    return(manifest)
  }

  manifest <- tryCatch(
    {
      tmp <- tempfile(fileext = ".json")
      on.exit(unlink(tmp), add = TRUE)
      curl::curl_download(.manifest_url, tmp, quiet = TRUE)
      read_json_bom(tmp, simplifyVector = FALSE)
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
  path <- getOption("taxify.manifest_path",
                    system.file("manifest.json", package = "taxify"))
  if (!nzchar(path) || !file.exists(path)) {
    stop("inst/manifest.json not found in package installation.", call. = FALSE)
  }
  read_json_bom(path, simplifyVector = FALSE)
}


#' Read a JSON file, tolerating a leading UTF-8 BOM
#'
#' PowerShell's `Set-Content` / `Out-File` (and some editors) prepend a UTF-8
#' byte-order mark (`EF BB BF`); `jsonlite` then warns "illegal byte-order-mark"
#' on every read and, on some parsers, fails outright. Strip a leading BOM
#' before parsing so a `meta.json` or manifest written outside the R download
#' path still reads cleanly. Every `meta.json` / manifest read goes through this.
#'
#' @param path Character. Path to a JSON file.
#' @param ... Passed to [jsonlite::fromJSON()] (e.g. `simplifyVector`).
#' @return The parsed JSON.
#' @noRd
read_json_bom <- function(path, ...) {
  raw <- readBin(path, "raw", n = file.info(path)$size)
  if (length(raw) >= 3L && raw[1] == as.raw(0xEF) &&
      raw[2] == as.raw(0xBB) && raw[3] == as.raw(0xBF)) {
    raw <- raw[-(1:3)]
  }
  txt <- rawToChar(raw)
  Encoding(txt) <- "UTF-8"
  jsonlite::fromJSON(txt, ...)
}


#' Check whether a local backbone version is current
#'
#' Compares the version recorded in `<data_dir>/<backbone>/latest/meta.json`
#' (if it exists) against the manifest. Returns `TRUE` if an update is needed.
#'
#' @param backbone_name Character string (e.g., `"wfo"`).
#' @return Logical scalar. `TRUE` means a newer version is available (or no
#'   local backbone exists yet).
#' @noRd
check_version <- function(backbone_name) {
  # Never refresh against the read-only example database (offline fixtures).
  if (is_example_data_dir()) return(FALSE)

  meta <- read_version_meta(backbone_name, "latest")
  vtr  <- versioned_vtr_path(backbone_name, "latest")

  # A build the user pinned -- restored by content id -- stays put. Refreshing
  # it to the current release would silently undo the pin at the next session.
  if (!is.null(meta) && isTRUE(as.logical(meta$pinned))) return(FALSE)

  # Frozen/bundled backbones (e.g. the example database) never phone home, but
  # a shipped content id still lets a same-tag republish refresh them offline
  # (mirrors the static-enrichment gate; the example db is small to hash).
  # The example database is exempted above by its location; a cache without
  # `downloaded_at` was built locally and is reconciled like a download.
  if (!is.null(meta) && isTRUE(meta$static %in% c(TRUE, "TRUE", "true"))) {
    entry <- tryCatch(resolve_manifest_entry(local_manifest(), backbone_name),
                      error = function(e) NULL)
    s <- reconcile_content_id(vtr, meta$content_id, entry$content_id,
                              adopt = function(cid) write_content_id_meta(vtr, cid))
    return(if (is.na(s)) FALSE else s)
  }

  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backbone_name)
  if (is.null(entry)) return(FALSE)  # Unknown backbone — skip

  if (is.null(meta)) return(TRUE)   # No local copy at all

  # Content identity decides, and the version string is the fallback. A version
  # records when a build ran, not what it read: a backbone whose source is
  # pinned (Euro+Med reads a frozen snapshot, WFO a fixed Zenodo record)
  # rebuilds to the same bytes under a new `YYYY.MM`, and comparing labels first
  # would refetch a file the user already holds -- 740 MB of it, for WFO. The
  # same comparison also catches the opposite case, a same-tag republish that
  # leaves the label unchanged.
  #
  # Only for runtime-downloaded caches (downloaded_at); hash_missing = FALSE
  # avoids rehashing a multi-GB backbone, so a cache downloaded with a content
  # id in its meta is compared and an older cache without one falls through.
  if (!is.null(meta$downloaded_at)) {
    s <- reconcile_content_id(vtr, meta$content_id, entry$content_id,
                              hash_missing = FALSE)
    if (!is.na(s)) return(s)
  }

  # Neither side carries a content id: the version string is all there is.
  isTRUE(meta$version != entry$latest)
}


#' Download URL of one published version of an asset
#'
#' Release assets live at `<...>/download/<tag>/<file>`, where the tag ends in
#' the version it publishes: `wfo-2026.08/wfo.vtr` for a backbone,
#' `enrichment-2026.08/iucn.vtr` for an enrichment. A pinned version is the same
#' URL with that suffix swapped -- the derivation from the tag layout that
#' `content_asset_url()` uses for a content id.
#'
#' Rewriting only the tag is what keeps both kinds on one rule: the file name
#' identifies the asset and never carries the version.
#'
#' @param base_url Character. The `full_url` of the rolling (latest) asset.
#' @param version Character. The version to point at.
#' @return Character URL, or `NULL` when `base_url` has no such tag, so no
#'   versioned copy can be named.
#' @noRd
versioned_asset_url <- function(base_url, version) {
  if (is.null(base_url) || length(base_url) != 1L || is.na(base_url) ||
      !nzchar(base_url)) {
    return(NULL)
  }
  dir  <- sub("/[^/]+$", "", base_url)
  file <- sub("^.*/", "", base_url)
  tag  <- sub("^.*/", "", dir)
  if (identical(dir, base_url) || !grepl("-", tag, fixed = TRUE)) return(NULL)
  paste0(sub("/[^/]+$", "", dir), "/", sub("-[^-]+$", "", tag), "-", version,
         "/", file)
}


#' The pinned-version URL, or an error naming what could not be pinned
#'
#' Shared by the backbone and the enrichment download path so both refuse the
#' same way. Handing back the latest URL instead is what wrote current bytes
#' into a directory named for an older version.
#'
#' @param base_url Character. The manifest entry's rolling URL.
#' @param name Character. Asset name, for the message.
#' @param version Character. The requested version.
#' @param latest Character or `NULL`. The manifest's current version.
#' @return Character URL.
#' @noRd
pinned_asset_url <- function(base_url, name, version, latest = NULL) {
  url <- versioned_asset_url(base_url, version)
  if (is.null(url)) {
    stop(sprintf(
      paste0("Cannot resolve version '%s' of '%s': its manifest URL (%s) is ",
             "not a versioned release asset, so only the current build can be ",
             "downloaded."),
      version, name, base_url %||% "<none>"), call. = FALSE)
  }
  if (!asset_url_exists(url)) {
    stop(sprintf(
      paste0("Version '%s' of '%s' is not published.\n  Tried: %s\n",
             "  The current release is '%s'."),
      version, name, url, latest %||% "unknown"), call. = FALSE)
  }
  url
}


#' Resolve the download URL for a backbone + version
#'
#' For `version = "latest"` the URL comes from the manifest. A pinned version is
#' derived from the release tag layout and checked for existence, so a version
#' that was never published errors instead of resolving to the current build.
#'
#' @param backbone_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @return Character URL.
#' @noRd
manifest_url <- function(backbone_name, version = "latest") {
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backbone_name)
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backbone_name),
         call. = FALSE)
  }
  # v2 schema uses full_url; v1 uses url
  url <- entry$full_url %||% entry$url
  if (version == "latest") return(url)
  pinned_asset_url(url, backbone_name, version, entry$latest)
}


#' Resolve a manifest entry, handling both v1 and v2 schema
#'
#' v1: flat structure `{ "wfo": { "latest": ..., "url": ... } }`
#' v2: nested `{ "schema_version": 2, "backends": { "wfo": { ... } } }`
#'
#' An asset this package version knows about can be absent from the fetched
#' manifest, which is hosted from the default branch and so lags a release that
#' adds one. The bundled manifest is consulted for exactly that case: a key the
#' remote does not carry. Where both carry a key the remote wins, which is what
#' makes a version bump reach an already-installed package.
#'
#' @param manifest The parsed manifest list.
#' @param backbone_name Character.
#' @return The entry list, or NULL.
#' @noRd
resolve_manifest_entry <- function(manifest, backbone_name) {
  pick <- function(m) {
    if (!is.null(m$schema_version) && m$schema_version >= 2L) {
      m$backends[[backbone_name]]
    } else {
      m[[backbone_name]]
    }
  }
  entry <- pick(manifest)
  if (!is.null(entry)) return(entry)
  tryCatch(pick(local_manifest()), error = function(e) NULL)
}


#' Get the xdelta3 patch URL for a backbone (if available)
#'
#' @param backbone_name Character.
#' @param version Character.
#' @return Character URL or NULL if no delta available.
#' @noRd
manifest_delta_url <- function(backbone_name, version = "latest") {
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backbone_name)
  if (is.null(entry)) return(NULL)
  entry$delta_url  # NULL if not present in manifest
}


#' Invalidate the session manifest cache
#'
#' Forces the next `fetch_manifest()` call to re-fetch from the network.
#' Useful after the maintainer updates the manifest between R sessions without
#' restarting R.
#'
#' @return No return value, called for side effects.
#' @export
taxify_refresh_manifest <- function() {
  .taxify_env$manifest <- NULL
  invisible(NULL)
}


#' Activate a local manifest for dev/testing
#'
#' Scans `taxify_data_dir()` for installed backbones, reads their `meta.json`
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

  backbones <- c("wfo", "col", "gbif", "itis",
                .register_assets[["register"]], .register_assets[["coverage"]])

  manifest <- list()
  found <- character(0L)
  not_found <- character(0L)

  for (bb_name in backbones) {
    vtr_path <- file.path(data_dir, bb_name, "latest", paste0(bb_name, ".vtr"))

    if (!file.exists(vtr_path)) {
      not_found <- c(not_found, bb_name)
      next
    }

    # Read meta.json if present, otherwise fall back to "unknown"
    meta_json <- file.path(dirname(vtr_path), "meta.json")
    if (file.exists(meta_json)) {
      meta <- read_json_bom(meta_json, simplifyVector = TRUE)
      version <- meta$version %||% "unknown"
    } else {
      version <- "unknown"
    }

    # Build a file:// URL.  On Windows, paths need three slashes for absolute.
    # normalizePath() gives the canonical OS path; we convert separators.
    abs_path <- normalizePath(vtr_path, winslash = "/", mustWork = TRUE)
    file_url <- paste0("file:///", abs_path)

    manifest[[bb_name]] <- list(latest = version, url = file_url)
    found <- c(found, sprintf("  %-10s v%-12s  ->  %s", bb_name, version,
                              file_url))
  }

  # Inject into session cache
  .taxify_env$manifest <- manifest

  # Clear version-check flags so taxify() re-evaluates against local manifest
  for (bb_name in backbones) {
    check_key <- paste0(".version_checked.", bb_name)
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
    message("Local manifest active (no backbones installed yet).")
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

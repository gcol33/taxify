# ---- Download: manifest-driven backbone downloads ----
#
# taxify_download(backend, version = "latest") is the user-facing function.
# It downloads the pre-built .vtr from Zenodo (via the manifest URL), writes
# a meta.json alongside it, and returns the path to the .vtr.
#
# The backends still have their own taxify_download S3 methods for the
# *build-from-source* path (CSV/ZIP → .vtr conversion). This file handles
# the *pre-built* path.
#
# Disk layout:
#   taxify_data_dir()/
#     wfo/
#       latest/wfo.vtr + meta.json
#       2024.01/wfo.vtr + meta.json   (pinned, never overwritten)
#     col/
#       latest/col.vtr + meta.json
#     gbif/
#       latest/gbif.vtr + meta.json
#     unified/
#       latest/genus_register.vtr + meta.json


# ---- Version meta.json (per versioned folder) ----

#' Write a meta.json for a downloaded backbone version
#'
#' @param dir Character. The versioned directory
#'   (e.g. `taxify_data_dir()/wfo/latest`).
#' @param backend_name Character.
#' @param version Character.
#' @param pinned Logical. `FALSE` for the rolling "latest" slot.
#' @noRd
write_version_meta <- function(dir, backend_name, version, pinned = FALSE) {
  meta <- list(
    version      = version,
    pinned       = pinned,
    downloaded_at = format(Sys.Date(), "%Y-%m-%d")
  )
  path <- file.path(dir, "meta.json")
  jsonlite::write_json(meta, path, pretty = TRUE, auto_unbox = TRUE)
  invisible(path)
}


#' Read a meta.json from a versioned backbone directory
#'
#' @param backend_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @return A named list with `version`, `pinned`, `downloaded_at`, or `NULL`
#'   if the file does not exist.
#' @noRd
read_version_meta <- function(backend_name, version = "latest") {
  dir <- versioned_dir(backend_name, version)
  path <- file.path(dir, "meta.json")
  if (!file.exists(path)) return(NULL)
  jsonlite::read_json(path, simplifyVector = TRUE)
}


# ---- Path helpers ----

#' Return the versioned directory for a backend
#'
#' @param backend_name Character.
#' @param version Character.
#' @return Character path (not guaranteed to exist).
#' @noRd
versioned_dir <- function(backend_name, version = "latest") {
  file.path(taxify_data_dir(), backend_name, version)
}


#' Return the .vtr path for a backend + version
#'
#' @param backend_name Character.
#' @param version Character.
#' @return Character path (not guaranteed to exist).
#' @noRd
versioned_vtr_path <- function(backend_name, version = "latest") {
  file.path(versioned_dir(backend_name, version),
            paste0(backend_name, ".vtr"))
}


# ---- Core download function ----

#' Download a backbone .vtr from Zenodo
#'
#' Downloads the `.vtr` into `<data_dir>/<backend>/<version>/` atomically
#' (temp file → rename). Writes `meta.json` on success. If the target file
#' already exists and `version` is not `"latest"` (i.e., a pinned version),
#' returns the existing path without re-downloading.
#'
#' @param backend_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @param dest_dir Character. Target directory. Defaults to
#'   `versioned_dir(backend_name, version)`.
#' @param verbose Logical.
#' @return Path to the downloaded `.vtr` (invisibly).
#' @noRd
download_backbone <- function(backend_name,
                              version   = "latest",
                              dest_dir  = NULL,
                              verbose   = TRUE) {

  dest_dir <- dest_dir %||% versioned_dir(backend_name, version)
  vtr_path <- file.path(dest_dir, paste0(backend_name, ".vtr"))

  # Pinned versions: never overwrite if already present
  if (version != "latest" && file.exists(vtr_path)) {
    if (verbose) {
      message(sprintf("\u2713 %s backbone v%s already present (pinned). Skipping.",
                      toupper(backend_name), version))
    }
    return(invisible(vtr_path))
  }

  # Resolve actual version string and download URL from manifest
  manifest <- fetch_manifest()
  entry <- manifest[[backend_name]]
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backend_name),
         call. = FALSE)
  }
  actual_version <- if (version == "latest") entry$latest else version
  url <- manifest_url(backend_name, version)

  if (verbose) {
    local_ver <- if (!is.null(read_version_meta(backend_name, version)))
      read_version_meta(backend_name, version)$version
    else
      NULL
    if (!is.null(local_ver) && local_ver != actual_version) {
      message(sprintf(
        "\u2139 %s backbone outdated (local: %s, latest: %s). Downloading...",
        toupper(backend_name), local_ver, actual_version
      ))
    } else if (is.null(local_ver)) {
      message(sprintf(
        "\u2139 %s backbone not found locally. Downloading v%s...",
        toupper(backend_name), actual_version
      ))
    } else {
      message(sprintf(
        "\u2139 %s backbone is current (v%s). Re-downloading...",
        toupper(backend_name), actual_version
      ))
    }
  }

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  tmp_path <- tempfile(tmpdir = dest_dir, fileext = ".vtr.tmp")
  on.exit(if (file.exists(tmp_path)) unlink(tmp_path), add = TRUE)

  tryCatch(
    {
      curl::curl_download(url, tmp_path, quiet = !verbose)
    },
    error = function(e) {
      stop(sprintf("Failed to download %s backbone from:\n  %s\nError: %s",
                   backend_name, url, conditionMessage(e)),
           call. = FALSE)
    }
  )

  # Atomic rename
  file.rename(tmp_path, vtr_path)
  write_version_meta(dest_dir, backend_name, actual_version,
                     pinned = (version != "latest"))

  if (verbose) {
    size_mb <- file.size(vtr_path) / 1048576
    message(sprintf("\u2713 %s backbone ready (v%s, %.0f MB).",
                    toupper(backend_name), actual_version, size_mb))
  }

  invisible(vtr_path)
}


# ---- User-facing download function ----

#' Download a taxify backbone
#'
#' Downloads a pre-built `.vtr` backbone from Zenodo using the taxify manifest.
#' Progress is always shown. No prompts are shown — calling this function is
#' consent.
#'
#' @param backend Character. One of `"wfo"`, `"col"`, `"gbif"`, or
#'   `"register"`. Multiple backends can be specified as a character vector.
#' @param version Character. `"latest"` (default) downloads into
#'   `<data_dir>/<backend>/latest/` and will be overwritten on future updates.
#'   A specific version string (e.g., `"2024.01"`) downloads into a pinned
#'   folder that is never overwritten.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#' @export
taxify_download_vtr <- function(backend = "wfo",
                                version = "latest",
                                verbose = TRUE) {
  paths <- vapply(backend, function(be) {
    download_backbone(be, version = version, verbose = verbose)
  }, character(1L))
  invisible(paths)
}


# ---- Once-per-session version check ----

#' Check all requested backends and auto-download if outdated
#'
#' Called at the top of `taxify()`. Uses the session cache in `.taxify_env`
#' to run at most once per R session per backend, regardless of how many
#' `taxify()` calls are made.
#'
#' @param backend_names Character vector of backend names.
#' @param verbose Logical.
#' @noRd
ensure_backends_current <- function(backend_names, verbose = TRUE) {
  for (be_name in backend_names) {
    # Skip if already checked this session
    check_key <- paste0(".version_checked.", be_name)
    if (isTRUE(.taxify_env[[check_key]])) next

    # Mark as checked immediately (even if download fails — we don't want to
    # retry on every taxify() call in a session)
    .taxify_env[[check_key]] <- TRUE

    tryCatch(
      {
        if (check_version(be_name)) {
          download_backbone(be_name, version = "latest", verbose = verbose)
          # Invalidate cached path so ensure_backbone() picks up the new file
          set_backbone_path(be_name, NULL)
        }
      },
      error = function(e) {
        warning(
          sprintf(
            "Could not update %s backbone: %s\nUsing existing local version.",
            be_name, conditionMessage(e)
          ),
          call. = FALSE
        )
      }
    )
  }
  invisible(NULL)
}

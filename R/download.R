# ---- Download: manifest-driven backbone downloads ----
#
# taxify_download(backend, version = "latest") is the user-facing function.
# It downloads the pre-built .vtr from Zenodo (via the manifest URL), writes
# a meta.json alongside it, and returns the path to the .vtr.
#
# The backends still have their own taxify_build() S3 methods for the
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
#     genus_register/
#       latest/genus_register.vtr + meta.json


# ---- Offline mode ----

#' Is taxify resolving assets without the network?
#'
#' Offline mode confines taxify to what is already on disk plus the bundled
#' manifest: no version checks, no downloads, and no fallback to a
#' build-from-source that would fetch a raw dataset. A `file://` manifest URL
#' still resolves, because copying a local file is not a network operation.
#'
#' Set `options(taxify.offline = TRUE)` for a session, or the `TAXIFY_OFFLINE`
#' environment variable for a whole process. The option wins when both are set.
#'
#' @return Logical scalar.
#' @noRd
taxify_offline <- function() {
  opt <- getOption("taxify.offline", NULL)
  if (!is.null(opt)) return(isTRUE(opt))
  nzchar(Sys.getenv("TAXIFY_OFFLINE"))
}


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
  vtr <- file.path(dir, paste0(backend_name, ".vtr"))
  meta <- list(
    version      = version,
    pinned       = pinned,
    # md5 of the downloaded .vtr, so check_version() can detect a same-tag
    # republish offline (matches the manifest's content_id for this backend).
    content_id   = content_id_of(vtr),
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
  read_json_bom(path, simplifyVector = TRUE)
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
#' (temp file -> rename). Writes `meta.json` on success. If the target file
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
  entry <- resolve_manifest_entry(manifest, backend_name)
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backend_name),
         call. = FALSE)
  }
  actual_version <- if (version == "latest") entry$latest else version
  url <- manifest_url(backend_name, version)

  if (taxify_offline() && !startsWith(url, "file://")) {
    stop(sprintf(
      "taxify is in offline mode; not downloading the %s backbone.",
      backend_name
    ), call. = FALSE)
  }

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

  # ---- Try xdelta3 patching first (if local .vtr exists + delta available) ----
  patched <- FALSE
  if (file.exists(vtr_path) && has_xdelta3()) {
    delta_url <- manifest_delta_url(backend_name, version)
    if (!is.null(delta_url)) {
      patched <- tryCatch(
        {
          if (verbose) message("  Trying xdelta3 patch...")
          delta_tmp <- tempfile(tmpdir = dest_dir, fileext = ".xdelta")
          on.exit(if (file.exists(delta_tmp)) unlink(delta_tmp), add = TRUE)
          curl::curl_download(delta_url, delta_tmp, quiet = !verbose)
          status <- system2("xdelta3", c("-d", "-s", vtr_path, delta_tmp,
                                         tmp_path))
          if (status == 0L) {
            if (verbose) {
              delta_mb <- file.size(delta_tmp) / 1048576
              message(sprintf("  Patched via xdelta3 (%.1f MB patch).", delta_mb))
            }
            TRUE
          } else {
            FALSE
          }
        },
        error = function(e) {
          if (verbose) message("  xdelta3 patch failed, falling back to full download.")
          FALSE
        }
      )
    }
  }

  # ---- Full download (if patching didn't work) ----
  if (!patched) {
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
        stop(sprintf("Failed to download %s backbone from:\n  %s\nError: %s",
                     backend_name, url, conditionMessage(e)),
             call. = FALSE)
      }
    )
  }

  # Atomic rename
  file.rename(tmp_path, vtr_path)

  # Clear any stale `.meta` sidecar. That file is a taxifydb build-from-source
  # artifact; a downloaded backbone is defined to carry none (its version lives
  # in the meta.json written below). If this slot was previously built from
  # source, the leftover `.meta` would shadow meta.json in
  # format_backbone_version() and report the old built version for the freshly
  # downloaded data.
  stale_meta <- paste0(tools::file_path_sans_ext(vtr_path), ".meta")
  if (file.exists(stale_meta)) unlink(stale_meta)

  # Download sidecar extras (e.g., col_species_profile.vtr) into the same
  # versioned directory. Each manifest entry under `extras` is
  # {name, url, size, sha256}. Failures here are non-fatal \u2014 the main
  # backbone is already in place; extras are optional enrichments.
  extras <- entry$extras
  if (!is.null(extras) && length(extras) > 0L) {
    for (ex in extras) {
      ex_name <- ex$name %||% basename(ex$url %||% "")
      ex_url  <- ex$url
      if (is.null(ex_name) || !nzchar(ex_name) || is.null(ex_url)) next
      ex_path <- file.path(dest_dir, ex_name)
      ex_tmp  <- tempfile(tmpdir = dest_dir, fileext = ".extra.tmp")
      tryCatch(
        {
          if (verbose) message(sprintf("  Downloading sidecar: %s", ex_name))
          if (startsWith(ex_url, "file://")) {
            local_src <- sub("^file:///", "/", ex_url)
            if (.Platform$OS.type == "windows" &&
                grepl("^/[A-Za-z]:/", local_src)) {
              local_src <- sub("^/", "", local_src)
            }
            if (!file.exists(local_src)) {
              stop(sprintf("Local sidecar not found: %s", local_src))
            }
            file.copy(local_src, ex_tmp, overwrite = TRUE)
          } else {
            curl::curl_download(ex_url, ex_tmp, quiet = !verbose)
          }
          file.rename(ex_tmp, ex_path)
        },
        error = function(e) {
          if (file.exists(ex_tmp)) unlink(ex_tmp)
          warning(sprintf("Failed to download sidecar '%s': %s",
                          ex_name, conditionMessage(e)),
                  call. = FALSE)
        }
      )
    }
  }

  write_version_meta(dest_dir, backend_name, actual_version,
                     pinned = (version != "latest"))

  if (verbose) {
    size_mb <- file.size(vtr_path) / 1048576
    message(sprintf("\u2713 %s backbone ready (v%s, %.0f MB).",
                    toupper(backend_name), actual_version, size_mb))
  }

  invisible(vtr_path)
}


#' Check if xdelta3 is available on PATH
#'
#' @return Logical.
#' @noRd
has_xdelta3 <- function() {
  tryCatch(
    {
      out <- system2("xdelta3", "-V", stdout = TRUE, stderr = TRUE)
      length(out) > 0L
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )
}


# ---- User-facing download function ----

#' Download a pre-built taxify backbone
#'
#' Downloads a pre-built `.vtr` backbone from GitHub Releases using the taxify
#' manifest. This needs no build tools and does not require `taxifydb`; it is the
#' fast path [taxify()] uses internally on first use. Call it directly to
#' pre-fetch backbones before an offline session. Progress is always shown; no
#' prompts are shown, so calling this function is consent.
#'
#' If no pre-built `.vtr` is available for a backend, it falls back to building
#' from source via [taxify_build()] (which requires `taxifydb`).
#'
#' @param backend Character. A backend name (e.g. `"wfo"`, `"col"`, `"gbif"`,
#'   ...; see the backends in [list_enrichments()]'s companion manifest) or
#'   `"register"` for the genus register. Multiple backends can be given as a
#'   character vector.
#' @param version Character. `"latest"` (default) downloads into
#'   `<data_dir>/<backend>/latest/` and will be overwritten on future updates.
#'   A specific version string (e.g., `"2024.01"`) downloads into a pinned
#'   folder that is never overwritten.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#' @seealso [taxify_build()] to build a backbone from source via `taxifydb`,
#'   [taxify_download_enrichment()] for enrichment layers.
#' @export
taxify_download <- function(backend = "wfo",
                            version = "latest",
                            verbose = TRUE) {
  paths <- vapply(backend, function(be) {
    # "register" is an alias for the published pair: the genus register and the
    # backbone-coverage table that accompanies it.
    if (identical(be, "register")) {
      ensure_coverage(verbose = verbose)
      reg <- ensure_register(verbose = verbose)
      if (is.null(reg)) {
        stop("Could not resolve the genus register.", call. = FALSE)
      }
      return(reg)
    }
    tryCatch(
      download_backbone(be, version = version, verbose = verbose),
      error = function(e) {
        if (verbose) {
          message(sprintf(
            "Pre-built .vtr not available for '%s'. Building from source...", be
          ))
        }
        taxify_build(be, verbose = verbose)
      }
    )
  }, character(1L))
  invisible(paths)
}


#' @rdname taxify_download
#' @export
taxify_download_vtr <- function(backend = "wfo",
                                version = "latest",
                                verbose = TRUE) {
  .Deprecated("taxify_download")
  taxify_download(backend = backend, version = version, verbose = verbose)
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
  if (taxify_offline()) return(invisible(NULL))
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

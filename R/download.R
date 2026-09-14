# ---- Download: manifest-driven backbone downloads ----
#
# taxify_download(backbone, version = "latest") is the user-facing function.
# It downloads the pre-built .vtr from Zenodo (via the manifest URL), writes
# a meta.json alongside it, and returns the path to the .vtr.
#
# The backbones still have their own taxify_build() S3 methods for the
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
#' @param backbone_name Character.
#' @param version Character.
#' @param pinned Logical. `FALSE` for the rolling "latest" slot.
#' @param content_id Character. md5 of the `.vtr`; hashed from the file when
#'   not supplied by a caller that already holds it.
#' @param install_path Character or `NULL`. How the bytes were obtained:
#'   `"patched"` (xdelta3 against the previous build) or `"full"` (the whole
#'   asset). Omitted from the file when `NULL`.
#' @noRd
write_version_meta <- function(dir, backbone_name, version, pinned = FALSE,
                               content_id = NULL, install_path = NULL) {
  vtr <- file.path(dir, paste0(backbone_name, ".vtr"))
  meta <- list(
    version      = version,
    pinned       = pinned,
    # md5 of the downloaded .vtr, so backbone_version_state() can detect a
    # same-tag republish offline (matches the manifest's content_id).
    content_id   = content_id %||% content_id_of(vtr),
    downloaded_at = format(Sys.Date(), "%Y-%m-%d"),
    install_path = install_path
  )
  path <- file.path(dir, "meta.json")
  jsonlite::write_json(meta, path, pretty = TRUE, auto_unbox = TRUE)
  invisible(path)
}


#' Read a meta.json from a versioned backbone directory
#'
#' @param backbone_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @return A named list with `version`, `pinned`, `downloaded_at`, or `NULL`
#'   if the file does not exist.
#' @noRd
read_version_meta <- function(backbone_name, version = "latest") {
  dir <- versioned_dir(backbone_name, version)
  path <- file.path(dir, "meta.json")
  if (!file.exists(path)) return(NULL)
  read_json_bom(path, simplifyVector = TRUE)
}


# ---- Path helpers ----

#' Return the versioned directory for a backbone
#'
#' @param backbone_name Character.
#' @param version Character.
#' @return Character path (not guaranteed to exist).
#' @noRd
versioned_dir <- function(backbone_name, version = "latest") {
  file.path(taxify_data_dir(), backbone_name, version)
}


#' Return the .vtr path for a backbone + version
#'
#' @param backbone_name Character.
#' @param version Character.
#' @return Character path (not guaranteed to exist).
#' @noRd
versioned_vtr_path <- function(backbone_name, version = "latest") {
  file.path(versioned_dir(backbone_name, version),
            paste0(backbone_name, ".vtr"))
}


# ---- Core download function ----

#' Download a backbone .vtr from Zenodo
#'
#' Downloads the `.vtr` into `<data_dir>/<backbone>/<version>/` atomically
#' (temp file -> rename). Writes `meta.json` on success. If the target file
#' already exists and `version` is not `"latest"` (i.e., a pinned version),
#' returns the existing path without re-downloading.
#'
#' @param backbone_name Character.
#' @param version Character. `"latest"` or a specific version string.
#' @param dest_dir Character. Target directory. Defaults to
#'   `versioned_dir(backbone_name, version)`.
#' @param verbose Logical.
#' @return Path to the downloaded `.vtr` (invisibly).
#' @noRd
download_backbone <- function(backbone_name,
                              version   = "latest",
                              dest_dir  = NULL,
                              verbose   = TRUE) {

  dest_dir <- dest_dir %||% versioned_dir(backbone_name, version)
  vtr_path <- file.path(dest_dir, paste0(backbone_name, ".vtr"))

  # Pinned versions: never overwrite if already present
  if (version != "latest" && file.exists(vtr_path)) {
    if (verbose) {
      message(sprintf("\u2713 %s backbone v%s already present (pinned). Skipping.",
                      toupper(backbone_name), version))
    }
    return(invisible(vtr_path))
  }

  # Resolve actual version string and download URL from manifest
  manifest <- fetch_manifest()
  entry <- resolve_manifest_entry(manifest, backbone_name)
  if (is.null(entry)) {
    stop(sprintf("Backend '%s' not found in manifest.", backbone_name),
         call. = FALSE)
  }
  actual_version <- if (version == "latest") entry$latest else version

  # Offline is checked against the manifest's own URL before a pinned version is
  # resolved: resolving one makes a HEAD request, which offline mode must not
  # reach.
  base_url <- entry$full_url %||% entry$url
  if (taxify_offline() &&
      !isTRUE(startsWith(base_url %||% "", "file://"))) {
    stop(sprintf(
      "taxify is in offline mode; not downloading the %s backbone.",
      backbone_name
    ), call. = FALSE)
  }
  url <- manifest_url(backbone_name, version)

  if (verbose) {
    local_ver <- if (!is.null(read_version_meta(backbone_name, version)))
      read_version_meta(backbone_name, version)$version
    else
      NULL
    if (!is.null(local_ver) && local_ver != actual_version) {
      message(sprintf(
        "\u2139 %s backbone outdated (local: %s, latest: %s). Downloading...",
        toupper(backbone_name), local_ver, actual_version
      ))
    } else if (is.null(local_ver)) {
      message(sprintf(
        "\u2139 %s backbone not found locally. Downloading v%s...",
        toupper(backbone_name), actual_version
      ))
    } else {
      message(sprintf(
        "\u2139 %s backbone is current (v%s). Re-downloading...",
        toupper(backbone_name), actual_version
      ))
    }
  }

  # The temp file lives one level up, in the asset's store root, so archiving
  # the build being replaced (which moves everything out of the version
  # directory) cannot sweep the download in progress along with it.
  store_root <- asset_store_root(backbone_name, "backbone")
  dir.create(store_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  tmp_path <- tempfile(tmpdir = store_root, fileext = ".vtr.tmp")
  on.exit(if (file.exists(tmp_path)) unlink(tmp_path), add = TRUE)

  # The manifest's content id describes the build `latest` serves; a pinned
  # version is a different build, which the manifest does not identify.
  expected_cid <- if (version == "latest") nz_or(entry$content_id, NULL)

  # ---- xdelta3 patch, only against the exact build the patch was cut from ----
  patch <- if (version == "latest") {
    try_backbone_patch(backbone_name, entry, vtr_path, dest_dir, tmp_path,
                       store_root, verbose = verbose)
  } else {
    list(patched = FALSE, note = NULL)
  }
  got_cid <- if (patch$patched) content_id_of(tmp_path)
  if (patch$patched && !is.null(expected_cid) &&
      !identical(as.character(got_cid), as.character(expected_cid))) {
    unlink(tmp_path)
    patch <- list(patched = FALSE, note = sprintf(
      "the patched file hashed to %s, not the manifest's %s",
      short_cid(got_cid), short_cid(expected_cid)))
  }

  # ---- Full download (if patching didn't work) ----
  if (!patch$patched) {
    fetch_asset_file(url, tmp_path,
                     sprintf("the %s backbone", backbone_name),
                     verbose = verbose)
    got_cid <- content_id_of(tmp_path)
    if (!is.null(expected_cid) &&
        !identical(as.character(got_cid), as.character(expected_cid))) {
      unlink(tmp_path)
      stop(sprintf(
        paste0("The downloaded %s backbone hashes to %s, not the content id ",
               "the manifest records (%s). Nothing was installed; the ",
               "previous build is untouched.\n  URL: %s"),
        toupper(backbone_name), got_cid, expected_cid, url), call. = FALSE)
    }
  }
  install_path <- if (patch$patched) "patched" else "full"

  # Keep the build being replaced, when the store is configured to (off by
  # default for backbones, which are gigabytes). This runs only once the new
  # bytes are safely in the temp file, so a failed download leaves the
  # installed backbone untouched.
  if (version == "latest" && keep_superseded_builds("backbone")) {
    archive_active_build(backbone_name, "backbone", verbose = verbose)
  }

  # Atomic rename
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  install_vtr_file(tmp_path, vtr_path)

  # Clear any stale `.meta` sidecar. That file is a taxifydb build-from-source
  # artifact; a downloaded backbone is defined to carry none (its version lives
  # in the meta.json written below). If this slot was previously built from
  # source, the leftover `.meta` would shadow meta.json in
  # format_backbone_version() and report the old built version for the freshly
  # downloaded data.
  stale_meta <- paste0(tools::file_path_sans_ext(vtr_path), ".meta")
  if (file.exists(stale_meta)) unlink(stale_meta)

  # Download sidecar extras (e.g., col_species_profile.vtr) into the same
  # versioned directory.
  download_asset_extras(entry, dest_dir, verbose = verbose)

  write_version_meta(dest_dir, backbone_name, actual_version,
                     pinned = (version != "latest"), content_id = got_cid,
                     install_path = install_path)

  # How the bytes were obtained is part of their provenance, so this is
  # reported whatever `verbose` says.
  message(sprintf(
    "\u2713 %s backbone ready (v%s, %.0f MB, %s)%s.",
    toupper(backbone_name), actual_version, file.size(vtr_path) / 1048576,
    if (patch$patched) "patched via xdelta3" else "full download",
    if (is.null(patch$note)) "" else paste0("; patch not used: ", patch$note)
  ))

  invisible(vtr_path)
}


#' First ten characters of a content id, for messages
#' @noRd
short_cid <- function(cid) {
  if (is.null(cid) || length(cid) != 1L || is.na(cid)) return("<none>")
  substr(cid, 1L, 10L)
}


#' Patch the local build of a backbone up to the manifest's build via xdelta3
#'
#' A patch reproduces the new build only from the exact bytes it was cut
#' against, which the manifest records as `delta_from_content_id`. The patch is
#' fetched only when the local build carries that id; a delta recorded without
#' one is not applied, because its `delta_from` release tag does not identify
#' the bytes (a re-cut reuses the tag). xdelta3's own output is captured, never
#' printed, and surfaces only in the returned note.
#'
#' @param backbone_name Character.
#' @param entry The resolved manifest entry.
#' @param vtr_path Character. The local build to patch from.
#' @param dir Character. Directory holding `vtr_path` and its `meta.json`.
#' @param tmp_path Character. Where the patched file is written.
#' @param store_root Character. Directory for the downloaded patch.
#' @param verbose Logical.
#' @return A list: `patched` (logical) and `note` (why no patch was used, or
#'   `NULL` when none was offered or it applied).
#' @noRd
try_backbone_patch <- function(backbone_name, entry, vtr_path, dir, tmp_path,
                               store_root, verbose = TRUE) {
  no_patch <- function(note = NULL) list(patched = FALSE, note = note)
  delta_url <- nz_or(entry$delta_url, NULL)
  if (is.null(delta_url) || !file.exists(vtr_path)) return(no_patch())

  base_cid <- nz_or(entry$delta_from_content_id, NULL)
  if (is.null(base_cid)) {
    return(no_patch("the manifest does not record which build it applies to"))
  }
  local_cid <- nz_or(read_store_meta(dir)$content_id, NULL) %||%
    content_id_of(vtr_path)
  if (!identical(as.character(local_cid), as.character(base_cid))) {
    return(no_patch(sprintf("it applies to build %s, the local build is %s",
                            short_cid(base_cid), short_cid(local_cid))))
  }
  if (!has_xdelta3()) return(no_patch("xdelta3 is not on PATH"))

  tryCatch(
    {
      if (verbose) message("  Applying xdelta3 patch...")
      delta_tmp <- tempfile(tmpdir = store_root, fileext = ".xdelta")
      on.exit(if (file.exists(delta_tmp)) unlink(delta_tmp), add = TRUE)
      fetch_asset_file(delta_url, delta_tmp,
                       sprintf("the %s backbone patch", backbone_name),
                       verbose = verbose)
      # system2() joins `args` into one command line, so every path is quoted
      # to survive a data directory containing a space.
      out <- suppressWarnings(system2(
        "xdelta3", c("-d", "-f", "-s", shQuote(vtr_path), shQuote(delta_tmp),
                     shQuote(tmp_path)),
        stdout = TRUE, stderr = TRUE))
      status <- attr(out, "status") %||% 0L
      if (status != 0L) {
        stop(sprintf("xdelta3 exited with status %s: %s", status,
                     paste(out, collapse = " ")), call. = FALSE)
      }
      list(patched = TRUE, note = NULL)
    },
    error = function(e) {
      if (file.exists(tmp_path)) unlink(tmp_path)
      no_patch(conditionMessage(e))
    }
  )
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
#' If no pre-built `.vtr` is available for a backbone, it falls back to building
#' from source via [taxify_build()] (which requires `taxifydb`).
#'
#' @param backbone Character. A backbone name (e.g. `"wfo"`, `"col"`, `"gbif"`,
#'   ...; see the backbones in [list_enrichments()]'s companion manifest) or
#'   `"register"` for the genus register. Multiple backbones can be given as a
#'   character vector.
#' @param version Character. `"latest"` (default) downloads into
#'   `<data_dir>/<backbone>/latest/` and will be overwritten on future updates.
#'   A specific version string (e.g., `"2024.01"`) downloads into a pinned
#'   folder that is never overwritten.
#' @param content_id Character or `NULL` (default). The content id of one exact
#'   build -- the md5 of its `.vtr`, as recorded by [taxify_lock()] and by the
#'   manifest. Given one, taxify fetches that build from the immutable copy
#'   published beside the rolling asset, verifies the bytes hash back to the id,
#'   and makes it the active backbone; the build it replaces is kept under its
#'   own content id. Pass one id per `backbone`, or one shared by all of them.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#' @seealso [taxify_build()] to build a backbone from source via `taxifydb`,
#'   [taxify_download_enrichment()] for enrichment layers, [taxify_store()] for
#'   the builds already on disk.
#' @export
taxify_download <- function(backbone = "wfo",
                            version = "latest",
                            content_id = NULL,
                            verbose = TRUE) {
  content_id <- recycle_content_ids(content_id, backbone, "backbone")
  paths <- vapply(seq_along(backbone), function(i) {
    be <- backbone[[i]]
    if (!is.null(content_id)) {
      return(download_content_build(be, content_id[[i]], "backbone",
                                    version = version, verbose = verbose))
    }
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
  names(paths) <- backbone
  invisible(paths)
}


#' Recycle a content_id argument over a vector of asset names
#'
#' A single id applies to a single asset, or to all of them when they are asked
#' for together; otherwise one id per name is required. Anything else is a
#' mistake worth stopping on -- silently pairing ids with the wrong assets would
#' install a build under another asset's pin.
#'
#' @param content_id Character or `NULL`.
#' @param names Character vector of asset names.
#' @param kind Character, for the error wording.
#' @return `NULL`, or a character vector the length of `names`.
#' @noRd
recycle_content_ids <- function(content_id, names, kind) {
  if (is.null(content_id)) return(NULL)
  content_id <- as.character(content_id)
  if (length(content_id) == length(names)) return(content_id)
  if (length(content_id) == 1L) return(rep(content_id, length(names)))
  stop(sprintf(
    "content_id must be one id, or one per %s (%d given for %d).",
    kind, length(content_id), length(names)
  ), call. = FALSE)
}


# ---- Once-per-session version check ----

#' Check all requested backbones and auto-download if outdated
#'
#' Called at the top of `taxify()`. Uses the session cache in `.taxify_env`
#' to run at most once per R session per backbone, regardless of how many
#' `taxify()` calls are made.
#'
#' @param backbones Character vector of backbone names.
#' @param verbose Logical.
#' @noRd
ensure_backbones_current <- function(backbones, verbose = TRUE) {
  if (taxify_offline()) return(invisible(NULL))
  for (bb_name in backbones) {
    if (isTRUE(.taxify_env[[paste0(".version_checked.", bb_name)]])) next
    refresh_backbone(bb_name, verbose = verbose)
  }
  invisible(NULL)
}


#' Bring one backbone up to the build the manifest serves
#'
#' Compares the active build against the manifest (`backbone_version_state()`)
#' and downloads the current release when the local one is behind or carries no
#' download record. A pinned build is left in place. Shared by the
#' once-per-session check in [taxify()] and by [install_backbones()], so both
#' decide by the same comparison.
#'
#' The backbone is marked as checked for the session before anything is
#' fetched, so a failed download is not retried on every later call.
#'
#' @param bb_name Character. Backbone name.
#' @param verbose Logical.
#' @return Invisibly, one of `"offline"` (nothing compared), `"current"`,
#'   `"pinned"`, `"refreshed"` (a new build was installed), or `"failed"` (the
#'   download failed with a warning, leaving the local build in use).
#' @noRd
refresh_backbone <- function(bb_name, verbose = TRUE) {
  if (taxify_offline()) return(invisible("offline"))
  .taxify_env[[paste0(".version_checked.", bb_name)]] <- TRUE

  state <- tryCatch(
    {
      s <- backbone_version_state(bb_name)
      if (s %in% c("stale", "missing")) {
        download_backbone(bb_name, version = "latest", verbose = verbose)
        set_backbone_path(bb_name, NULL)
        s <- "refreshed"
      }
      s
    },
    error = function(e) {
      warning(
        sprintf(
          "Could not update %s backbone: %s\nUsing existing local version.",
          bb_name, conditionMessage(e)
        ),
        call. = FALSE
      )
      "failed"
    }
  )
  invisible(state)
}

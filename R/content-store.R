# ---- Content-addressed asset store ----
#
# A build's identity is the md5 of its `.vtr` (`content_id`), the same string
# `taxify_lock()` records. The manifest carries it beside the rolling
# `full_url`, and beside an immutable `content_url` naming that exact build at
# `<tag>/<name>-<content_id>.vtr`. This file turns a recorded id back into
# bytes: it resolves the URL for one build, fetches and verifies it, and keeps
# every build the user has held in a content-keyed directory beside the active
# one, so a refetch adds a directory instead of replacing one.
#
# Disk layout (enrichments; backbones use the same shape without the
# `enrichment/` level):
#
#   taxify_data_dir()/enrichment/<name>/
#     latest/<name>.vtr + meta.json          the active build
#     <content_id>/<name>.vtr + meta.json    a build kept for reference
#
# A build is moved between the two, never copied, so one copy of each distinct
# build exists on disk. `<content_id>` is a 32-character md5 hex string and so
# can never collide with a `YYYY.MM` version label sharing the directory.


#' Directory holding one build of an asset
#'
#' @param name Character. Backbone or enrichment identifier.
#' @param key Character. `"latest"`, a version label, or a content id.
#' @param kind Character. `"enrichment"` or `"backbone"`.
#' @return Character path (not guaranteed to exist).
#' @noRd
asset_dir <- function(name, key = "latest", kind = c("enrichment", "backbone")) {
  kind <- match.arg(kind)
  if (kind == "enrichment") enrichment_dir(name, key) else versioned_dir(name, key)
}


#' Path to the `.vtr` of one build of an asset
#' @noRd
asset_vtr_path <- function(name, key = "latest",
                           kind = c("enrichment", "backbone")) {
  file.path(asset_dir(name, key, match.arg(kind)), paste0(name, ".vtr"))
}


#' Directory holding every build of an asset
#' @noRd
asset_store_root <- function(name, kind = c("enrichment", "backbone")) {
  dirname(asset_dir(name, "latest", match.arg(kind)))
}


#' Is a store key a content id rather than a version label?
#'
#' A content id is the 32-character lowercase md5 hex of the `.vtr`; a version
#' label is a build target like `2026.08`. The two share the store, and this is
#' what tells them apart.
#'
#' @param key Character.
#' @return Logical scalar.
#' @noRd
is_content_key <- function(key) {
  is.character(key) && length(key) == 1L && !is.na(key) &&
    grepl("^[0-9a-f]{32}$", key)
}


#' Resolve the manifest entry for an asset of either kind
#'
#' Falls back to the bundled manifest for a key the fetched one does not carry
#' (the hosted manifest lags a release that adds an asset), matching
#' `resolve_manifest_entry()`.
#'
#' @noRd
asset_manifest_entry <- function(name, kind = c("enrichment", "backbone"),
                                 manifest = NULL) {
  kind <- match.arg(kind)
  manifest <- manifest %||% fetch_manifest()
  if (kind == "backbone") return(resolve_manifest_entry(manifest, name))
  entry <- resolve_enrichment_entry(manifest, name)
  if (!is.null(entry)) return(entry)
  tryCatch(resolve_enrichment_entry(local_manifest(), name),
           error = function(e) NULL)
}


#' URL of one exact build of an asset
#'
#' Prefers the manifest's recorded `content_url`, which names the immutable
#' copy uploaded beside the rolling `<name>.vtr`. When the manifest records no
#' `content_url`, or records one for a different build than the id asked for,
#' the URL is derived from the rolling one: the immutable copy lives in the
#' same release tag under `<name>-<content_id>.vtr`. Deriving it here is what
#' spares the caller from knowing the convention.
#'
#' @param entry The resolved manifest entry.
#' @param name Character. Asset identifier.
#' @param content_id Character. 32-character md5 hex.
#' @return Character URL, or `NULL` when the entry carries no URL at all.
#' @noRd
content_asset_url <- function(entry, name, content_id) {
  if (is.null(entry)) return(NULL)
  # A recorded content_url describes the build the entry's content_id names, so
  # it applies only when that is the build being asked for. Any other id is an
  # earlier build of the same asset, whose immutable copy is derived below.
  cu <- entry$content_url
  if (!is.null(cu) && length(cu) == 1L && nzchar(cu) &&
      identical(as.character(entry$content_id), as.character(content_id))) {
    return(cu)
  }
  base <- entry$full_url %||% entry$url
  if (is.null(base) || length(base) != 1L || !nzchar(base)) return(NULL)
  paste0(sub("[^/]+$", "", base), sprintf("%s-%s.vtr", name, content_id))
}


#' Read the meta.json of one build, tolerating its absence
#' @noRd
read_store_meta <- function(dir) {
  path <- file.path(dir, "meta.json")
  if (!file.exists(path)) return(NULL)
  tryCatch(read_json_bom(path, simplifyVector = TRUE), error = function(e) NULL)
}


#' Write a meta.json for one build
#' @noRd
write_store_meta <- function(dir, meta) {
  path <- file.path(dir, "meta.json")
  tryCatch(
    jsonlite::write_json(meta, path, pretty = TRUE, auto_unbox = TRUE),
    error = function(e) NULL
  )
  invisible(path)
}


#' Find a build already on disk by its content id
#'
#' Checks the content-keyed directory first, then any sibling build (including
#' the active one) whose `meta.json` records that id. Files are not hashed:
#' rehashing a multi-GB backbone on every lookup is what the recorded id
#' exists to avoid.
#'
#' @return Character path to the `.vtr`, or `NULL`.
#' @noRd
local_content_path <- function(name, content_id,
                               kind = c("enrichment", "backbone")) {
  kind <- match.arg(kind)
  if (!is_content_key(content_id)) return(NULL)

  direct <- asset_vtr_path(name, content_id, kind)
  if (file.exists(direct)) return(direct)

  root <- asset_store_root(name, kind)
  if (!dir.exists(root)) return(NULL)
  for (d in list.dirs(root, recursive = FALSE)) {
    p <- file.path(d, paste0(name, ".vtr"))
    if (!file.exists(p)) next
    cid <- nz_or(read_store_meta(d)$content_id, NA_character_)
    if (identical(as.character(cid), content_id)) return(p)
  }
  NULL
}


#' Should a routine refresh keep the build it replaces?
#'
#' Enrichments keep it: they are megabytes, and a re-cut under an unchanged tag
#' is exactly what destroyed a locked build before. Backbones do not: a routine
#' GBIF refresh would otherwise hold several gigabytes of superseded backbone
#' forever. Both are overridable, and the restore path archives regardless of
#' either -- activating a pinned build must never destroy the current one.
#'
#' @noRd
keep_superseded_builds <- function(kind = c("enrichment", "backbone")) {
  kind <- match.arg(kind)
  if (kind == "enrichment") {
    isTRUE(getOption("taxify.keep_enrichment_versions", TRUE))
  } else {
    isTRUE(getOption("taxify.keep_backbone_versions", FALSE))
  }
}


#' Move the active build into its content-keyed directory
#'
#' Called before the active slot is overwritten. Everything in the directory
#' travels with the build -- `meta.json`, a `.meta` sidecar, downloaded extras
#' -- so the archived copy is as usable as the active one was. The move is a
#' rename, so archiving costs no disk.
#'
#' @param name Character.
#' @param kind Character.
#' @return The archive directory (invisibly), or `NULL` when nothing was
#'   archived (no active build, an unresolvable id, or an archive already
#'   holding a build of that id).
#' @noRd
archive_active_build <- function(name, kind = c("enrichment", "backbone"),
                                 verbose = FALSE) {
  kind <- match.arg(kind)
  # The example database is a read-only fixture set inside the package
  # installation; never restructure it.
  if (is_example_data_dir()) return(invisible(NULL))

  act_dir <- asset_dir(name, "latest", kind)
  vtr <- file.path(act_dir, paste0(name, ".vtr"))
  if (!file.exists(vtr)) return(invisible(NULL))

  meta <- read_store_meta(act_dir)
  cid <- nz_or(meta$content_id, NA_character_)
  if (is.na(cid) || !nzchar(cid)) cid <- content_id_of(vtr)
  if (is.na(cid) || !is_content_key(cid)) return(invisible(NULL))

  arc_dir <- asset_dir(name, cid, kind)
  arc_vtr <- file.path(arc_dir, paste0(name, ".vtr"))

  # The store already holds this build. The active copy is redundant, so drop
  # it -- but only after confirming the archived file is the same size, so a
  # mismatched archive is left alone rather than trusted.
  if (file.exists(arc_vtr)) {
    if (isTRUE(file.size(arc_vtr) == file.size(vtr))) {
      unlink(list.files(act_dir, full.names = TRUE))
      return(invisible(arc_dir))
    }
    return(invisible(NULL))
  }

  dir.create(arc_dir, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(act_dir, all.files = FALSE, no.. = TRUE, full.names = TRUE)
  ok <- TRUE
  for (f in files) {
    target <- file.path(arc_dir, basename(f))
    moved <- suppressWarnings(file.rename(f, target))
    if (!moved) {
      moved <- file.copy(f, target, overwrite = TRUE)
      if (moved) unlink(f)
    }
    ok <- ok && moved
  }
  if (!ok) {
    warning(sprintf("Could not fully archive the installed '%s' build.", name),
            call. = FALSE)
  }

  # A build kept for reference is pinned: nothing refreshes it in place.
  meta <- read_store_meta(arc_dir) %||% list()
  meta$content_id <- cid
  meta$pinned <- TRUE
  write_store_meta(arc_dir, meta)

  if (verbose) {
    message(sprintf("  Kept the superseded build as %s.", substr(cid, 1L, 10L)))
  }
  invisible(arc_dir)
}


#' Make a build held in the store the active one
#'
#' Swaps the content-keyed directory into the active slot, archiving whatever
#' was active first, so the two builds trade places without either being lost.
#' The activated build's `meta.json` is marked pinned, which is what stops the
#' next session's version check from refreshing the restored build away.
#'
#' @return Path to the now-active `.vtr` (invisibly).
#' @noRd
activate_content_build <- function(name, content_id,
                                   kind = c("enrichment", "backbone"),
                                   verbose = TRUE) {
  kind <- match.arg(kind)
  src <- local_content_path(name, content_id, kind)
  if (is.null(src)) {
    stop(sprintf("No build of '%s' with content id %s is on disk.",
                 name, content_id), call. = FALSE)
  }
  src_dir <- dirname(src)
  act_dir <- asset_dir(name, "latest", kind)

  same <- isTRUE(tryCatch(
    normalizePath(src_dir, mustWork = FALSE) ==
      normalizePath(act_dir, mustWork = FALSE),
    error = function(e) FALSE
  ))

  if (!same) {
    archive_active_build(name, kind, verbose = verbose)
    dir.create(act_dir, recursive = TRUE, showWarnings = FALSE)
    for (f in list.files(src_dir, all.files = FALSE, no.. = TRUE,
                         full.names = TRUE)) {
      target <- file.path(act_dir, basename(f))
      moved <- suppressWarnings(file.rename(f, target))
      if (!moved) {
        moved <- file.copy(f, target, overwrite = TRUE)
        if (moved) unlink(f)
      }
      if (!moved) {
        stop(sprintf("Could not move build %s of '%s' into the active slot.",
                     substr(content_id, 1L, 10L), name), call. = FALSE)
      }
    }
    unlink(src_dir, recursive = TRUE)
  }

  meta <- read_store_meta(act_dir) %||% list()
  meta$content_id <- content_id
  meta$pinned <- TRUE
  write_store_meta(act_dir, meta)

  invalidate_asset_cache(name, kind)

  if (verbose) {
    message(sprintf("\u2713 %s '%s' pinned to build %s.",
                    if (kind == "backbone") "Backbone" else "Enrichment",
                    name, substr(content_id, 1L, 10L)))
  }
  invisible(file.path(act_dir, paste0(name, ".vtr")))
}


#' Drop an asset's cached path and its once-per-session version flag
#'
#' Both kinds cache a path under a key in `.taxify_cache` and a checked flag in
#' `.taxify_env`; changing which build is active has to clear both, or the
#' session keeps reading the build it resolved earlier.
#'
#' @noRd
invalidate_asset_cache <- function(name, kind = c("enrichment", "backbone")) {
  kind <- match.arg(kind)
  if (kind == "enrichment") {
    set_backbone_path(paste0("enrichment_", name), NULL)
    .taxify_env[[paste0(".enrichment_version_checked.", name)]] <- TRUE
  } else {
    set_backbone_path(name, NULL)
    .taxify_env[[paste0(".version_checked.", name)]] <- TRUE
  }
  invisible(NULL)
}


#' Fetch one file into a temporary path, from the network or a file:// URL
#'
#' The single fetch used by the backbone, enrichment and content-pinned
#' download paths, so the `file://` handling (including the Windows drive-letter
#' form) and the error wording live in one place.
#'
#' @param url Character.
#' @param tmp_path Character. Where to write.
#' @param label Character. What to name in an error ("the WFO backbone").
#' @param verbose Logical.
#' @return `TRUE` invisibly; stops on failure.
#' @noRd
fetch_asset_file <- function(url, tmp_path, label, verbose = TRUE) {
  tryCatch(
    {
      if (startsWith(url, "file://")) {
        local_src <- sub("^file:///", "/", url)
        if (.Platform$OS.type == "windows" && grepl("^/[A-Za-z]:/", local_src)) {
          local_src <- sub("^/", "", local_src)
        }
        if (!file.exists(local_src)) {
          stop(sprintf("Local file not found: %s", local_src))
        }
        file.copy(local_src, tmp_path, overwrite = TRUE)
      } else {
        h <- curl::new_handle()
        curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
        curl::curl_download(url, tmp_path, handle = h, quiet = !verbose)
      }
    },
    error = function(e) {
      stop(sprintf("Failed to download %s from:\n  %s\nError: %s",
                   label, url, conditionMessage(e)), call. = FALSE)
    }
  )
  invisible(TRUE)
}


#' Download the sidecar extras a manifest entry lists
#'
#' Each `extras` element is `{name, url, size, sha256}`. Failures are
#' non-fatal: the asset itself is already in place and extras are optional.
#' Extras carry no content id of their own, so a content-pinned fetch takes the
#' current release's copies.
#'
#' @noRd
download_asset_extras <- function(entry, dest_dir, verbose = TRUE) {
  extras <- entry$extras
  if (is.null(extras) || length(extras) == 0L) return(invisible(NULL))
  for (ex in extras) {
    ex_name <- ex$name %||% basename(ex$url %||% "")
    ex_url  <- ex$url
    if (is.null(ex_name) || !nzchar(ex_name) || is.null(ex_url)) next
    ex_path <- file.path(dest_dir, ex_name)
    ex_tmp  <- tempfile(tmpdir = dest_dir, fileext = ".extra.tmp")
    tryCatch(
      {
        if (verbose) message(sprintf("  Downloading sidecar: %s", ex_name))
        fetch_asset_file(ex_url, ex_tmp, sprintf("sidecar '%s'", ex_name),
                         verbose = verbose)
        file.rename(ex_tmp, ex_path)
      },
      error = function(e) {
        if (file.exists(ex_tmp)) unlink(ex_tmp)
        warning(sprintf("Failed to download sidecar '%s': %s",
                        ex_name, conditionMessage(e)), call. = FALSE)
      }
    )
  }
  invisible(NULL)
}


#' Version label to record for a content-pinned build
#'
#' The manifest's `latest` applies only when it names the build being fetched.
#' Otherwise an explicitly requested label is used, and failing that the label
#' is left unrecorded -- recording a label that does not describe the bytes is
#' the confusion content ids exist to end.
#'
#' @noRd
pinned_version_label <- function(entry, content_id, version) {
  if (identical(as.character(entry$content_id), as.character(content_id))) {
    return(entry$latest %||% NA_character_)
  }
  if (!is.null(version) && !identical(version, "latest") && nzchar(version)) {
    return(version)
  }
  NA_character_
}


#' Download one exact build of an asset by its content id
#'
#' Resolves the immutable URL for `content_id`, fetches it, and verifies the
#' bytes hash back to the id asked for before installing them. A build already
#' on disk is reused rather than refetched.
#'
#' @param name Character. Backbone or enrichment identifier.
#' @param content_id Character. 32-character md5 hex, as recorded by
#'   [taxify_lock()] or the manifest.
#' @param kind Character. `"enrichment"` or `"backbone"`.
#' @param version Character or `NULL`. A version label to record alongside the
#'   build when the manifest's own entry describes a different one.
#' @param activate Logical. `TRUE` (default) makes the build the active one,
#'   archiving whatever was active. `FALSE` parks it in its content-keyed
#'   directory and leaves the active build alone.
#' @param verbose Logical.
#' @return Path to the installed `.vtr` (invisibly).
#' @noRd
download_content_build <- function(name, content_id,
                                   kind = c("enrichment", "backbone"),
                                   version = NULL,
                                   activate = TRUE,
                                   verbose = TRUE) {
  kind <- match.arg(kind)
  if (!is_content_key(content_id)) {
    stop(sprintf(
      "content_id must be a 32-character md5 hex string; got '%s'.",
      paste(content_id, collapse = ", ")
    ), call. = FALSE)
  }

  # Already held: activating or returning it costs no download.
  local <- local_content_path(name, content_id, kind)
  if (!is.null(local)) {
    if (verbose) {
      message(sprintf("\u2713 Build %s of '%s' is already on disk.",
                      substr(content_id, 1L, 10L), name))
    }
    if (activate) return(invisible(activate_content_build(name, content_id, kind,
                                                          verbose = verbose)))
    return(invisible(local))
  }

  entry <- asset_manifest_entry(name, kind)
  if (is.null(entry)) {
    stop(sprintf("%s '%s' not found in manifest.",
                 if (kind == "backbone") "Backend" else "Enrichment", name),
         call. = FALSE)
  }
  url <- content_asset_url(entry, name, content_id)
  if (is.null(url)) {
    stop(sprintf("Manifest entry for '%s' carries no download URL.", name),
         call. = FALSE)
  }
  if (taxify_offline() && !startsWith(url, "file://")) {
    stop(sprintf("taxify is in offline mode; not downloading '%s'.", name),
         call. = FALSE)
  }

  if (verbose) {
    message(sprintf("\u2139 Fetching build %s of '%s'...",
                    substr(content_id, 1L, 10L), name))
  }

  root <- asset_store_root(name, kind)
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  tmp_path <- tempfile(tmpdir = root, fileext = ".vtr.tmp")
  on.exit(if (file.exists(tmp_path)) unlink(tmp_path), add = TRUE)

  tryCatch(
    fetch_asset_file(url, tmp_path, sprintf("build %s of '%s'",
                                            substr(content_id, 1L, 10L), name),
                     verbose = verbose),
    error = function(e) {
      stop(sprintf(
        paste0("%s\n",
               "No asset for content id %s is published at that URL. Builds ",
               "published before taxifydb recorded a content_url kept only ",
               "the rolling copy, which a later re-cut replaced in place; ",
               "such a build cannot be recovered."),
        conditionMessage(e), content_id
      ), call. = FALSE)
    }
  )

  got <- content_id_of(tmp_path)
  if (!identical(as.character(got), content_id)) {
    unlink(tmp_path)
    stop(sprintf(
      paste0("Downloaded bytes for '%s' hash to %s, not the requested %s. ",
             "The asset at that URL is not the build asked for."),
      name, got, content_id
    ), call. = FALSE)
  }

  dest_dir <- asset_dir(name, content_id, kind)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  vtr_path <- file.path(dest_dir, paste0(name, ".vtr"))
  file.rename(tmp_path, vtr_path)

  ver <- pinned_version_label(entry, content_id, version)
  meta <- if (kind == "enrichment") {
    build_enrichment_meta(entry, ver, pinned = TRUE, vtr_path)
  } else {
    list(version = ver, pinned = TRUE, content_id = content_id,
         downloaded_at = format(Sys.Date(), "%Y-%m-%d"))
  }
  # No label describes these bytes: leave the field out rather than record one
  # that belongs to a different build.
  if (is.na(ver)) meta$version <- NULL
  write_store_meta(dest_dir, meta)

  if (kind == "backbone") download_asset_extras(entry, dest_dir, verbose = verbose)

  if (verbose) {
    message(sprintf("\u2713 Build %s of '%s' ready (%.1f MB).",
                    substr(content_id, 1L, 10L), name,
                    file.size(vtr_path) / 1048576))
  }

  if (activate) {
    return(invisible(activate_content_build(name, content_id, kind,
                                            verbose = verbose)))
  }
  invisible(vtr_path)
}


#' Builds of a taxify asset held on disk
#'
#' taxify keeps every build it has downloaded of an enrichment: the active one
#' under `latest/`, and each build it replaced in a directory named for that
#' build's content id (the md5 of its `.vtr`, the same string [taxify_lock()]
#' records). Backbones are listed the same way, though by default only the
#' active build of a backbone is kept -- see `taxify.keep_backbone_versions`
#' below.
#'
#' Use this to see which pinned builds a lockfile could be restored to without
#' a download.
#'
#' @param asset Character. One or more backbone or enrichment names to list.
#'   `NULL` (default) lists every asset in the data directory.
#'
#' @return A data.frame with one row per build on disk, columns: `component`,
#'   `type` (`"backbone"`/`"enrichment"`), `slot` (the store directory --
#'   `"latest"` for the active build, else its content id), `active`,
#'   `version`, `content_id`, `pinned`, `size_mb`, `downloaded_at`.
#'
#' @section Options:
#' `taxify.keep_enrichment_versions` (default `TRUE`) keeps the build an
#' enrichment refresh replaces; `taxify.keep_backbone_versions` (default
#' `FALSE`) does the same for backbones, off because a superseded backbone is
#' gigabytes. Restoring a pinned build archives the build it replaces either
#' way.
#'
#' @seealso [taxify_lock()] to record a build, [taxify_restore()] to check or
#'   reinstall one, [taxify_download_enrichment()] to fetch one by content id.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#' head(taxify_store())
#' options(old)
#'
#' @export
taxify_store <- function(asset = NULL) {
  dd <- taxify_data_dir()
  rows <- list()

  scan_one <- function(name, kind) {
    root <- asset_store_root(name, kind)
    if (!dir.exists(root)) return(invisible(NULL))
    for (d in list.dirs(root, recursive = FALSE)) {
      vtr <- file.path(d, paste0(name, ".vtr"))
      if (!file.exists(vtr)) next
      meta <- read_store_meta(d)
      rows[[length(rows) + 1L]] <<- data.frame(
        component     = name,
        type          = kind,
        slot          = basename(d),
        active        = identical(basename(d), "latest"),
        version       = nz_or(meta$version, NA_character_),
        content_id    = nz_or(meta$content_id, NA_character_),
        pinned        = isTRUE(nz_or(meta$pinned, FALSE)),
        size_mb       = round(file.size(vtr) / 1048576, 1),
        downloaded_at = nz_or(meta$downloaded_at, NA_character_),
        stringsAsFactors = FALSE
      )
    }
    invisible(NULL)
  }

  bb_names <- if (dir.exists(dd)) {
    setdiff(basename(list.dirs(dd, recursive = FALSE)), "enrichment")
  } else character(0L)
  en_root <- file.path(dd, "enrichment")
  en_names <- if (dir.exists(en_root)) {
    basename(list.dirs(en_root, recursive = FALSE))
  } else character(0L)

  if (!is.null(asset)) {
    bb_names <- intersect(bb_names, asset)
    en_names <- intersect(en_names, asset)
  }

  for (nm in bb_names) scan_one(nm, "backbone")
  for (nm in en_names) scan_one(nm, "enrichment")

  out <- if (length(rows)) do.call(rbind, rows) else data.frame(
    component = character(0L), type = character(0L), slot = character(0L),
    active = logical(0L), version = character(0L), content_id = character(0L),
    pinned = logical(0L), size_mb = numeric(0L),
    downloaded_at = character(0L), stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out
}

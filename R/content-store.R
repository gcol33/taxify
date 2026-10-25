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
#' No, for either kind: a refresh replaces the build in place, so the data
#' directory holds one build per asset. A lockfile that pinned the replaced
#' build still restores it, because every build is published under its content
#' id and [download_content_build()] fetches it back by that id. Both are
#' overridable, and the restore path archives regardless of either --
#' activating a pinned build must never destroy the current one.
#'
#' @noRd
keep_superseded_builds <- function(kind = c("enrichment", "backbone")) {
  kind <- match.arg(kind)
  if (kind == "enrichment") {
    isTRUE(getOption("taxify.keep_enrichment_versions", FALSE))
  } else {
    isTRUE(getOption("taxify.keep_backbone_versions", FALSE))
  }
}


#' Index sidecars of a store
#'
#' vectra keeps a hash index of a column beside the store as
#' `<store>.<column>.vtri`. Matched by prefix rather than by glob, so a data
#' directory holding glob metacharacters still resolves.
#'
#' @param vtr_path Character. Path to a `.vtr`.
#' @return Character vector of index paths (possibly empty).
#' @noRd
vtr_index_files <- function(vtr_path) {
  dir <- dirname(vtr_path)
  if (!dir.exists(dir)) return(character(0L))
  files <- list.files(dir, all.files = TRUE, no.. = TRUE)
  keep <- startsWith(files, paste0(basename(vtr_path), ".")) &
    endsWith(files, ".vtri")
  file.path(dir, files[keep])
}


#' Put a new `.vtr` at its installed path, without the replaced file's indexes
#'
#' An index is stamped with the shape of the store it was built for (row count,
#' row-group count, column position), not its content, so vectra accepts one
#' left behind by a replaced store of the same shape and prunes row groups by
#' the old keys, dropping matching rows without an error (gcol33/vectra#13).
#' The published assets carry no index, so every install path removes the
#' indexes of whatever file it replaces before the new bytes take its place.
#' Every place a taxify asset is installed goes through here.
#'
#' @param tmp_path Character. The new file, already verified.
#' @param vtr_path Character. Where it is installed.
#' @return `vtr_path`, invisibly; stops when the file cannot be moved there.
#' @noRd
install_vtr_file <- function(tmp_path, vtr_path) {
  drop_vtr_indexes(vtr_path)
  if (!isTRUE(file.rename(tmp_path, vtr_path))) {
    stop(sprintf("Could not move the downloaded file into place at %s.",
                 vtr_path), call. = FALSE)
  }
  invisible(vtr_path)
}


#' Remove the index sidecars of a store
#' @noRd
drop_vtr_indexes <- function(vtr_path) {
  idx <- vtr_index_files(vtr_path)
  if (length(idx)) unlink(idx)
  invisible(idx)
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
    # Archiving normally empties the slot, but it leaves the active files in
    # place when it cannot resolve or move them; their indexes must not end up
    # beside the store being activated.
    for (v in list.files(src_dir, pattern = "[.]vtr$")) {
      drop_vtr_indexes(file.path(act_dir, v))
    }
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


#' Downloads an earlier session left behind
#'
#' A download writes `<random>.vtr.tmp` in the asset's store root (a reference
#' table `<random>.refs.tmp` in the version directory), and curl
#' streams into `<that>.curltmp` beside it until the transfer completes. An
#' interrupted or killed session leaves both behind, each up to the size of the
#' asset. A file not written to for an hour belongs to no transfer still in
#' progress, so a concurrent download in another session is never touched.
#' Older taxify versions wrote the temp file inside the version directory, so
#' those are scanned too.
#'
#' @param root Character. An asset's store root.
#' @return Character vector of paths.
#' @noRd
stale_download_files <- function(root) {
  if (!dir.exists(root)) return(character(0L))
  dirs <- c(root, list.dirs(root, recursive = FALSE))
  f <- unlist(lapply(dirs, list.files, pattern = "[.](tmp|curltmp)$",
                     full.names = TRUE), use.names = FALSE)
  if (!length(f)) return(character(0L))
  age <- difftime(Sys.time(), file.mtime(f), units = "hours")
  f[!is.na(age) & age > 1]
}


#' A temp path for a download into an asset's store root
#'
#' Clears what interrupted downloads left in the same root first, so a failed
#' transfer costs disk only until the next attempt.
#'
#' @param root Character. The asset's store root (created if missing).
#' @return Character path. Callers remove it, and its `.curltmp` companion,
#'   with [unlink_download()] on exit.
#' @noRd
asset_tmp_path <- function(root) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  unlink(stale_download_files(root))
  tempfile(tmpdir = root, fileext = ".vtr.tmp")
}


#' Remove a download's temp file and curl's partial-transfer companion
#' @noRd
unlink_download <- function(tmp_path) {
  unlink(c(tmp_path, paste0(tmp_path, ".curltmp")))
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


#' Is an asset published at this URL?
#'
#' A HEAD request, so a pinned version that was never released is caught before
#' anything is written to the store. Any failure (offline, DNS, a proxy that
#' rejects HEAD) reads as absent, which is also how the download itself would
#' end.
#'
#' @param url Character.
#' @return Logical.
#' @noRd
asset_url_exists <- function(url) {
  if (is.null(url) || length(url) != 1L || is.na(url) || !nzchar(url)) {
    return(FALSE)
  }
  if (startsWith(url, "file://")) {
    local_src <- sub("^file:///", "/", url)
    if (.Platform$OS.type == "windows" && grepl("^/[A-Za-z]:/", local_src)) {
      local_src <- sub("^/", "", local_src)
    }
    return(file.exists(local_src))
  }
  tryCatch(
    {
      h <- curl::new_handle(nobody = TRUE)
      curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
      isTRUE(curl::curl_fetch_memory(url, handle = h)$status_code < 400L)
    },
    error = function(e) FALSE
  )
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
    ex_name <- ex$name %||% local_asset_name(ex$url %||% "")
    ex_url  <- ex$url
    if (is.null(ex_name) || !nzchar(ex_name) || is.null(ex_url)) next
    ex_path <- file.path(dest_dir, ex_name)
    ex_tmp  <- tempfile(tmpdir = dest_dir, fileext = ".extra.tmp")
    tryCatch(
      {
        if (verbose) message(sprintf("  Downloading sidecar: %s", ex_name))
        fetch_asset_file(ex_url, ex_tmp, sprintf("sidecar '%s'", ex_name),
                         verbose = verbose)
        install_vtr_file(ex_tmp, ex_path)
      },
      error = function(e) {
        unlink_download(ex_tmp)
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

  tmp_path <- asset_tmp_path(asset_store_root(name, kind))
  on.exit(unlink_download(tmp_path), add = TRUE)

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
  install_vtr_file(tmp_path, vtr_path)

  ver <- pinned_version_label(entry, content_id, version)
  meta <- if (kind == "enrichment") {
    m <- build_enrichment_meta(entry, ver, pinned = TRUE, vtr_path)
    # The entry's reference table belongs to the build the entry names; an older
    # build restored by content id keeps whatever provenance it was built with.
    if (identical(entry$content_id, content_id) && !is.null(m$references)) {
      download_enrichment_references(entry, dest_dir, verbose = verbose)
    } else {
      m$references <- NULL
    }
    m
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
#' Lists each backbone and enrichment build in the data directory: the active
#' one under `latest/`, and any other build in a directory named for its
#' content id (the md5 of its `.vtr`, the same string [taxify_lock()] records).
#' By default a refresh replaces a build in place, so an asset has one build;
#' the others come from restoring a pinned build or from the
#' `taxify.keep_*_versions` options below. [taxify_clean()] removes them.
#'
#' Use this to see which pinned builds a lockfile could be restored to without
#' a download, and how much disk each asset takes.
#'
#' @param asset Character. One or more backbone or enrichment names to list.
#'   `NULL` (default) lists every asset in the data directory.
#'
#' @return A data.frame with one row per build on disk, columns: `component`,
#'   `type` (`"backbone"`/`"enrichment"`), `slot` (the store directory:
#'   `"latest"` for the active build, else its content id), `active`,
#'   `version`, `content_id`, `pinned`, `size_mb`, `downloaded_at`.
#'
#' @section Options:
#' `taxify.keep_enrichment_versions` and `taxify.keep_backbone_versions` (both
#' default `FALSE`) keep the build a refresh replaces, under its content id.
#' Restoring a pinned build archives the build it replaces either way.
#'
#' @seealso [taxify_lock()] to record a build, [taxify_restore()] to check or
#'   reinstall one, [taxify_download_enrichment()] to fetch one by content id,
#'   [taxify_clean()] to remove builds.
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


#' Remove downloaded taxify data
#'
#' Frees disk space in the data directory ([taxify_data_dir()]). Called with no
#' arguments it removes what taxify no longer reads: builds replaced by a newer
#' one or kept by version, and files left by an interrupted download. The
#' active build of every backbone and enrichment stays. Name assets to remove
#' them completely, or pass `"all"` to delete the data directory.
#'
#' A removed backbone or enrichment downloads again when it is next installed;
#' a lockfile pin is restored by [taxify_restore()] from the published copy of
#' that build.
#'
#' @param assets `NULL` (default) for superseded builds and interrupted
#'   downloads, a character vector of backbone or enrichment names to remove
#'   completely, or `"all"` for the whole data directory.
#' @param dry_run Logical. List what would be removed, without removing it.
#' @param verbose Logical. Report the space freed.
#'
#' @return Invisibly, a data.frame with one row per path removed (or, with
#'   `dry_run = TRUE`, that would be removed): `component`, `type`
#'   (`"backbone"`/`"enrichment"`/`"directory"`), `reason` (`"superseded"`,
#'   `"interrupted"`, `"removed"`), `size_mb` and `path`.
#'
#' @seealso [taxify_store()] for the builds on disk, [install_backbones()].
#'
#' @examples
#' old <- options(taxify.data_dir = file.path(tempdir(), "taxify_clean_demo"))
#' taxify_clean(dry_run = TRUE)
#' options(old)
#'
#' @export
taxify_clean <- function(assets = NULL, dry_run = FALSE, verbose = TRUE) {
  if (is_example_data_dir()) {
    stop("The active data directory is the read-only example database; ",
         "set taxify.data_dir to the directory to clean.", call. = FALSE)
  }
  dd <- taxify_data_dir()
  rows <- list()
  add <- function(component, type, reason, path) {
    rows[[length(rows) + 1L]] <<- data.frame(
      component = component, type = type, reason = reason,
      size_mb = round(path_size(path) / 1048576, 1), path = path,
      stringsAsFactors = FALSE
    )
  }

  en_root <- file.path(dd, "enrichment")
  bb_on_disk <- if (dir.exists(dd)) {
    setdiff(basename(list.dirs(dd, recursive = FALSE)), "enrichment")
  } else character(0L)
  en_on_disk <- if (dir.exists(en_root)) {
    basename(list.dirs(en_root, recursive = FALSE))
  } else character(0L)

  if (identical(assets, "all")) {
    if (dir.exists(dd)) add("all", "directory", "removed", dd)
  } else if (!is.null(assets)) {
    assets <- as.character(assets)
    unknown <- setdiff(assets, c(bb_on_disk, en_on_disk))
    if (length(unknown)) {
      warning(sprintf("Not in the data directory: %s.",
                      paste(unknown, collapse = ", ")), call. = FALSE)
    }
    for (nm in intersect(assets, bb_on_disk)) {
      add(nm, "backbone", "removed", asset_store_root(nm, "backbone"))
    }
    for (nm in intersect(assets, en_on_disk)) {
      add(nm, "enrichment", "removed", asset_store_root(nm, "enrichment"))
    }
  } else {
    # Only directories taxify itself lays out are swept; anything else a user
    # keeps in the data directory is left alone.
    managed <- union(backbone_names(),
                     names(tryCatch(local_manifest()$backends,
                                    error = function(e) NULL)))
    sweep <- function(nm, kind) {
      root <- asset_store_root(nm, kind)
      for (d in setdiff(list.dirs(root, recursive = FALSE),
                        file.path(root, "latest"))) {
        add(nm, kind, "superseded", d)
      }
      for (f in stale_download_files(root)) add(nm, kind, "interrupted", f)
    }
    for (nm in intersect(bb_on_disk, managed)) sweep(nm, "backbone")
    for (nm in en_on_disk) sweep(nm, "enrichment")
  }

  out <- if (length(rows)) do.call(rbind, rows) else data.frame(
    component = character(0L), type = character(0L), reason = character(0L),
    size_mb = numeric(0L), path = character(0L), stringsAsFactors = FALSE
  )
  rownames(out) <- NULL

  if (!dry_run && nrow(out)) {
    unlink(out$path, recursive = TRUE)
    taxify_clear_cache()
  }
  if (verbose) {
    message(sprintf("%s %.1f MB in %d path%s from %s.",
                    if (dry_run) "Would remove" else "Removed",
                    sum(out$size_mb), nrow(out),
                    if (nrow(out) == 1L) "" else "s", dd))
  }
  invisible(out)
}


#' Total size in bytes of a file or a directory tree
#' @noRd
path_size <- function(path) {
  if (!file.exists(path)) return(0)
  if (!dir.exists(path)) return(as.numeric(file.size(path)))
  f <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  sum(as.numeric(file.size(f)), na.rm = TRUE)
}

# ---- Reproducibility lockfile ----
#
# cite() prints prose citations for a result. taxify_lock() writes the machine-
# readable counterpart: exactly which backbone and enrichment assets, at which
# version and byte-identity (content id), produced a result -- so a paper's
# Methods can pin what matched, and taxify_restore() can check a later install
# against that pin and report any drift. The two answer "what did I run against?"
# and "am I still running against it?".


#' Coalesce treating zero-length AND NULL as missing
#'
#' `%||%` only catches NULL, but jsonlite yields a zero-length vector for an
#' empty JSON field (`{}` / `[]`). Lock fields read back from a lockfile may
#' therefore be `character(0)`, which slips past `%||%` and then errors in
#' `is.na()`/`if`. This treats both as missing.
#' @noRd
nz_or <- function(x, y) if (length(x) == 0L || is.null(x)) y else x


#' Build a lockfile entry for one installed backbone
#' @noRd
.backbone_lock_entry <- function(bb_name) {
  meta <- tryCatch(read_version_meta(bb_name, "latest"), error = function(e) NULL)
  vtr  <- versioned_vtr_path(bb_name, "latest")
  installed <- file.exists(vtr)
  # A .meta sidecar (taxifydb build) or meta.json (download) supplies version;
  # fall back to the version string in the backbone-version formatter.
  ver <- meta$version %||% NA_character_
  if (is.na(ver) && installed) {
    side <- tryCatch(read_backbone_meta(vtr), error = function(e) NULL)
    ver  <- side$version %||% NA_character_
  }
  list(
    name          = bb_name,
    version       = ver %||% NA_character_,
    content_id    = meta$content_id %||% NA_character_,
    downloaded_at = meta$downloaded_at %||% NA_character_,
    installed     = installed
  )
}


#' Build a lockfile entry for one enrichment
#'
#' The version and content id come from what `register_enrichment()` recorded at
#' join time -- the build the result was produced from. The installed build is
#' only the fallback, for a result registered before those fields existed:
#' reading it first would pin whatever a refresh or a restore left in place
#' since.
#' @noRd
.enrichment_lock_entry <- function(e) {
  name <- e$name
  vtr  <- enrichment_vtr_path(name, "latest")
  meta <- tryCatch(read_enrichment_meta(vtr), error = function(e) NULL)
  pick <- function(recorded, installed) {
    recorded <- nz_or(recorded, NA_character_)
    if (!is.na(recorded[[1L]])) recorded else nz_or(installed, NA_character_)
  }
  list(
    name          = name,
    source        = pick(e$source, meta$source),
    version       = pick(e$version, meta$version),
    license       = pick(e$license, meta$license),
    content_id    = pick(e$content_id, meta$content_id),
    downloaded_at = nz_or(meta$downloaded_at, NA_character_),
    installed     = file.exists(vtr)
  )
}


#' Record the exact backbone and enrichment versions behind a result
#'
#' Writes a machine-readable lockfile pinning which backbone and enrichment
#' assets -- name, version, and byte-identity (content id) -- produced a
#' [taxify()] result. Where [cite()] prints prose citations, `taxify_lock()`
#' records the reproducible counterpart, so a manuscript's Methods can state
#' exactly what was matched against and [taxify_restore()] can later verify an
#' install still matches.
#'
#' @param x A [taxify()] result (its resolved backbones and any `add_*()`
#'   enrichment layers are locked), or `NULL` (default) to snapshot every
#'   installed backbone.
#' @param file Optional path to write the lockfile to (JSON). When `NULL`
#'   (default) nothing is written and the lock is only returned.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A lock list (invisibly when `file` is written), with elements
#'   `taxify_version`, `created`, `r_version`, `backbones`, and `enrichments`.
#'
#' @seealso [taxify_restore()] to check an install against a lockfile, [cite()]
#'   for prose citations.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
#' lock <- taxify_lock(res)
#' lock$backbones[[1]]$name
#'
#' options(old)
#'
#' @export
taxify_lock <- function(x = NULL, file = NULL, verbose = TRUE) {
  if (!is.null(x)) {
    if (!inherits(x, "taxify_result")) {
      stop("x must be a taxify() result or NULL.", call. = FALSE)
    }
    meta <- attr(x, "taxify_meta")
    # Backbones that actually matched a row, else the backbones that were tried.
    bb_names <- if ("backbone" %in% names(x)) {
      unique(x$backbone[!is.na(x$backbone)])
    } else character(0L)
    if (length(bb_names) == 0L) bb_names <- as.character(meta$backbone %||% character(0L))
    # Only the sources that supplied a value: the same rule cite() applies, so a
    # source consulted and matching nothing is neither credited nor pinned, and
    # taxify_restore(install = TRUE) does not fetch an asset the result never
    # used.
    enrich <- Filter(enrichment_contributed, meta$enrichments %||% list())
  } else {
    bb_names <- installed_backbones()
    enrich <- list()
  }

  backbones <- lapply(unique(bb_names), .backbone_lock_entry)
  enrichments <- lapply(enrich, .enrichment_lock_entry)

  lock <- list(
    taxify_version = as.character(utils::packageVersion("taxify")),
    created        = format(Sys.Date(), "%Y-%m-%d"),
    r_version      = R.version.string,
    backbones       = backbones,
    enrichments    = enrichments
  )

  if (!is.null(file)) {
    jsonlite::write_json(lock, file, pretty = TRUE, auto_unbox = TRUE)
    if (verbose) message(sprintf("Lockfile written to %s", file))
    return(invisible(lock))
  }
  lock
}


#' Compare one locked entry against what is installed now
#'
#' Returns `"missing"` (not installed), `"content_drift"` / `"version_drift"`
#' (a compared identity differs), `"unverified"` (installed, but what the lock
#' pinned cannot be compared -- the install exposes no counterpart, or neither
#' side carries an identity at all), or `"ok"`.
#' @noRd
.restore_status <- function(locked_ver, locked_cid, cur_ver, cur_cid, installed) {
  # Normalize zero-length lock fields (jsonlite emits them for empty JSON) so a
  # malformed field degrades to a reported status rather than an exception.
  locked_ver <- nz_or(locked_ver, NA_character_)
  locked_cid <- nz_or(locked_cid, NA_character_)
  cur_ver    <- nz_or(cur_ver, NA_character_)
  cur_cid    <- nz_or(cur_cid, NA_character_)

  if (!isTRUE(installed)) return("missing")

  # Content id is the strongest signal (catches a same-version republish).
  if (!is.na(locked_cid)) {
    if (is.na(cur_cid)) {
      # The lock pinned bytes, and this install exposes none to compare them
      # against (a pre-content-id cache, a local taxifydb build). Matching
      # version labels prove nothing here -- a same-tag republish is exactly
      # what the content id exists to catch -- so the row is unverified, not
      # "ok".
      return("unverified")
    }
    if (!identical(locked_cid, cur_cid)) return("content_drift")
    return("ok")
  }
  if (!is.na(locked_ver) && !is.na(cur_ver)) {
    if (!identical(locked_ver, cur_ver)) return("version_drift")
    return("ok")
  }
  # The lock pinned an identity (a version or content id) but the current
  # install exposes no counterpart: the recorded run cannot be shown to match,
  # so report drift rather than a false "ok".
  if (!is.na(locked_ver) || !is.na(locked_cid)) return("version_drift")
  # Nothing comparable on either side: installed, but unverifiable against the
  # lock.
  "unverified"
}


#' Compare one locked asset against the installed build
#'
#' One row of the `taxify_restore()` report, for either kind. Split out so the
#' report can be built twice -- once to decide what to install, once to say what
#' the install achieved -- from a single definition of what a row is.
#'
#' @param locked The lockfile entry.
#' @param kind Character. `"backbone"` or `"enrichment"`.
#' @return A one-row data.frame.
#' @noRd
.restore_row <- function(locked, kind) {
  short <- function(cid) {
    cid <- nz_or(cid, NA_character_)
    if (is.na(cid)) NA_character_ else substr(cid, 1L, 10L)
  }

  if (kind == "backbone") {
    vtr  <- versioned_vtr_path(locked$name, "latest")
    meta <- tryCatch(read_version_meta(locked$name, "latest"),
                     error = function(e) NULL)
  } else {
    vtr  <- enrichment_vtr_path(locked$name, "latest")
    meta <- tryCatch(read_enrichment_meta(vtr), error = function(e) NULL)
  }
  installed <- file.exists(vtr)

  cur_ver <- nz_or(meta$version, NA_character_)
  if (kind == "backbone" && is.na(cur_ver) && installed) {
    cur_ver <- nz_or((tryCatch(read_backbone_meta(vtr),
                               error = function(e) NULL))$version,
                     NA_character_)
  }
  cur_cid    <- nz_or(meta$content_id, NA_character_)
  locked_ver <- nz_or(locked$version, NA_character_)
  locked_cid <- nz_or(locked$content_id, NA_character_)

  data.frame(
    component            = locked$name,
    type                 = kind,
    locked_version       = locked_ver,
    installed_version    = cur_ver,
    locked_content_id    = short(locked_cid),
    installed_content_id = short(cur_cid),
    status = .restore_status(locked_ver, locked_cid, cur_ver, cur_cid,
                             installed),
    stringsAsFactors = FALSE
  )
}


#' Empty restore report, for a lockfile pinning nothing
#' @noRd
.empty_restore_report <- function() {
  data.frame(
    component = character(0L), type = character(0L),
    locked_version = character(0L), installed_version = character(0L),
    locked_content_id = character(0L), installed_content_id = character(0L),
    status = character(0L), stringsAsFactors = FALSE
  )
}


#' Install the exact build one lockfile entry pins
#'
#' Fetches the build by its recorded content id and makes it the active one.
#' Returns `TRUE` when the build is now installed. Never throws: a build that
#' cannot be recovered leaves its row reporting drift, which is the honest
#' outcome for an asset re-cut before its bytes were published immutably.
#'
#' @noRd
.restore_install_one <- function(locked, kind, verbose = TRUE) {
  cid <- nz_or(locked$content_id, NA_character_)
  if (is.na(cid) || !is_content_key(cid)) {
    if (verbose) {
      message(sprintf(
        "  '%s': the lockfile records no content id, so no exact build can be fetched.",
        locked$name))
    }
    return(FALSE)
  }
  ok <- tryCatch(
    {
      download_content_build(locked$name, cid, kind,
                             version = nz_or(locked$version, NULL),
                             activate = TRUE, verbose = verbose)
      TRUE
    },
    error = function(e) {
      if (verbose) {
        message(sprintf("  '%s': %s", locked$name, conditionMessage(e)))
      }
      FALSE
    }
  )
  ok
}


#' Check an install against a lockfile, and optionally reinstall what drifted
#'
#' Reads a lockfile written by [taxify_lock()] and reports, for each backbone
#' and enrichment it pins, whether the currently installed asset matches -- by
#' version and byte-identity (content id) -- or has drifted, or is missing.
#'
#' With `install = TRUE` it also fetches the exact build each row pins, from the
#' immutable copy published beside the rolling asset, and makes it the active
#' one: the recorded run is put back in place in a single call. The build each
#' pinned build replaces is kept on disk under its own content id, so restoring
#' a lockfile is reversible. Every build that matches the lock afterwards is
#' pinned, including one that already matched and needed no download, so the
#' next session's version check does not refresh it away from the lock. Release
#' a pin with [taxify_pin()].
#'
#' A build published before taxifydb began uploading an immutable copy cannot be
#' recovered -- the re-cut replaced it in place -- and its row keeps reporting
#' drift after the install pass.
#'
#' @param file Path to a lockfile written by [taxify_lock()], or the lock list
#'   it returned.
#' @param install Logical. `FALSE` (default) verifies and reports only. `TRUE`
#'   downloads and activates the pinned build of every asset that does not
#'   already match.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per pinned asset, columns: `component`,
#'   `type` (`"backbone"`/`"enrichment"`), `locked_version`, `installed_version`,
#'   `locked_content_id` and `installed_content_id` (short), and `status`
#'   (`"ok"`, `"version_drift"`, `"content_drift"`, `"missing"`, or
#'   `"unverified"` when what the lock pinned cannot be compared against this
#'   install).
#'   With `install = TRUE` the statuses describe the install afterwards, a
#'   `restored` column records which rows were fetched, and a `pinned` column
#'   which rows are now pinned (every row whose status is `"ok"`).
#'
#' @seealso [taxify_lock()], [taxify_pin()] to pin or release an installed
#'   build without a lockfile, [taxify_store()] for the builds on disk,
#'   [taxify_download_enrichment()] to fetch a single build by content id.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
#' lock <- taxify_lock(res)
#' taxify_restore(lock, verbose = FALSE)
#'
#' options(old)
#'
#' @export
taxify_restore <- function(file, install = FALSE, verbose = TRUE) {
  lock <- if (is.list(file) && !is.null(file$backbones)) {
    file
  } else if (is.character(file) && length(file) == 1L && file.exists(file)) {
    read_json_bom(file, simplifyVector = FALSE)
  } else {
    stop("file must be a lockfile path or a lock list from taxify_lock().",
         call. = FALSE)
  }

  entries <- c(
    lapply(lock$backbones %||% list(),   function(b) list(locked = b, kind = "backbone")),
    lapply(lock$enrichments %||% list(), function(e) list(locked = e, kind = "enrichment"))
  )

  report <- function() {
    rows <- lapply(entries, function(x) .restore_row(x$locked, x$kind))
    out <- if (length(rows)) do.call(rbind, rows) else .empty_restore_report()
    rownames(out) <- NULL
    out
  }

  out <- report()

  if (isTRUE(install) && length(entries)) {
    todo <- which(out$status != "ok")
    restored <- rep(FALSE, nrow(out))
    if (length(todo)) {
      if (verbose) {
        message(sprintf("taxify_restore(): fetching %d pinned build%s...",
                        length(todo), if (length(todo) == 1L) "" else "s"))
      }
      for (i in todo) {
        restored[i] <- .restore_install_one(entries[[i]]$locked,
                                            entries[[i]]$kind,
                                            verbose = verbose)
      }
      out <- report()
    }
    out$restored <- restored

    # Restoring holds the install to the lock, so a build that already matched
    # is pinned exactly like one fetched above; otherwise the next version
    # check refreshes it away from the lock.
    held <- which(out$status == "ok")
    if (!is_example_data_dir()) {
      for (i in held) {
        .set_pinned(entries[[i]]$locked$name, entries[[i]]$kind, TRUE)
      }
    } else {
      held <- integer(0L)
    }
    out$pinned <- seq_len(nrow(out)) %in% held
  }

  if (verbose) {
    n_unver <- sum(out$status == "unverified")
    n_drift <- sum(!out$status %in% c("ok", "unverified"))
    if (n_drift == 0L && n_unver == 0L) {
      message("taxify_restore(): all pinned assets match the lockfile.")
    } else {
      parts <- character(0L)
      if (n_drift > 0L) parts <- c(parts, sprintf("%d differ", n_drift))
      if (n_unver > 0L) parts <- c(parts, sprintf("%d unverifiable", n_unver))
      message(sprintf(
        "taxify_restore(): %s (of %d pinned assets); see 'status'.",
        paste(parts, collapse = ", "), nrow(out)))
      if (!isTRUE(install) && n_drift > 0L) {
        message("  taxify_restore(file, install = TRUE) fetches the pinned builds.")
      }
    }
  }
  out
}


#' Pin or release installed taxify assets
#'
#' A pinned build stays active: the version check that [taxify()],
#' [install_backbones()] and the `add_*()` doors run against the manifest leaves
#' it in place instead of replacing it with the current release. Pin the builds a
#' project was run against to keep a shared data directory from moving under it,
#' and release them when the project is done. The pin is recorded in the build's
#' `meta.json` together with its content id (the md5 of its `.vtr`, as
#' [taxify_lock()] records it), so a pinned build can also be named in a
#' lockfile.
#'
#' Every name is checked before anything is written: when one is not installed,
#' or is installed as both a backbone and an enrichment and `kind` does not say
#' which, nothing is pinned.
#'
#' [taxify_restore()] with `install = TRUE` pins every build matching a lockfile,
#' and a build fetched with `taxify_download(content_id = )` or
#' `taxify_download_enrichment(content_id = )` is pinned when it is activated.
#'
#' @param name Character vector of installed backbone and/or enrichment names.
#' @param pin Logical. `TRUE` (default) pins; `FALSE` releases the pin, so the
#'   next version check compares the build against the manifest again.
#' @param kind `NULL` (default) to find each name among the installed backbones
#'   and enrichments, or `"backbone"` / `"enrichment"` to look only there. Needed
#'   for a name installed as both (e.g. `"wcvp"`).
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per name: `component`, `type`, `version`,
#'   `content_id` (the full id of the build pinned or released) and `pinned`.
#'
#' @seealso [taxify_restore()] to pin the builds a lockfile records,
#'   [taxify_store()] to list the builds on disk and whether each is pinned.
#'
#' @examples
#' \dontrun{
#' taxify_pin(c("wfo", "col"))
#' taxify_pin("iucn", kind = "enrichment")
#' taxify_pin(c("wfo", "col"), pin = FALSE)
#' }
#'
#' @export
taxify_pin <- function(name, pin = TRUE, kind = NULL, verbose = TRUE) {
  if (!is.character(name) || length(name) == 0L || anyNA(name) ||
      !all(nzchar(name))) {
    stop("name must be a character vector of installed asset names.",
         call. = FALSE)
  }
  if (!is.logical(pin) || length(pin) != 1L || is.na(pin)) {
    stop("pin must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.null(kind)) kind <- match.arg(kind, c("backbone", "enrichment"))
  if (is_example_data_dir()) {
    stop("The bundled example database is read-only; its builds cannot be pinned.",
         call. = FALSE)
  }

  name <- unique(name)
  kinds <- vapply(name, .pin_kind, character(1L), kind = kind)
  rows <- lapply(seq_along(name), function(i) .set_pinned(name[[i]], kinds[[i]], pin))
  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  if (verbose) {
    for (i in seq_len(nrow(out))) {
      message(sprintf("%s %s '%s' %s build %s.",
                      if (pin) "\u2713 Pinned" else "\u2713 Released",
                      out$type[[i]], out$component[[i]],
                      if (pin) "to" else "from", short_cid(out$content_id[[i]])))
    }
  }
  out
}


#' Which kind of installed asset a name refers to
#'
#' @param name Character scalar.
#' @param kind `NULL`, `"backbone"` or `"enrichment"`.
#' @return `"backbone"` or `"enrichment"`; stops when the name is not
#'   installed as the kind asked for, or is installed as both and `kind` is
#'   `NULL`.
#' @noRd
.pin_kind <- function(name, kind = NULL) {
  installed <- c(
    backbone   = file.exists(asset_vtr_path(name, "latest", "backbone")),
    enrichment = file.exists(asset_vtr_path(name, "latest", "enrichment"))
  )
  if (!is.null(kind)) {
    if (!installed[[kind]]) {
      stop(sprintf("No %s '%s' is installed in %s; nothing to pin.",
                   kind, name, taxify_data_dir()), call. = FALSE)
    }
    return(kind)
  }
  hit <- names(installed)[installed]
  if (length(hit) == 0L) {
    stop(sprintf(
      "'%s' is not installed as a backbone or an enrichment in %s; nothing to pin.",
      name, taxify_data_dir()), call. = FALSE)
  }
  if (length(hit) > 1L) {
    stop(sprintf(
      "'%s' is installed both as a backbone and as an enrichment; say which with kind =.",
      name), call. = FALSE)
  }
  hit
}


#' Set the pin flag on the active build of an installed asset
#'
#' Records the build's content id alongside the flag, hashing the `.vtr` when
#' its `meta.json` carries none, so the pin names the bytes it holds. Releasing
#' a pin also clears the session's version-check flag, so the next check in this
#' session compares the build against the manifest.
#'
#' @param name Character scalar.
#' @param kind `"backbone"` or `"enrichment"`.
#' @param pin Logical scalar.
#' @return A one-row data.frame: `component`, `type`, `version`, `content_id`,
#'   `pinned`.
#' @noRd
.set_pinned <- function(name, kind, pin) {
  dir <- asset_dir(name, "latest", kind)
  vtr <- file.path(dir, paste0(name, ".vtr"))
  meta_path <- file.path(dir, "meta.json")
  meta <- if (file.exists(meta_path)) {
    read_json_bom(meta_path, simplifyVector = TRUE)
  } else {
    list()
  }

  cid <- nz_or(meta$content_id, NA_character_)
  if (is.na(cid) || !is_content_key(cid)) {
    cid <- content_id_of(vtr)
    meta$content_id <- cid
  }
  meta$pinned <- isTRUE(pin)
  jsonlite::write_json(meta, meta_path, pretty = TRUE, auto_unbox = TRUE)

  if (!isTRUE(pin)) {
    flag <- if (kind == "backbone") ".version_checked." else ".enrichment_version_checked."
    .taxify_env[[paste0(flag, name)]] <- NULL
  }

  data.frame(component = name, type = kind,
             version = as.character(nz_or(meta$version, NA_character_)),
             content_id = cid, pinned = isTRUE(pin), stringsAsFactors = FALSE)
}

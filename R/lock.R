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
#' @noRd
.enrichment_lock_entry <- function(e) {
  name <- e$name
  vtr  <- enrichment_vtr_path(name, "latest")
  meta <- tryCatch(read_enrichment_meta(vtr), error = function(e) NULL)
  list(
    name          = name,
    source        = e$source %||% (meta$source %||% NA_character_),
    version       = e$version %||% (meta$version %||% NA_character_),
    license       = e$license %||% (meta$license %||% NA_character_),
    content_id    = meta$content_id %||% NA_character_,
    downloaded_at = meta$downloaded_at %||% NA_character_,
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
    enrich <- meta$enrichments %||% list()
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
#' (a compared identity differs, or was locked but the install exposes no
#' counterpart to compare it against), `"unverified"` (installed but neither a
#' version nor a content id could be compared on either side), or `"ok"`.
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
  if (!is.na(locked_cid) && !is.na(cur_cid)) {
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
#' a lockfile is reversible. A pinned build is not refreshed away by the next
#' session's version check.
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
#'   `"unverified"` when neither a version nor a content id could be compared).
#'   With `install = TRUE` the statuses describe the install afterwards, and a
#'   `restored` column records which rows were fetched.
#'
#' @seealso [taxify_lock()], [taxify_store()] for the builds on disk,
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

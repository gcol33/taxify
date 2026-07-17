# ---- Reproducibility lockfile ----
#
# cite() prints prose citations for a result. taxify_lock() writes the machine-
# readable counterpart: exactly which backbone and enrichment assets, at which
# version and byte-identity (content id), produced a result -- so a paper's
# Methods can pin what matched, and taxify_restore() can check a later install
# against that pin and report any drift. The two answer "what did I run against?"
# and "am I still running against it?".


#' Build a lockfile entry for one installed backbone
#' @noRd
.backbone_lock_entry <- function(be_name) {
  meta <- tryCatch(read_version_meta(be_name, "latest"), error = function(e) NULL)
  vtr  <- versioned_vtr_path(be_name, "latest")
  installed <- file.exists(vtr)
  # A .meta sidecar (taxifydb build) or meta.json (download) supplies version;
  # fall back to the version string in the backbone-version formatter.
  ver <- meta$version %||% NA_character_
  if (is.na(ver) && installed) {
    side <- tryCatch(read_backbone_meta(vtr), error = function(e) NULL)
    ver  <- side$version %||% NA_character_
  }
  list(
    name          = be_name,
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
#'   `taxify_version`, `created`, `r_version`, `backends`, and `enrichments`.
#'
#' @seealso [taxify_restore()] to check an install against a lockfile, [cite()]
#'   for prose citations.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' res  <- taxify("Quercus robur", backend = "wfo", verbose = FALSE)
#' lock <- taxify_lock(res)
#' lock$backends[[1]]$name
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
    # Backbones that actually matched a row, else the backends that were tried.
    be_names <- if ("backend" %in% names(x)) {
      unique(x$backend[!is.na(x$backend)])
    } else character(0L)
    if (length(be_names) == 0L) be_names <- as.character(meta$backend %||% character(0L))
    enrich <- meta$enrichments %||% list()
  } else {
    be_names <- installed_backbones()
    enrich <- list()
  }

  backends <- lapply(unique(be_names), .backbone_lock_entry)
  enrichments <- lapply(enrich, .enrichment_lock_entry)

  lock <- list(
    taxify_version = as.character(utils::packageVersion("taxify")),
    created        = format(Sys.Date(), "%Y-%m-%d"),
    r_version      = R.version.string,
    backends       = backends,
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
#' @noRd
.restore_status <- function(locked_ver, locked_cid, cur_ver, cur_cid, installed) {
  if (!isTRUE(installed)) return("missing")
  # Content id is the strongest signal (catches a same-version republish).
  if (!is.na(locked_cid) && !is.na(cur_cid)) {
    if (!identical(locked_cid, cur_cid)) return("content_drift")
    return("ok")
  }
  if (!is.na(locked_ver) && !is.na(cur_ver) && !identical(locked_ver, cur_ver)) {
    return("version_drift")
  }
  "ok"
}


#' Check an install against a lockfile
#'
#' Reads a lockfile written by [taxify_lock()] and reports, for each backbone
#' and enrichment it pins, whether the currently installed asset matches -- by
#' version and byte-identity (content id) -- or has drifted, or is missing.
#' taxify serves only the latest version of each asset, so `taxify_restore()`
#' verifies and reports rather than force-installing a historical version; a
#' drift row tells you the recorded run cannot be reproduced byte-for-byte with
#' the current downloads.
#'
#' @param file Path to a lockfile written by [taxify_lock()], or the lock list
#'   it returned.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per pinned asset, columns: `component`,
#'   `type` (`"backbone"`/`"enrichment"`), `locked_version`, `installed_version`,
#'   `locked_content_id` and `installed_content_id` (short), and `status`
#'   (`"ok"`, `"version_drift"`, `"content_drift"`, or `"missing"`).
#'
#' @seealso [taxify_lock()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' res  <- taxify("Quercus robur", backend = "wfo", verbose = FALSE)
#' lock <- taxify_lock(res)
#' taxify_restore(lock, verbose = FALSE)
#'
#' options(old)
#'
#' @export
taxify_restore <- function(file, verbose = TRUE) {
  lock <- if (is.list(file) && !is.null(file$backends)) {
    file
  } else if (is.character(file) && length(file) == 1L && file.exists(file)) {
    read_json_bom(file, simplifyVector = FALSE)
  } else {
    stop("file must be a lockfile path or a lock list from taxify_lock().",
         call. = FALSE)
  }

  short <- function(cid) {
    if (is.null(cid) || is.na(cid)) NA_character_ else substr(cid, 1L, 10L)
  }

  rows <- list()

  for (b in lock$backends %||% list()) {
    meta <- tryCatch(read_version_meta(b$name, "latest"), error = function(e) NULL)
    vtr  <- versioned_vtr_path(b$name, "latest")
    installed <- file.exists(vtr)
    cur_ver <- meta$version %||% NA_character_
    if (is.na(cur_ver) && installed) {
      cur_ver <- (tryCatch(read_backbone_meta(vtr), error = function(e) NULL))$version %||% NA_character_
    }
    cur_cid <- meta$content_id %||% NA_character_
    rows[[length(rows) + 1L]] <- data.frame(
      component            = b$name,
      type                 = "backbone",
      locked_version       = b$version %||% NA_character_,
      installed_version    = cur_ver,
      locked_content_id    = short(b$content_id),
      installed_content_id = short(cur_cid),
      status = .restore_status(b$version %||% NA_character_,
                               b$content_id %||% NA_character_,
                               cur_ver, cur_cid, installed),
      stringsAsFactors = FALSE
    )
  }

  for (e in lock$enrichments %||% list()) {
    vtr  <- enrichment_vtr_path(e$name, "latest")
    meta <- tryCatch(read_enrichment_meta(vtr), error = function(e) NULL)
    installed <- file.exists(vtr)
    cur_ver <- meta$version %||% NA_character_
    cur_cid <- meta$content_id %||% NA_character_
    rows[[length(rows) + 1L]] <- data.frame(
      component            = e$name,
      type                 = "enrichment",
      locked_version       = e$version %||% NA_character_,
      installed_version    = cur_ver,
      locked_content_id    = short(e$content_id),
      installed_content_id = short(cur_cid),
      status = .restore_status(e$version %||% NA_character_,
                               e$content_id %||% NA_character_,
                               cur_ver, cur_cid, installed),
      stringsAsFactors = FALSE
    )
  }

  out <- if (length(rows)) do.call(rbind, rows) else data.frame(
    component = character(0L), type = character(0L),
    locked_version = character(0L), installed_version = character(0L),
    locked_content_id = character(0L), installed_content_id = character(0L),
    status = character(0L), stringsAsFactors = FALSE
  )
  rownames(out) <- NULL

  if (verbose) {
    n_drift <- sum(out$status != "ok")
    if (n_drift == 0L) {
      message("taxify_restore(): all pinned assets match the lockfile.")
    } else {
      message(sprintf(
        "taxify_restore(): %d of %d pinned assets differ from the lockfile (see 'status').",
        n_drift, nrow(out)))
    }
  }
  out
}

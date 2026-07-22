# ---- Unified genus register ----
#
# Cross-backbone genus-level index, published as two pre-built .vtr files and
# downloaded like any other asset:
#
#   genus_register.vtr   - one row per genus, with classification + life_form
#   backend_coverage.vtr - long format: one row per (genus x backbone)
#
# Both are built by taxifydb over a fixed backbone set, so every install
# resolves the same genus to the same kingdom_group / taxon_group / life_form
# regardless of which backbones the user happens to have on disk. The register
# feeds taxify()'s own output columns, so building it locally from the
# installed subset would make identical code return different answers on two
# machines.
#
# The register is small enough (~500k rows) to cache in memory; it is loaded
# into .taxify_env$register on first access.


# ---- Path helpers ----

#' Name of the published register assets
#' @noRd
.register_assets <- c(register = "genus_register", coverage = "backend_coverage")

#' Path to genus_register.vtr
#' @noRd
register_vtr_path <- function() {
  versioned_vtr_path(.register_assets[["register"]], "latest")
}

#' Path to backend_coverage.vtr
#' @noRd
coverage_vtr_path <- function() {
  versioned_vtr_path(.register_assets[["coverage"]], "latest")
}


# ---- Asset resolution ----

#' Resolve a register asset, downloading it on first use
#'
#' Same fallback chain as the backbones and enrichments: disk, then the
#' pre-built `.vtr` from the manifest, then a `taxifydb` build. Returns `NULL`
#' rather than erroring when none of those work, so an offline session degrades
#' to the behaviour of a missing register (the columns it fills come back `NA`)
#' instead of failing the whole call.
#'
#' @param asset One of `"register"` or `"coverage"`.
#' @param verbose Logical.
#' @return Path to the `.vtr`, or `NULL`.
#' @noRd
ensure_register_asset <- function(asset, verbose = TRUE) {
  name <- .register_assets[[asset]]
  path <- versioned_vtr_path(name, "latest")

  if (file.exists(path)) {
    # Once per session, pick up a newer published build.
    ensure_backbones_current(name, verbose = verbose)
    return(path)
  }

  # No local copy: the download is the normal route, and a failure here is not
  # fatal, so take the session flag and stay quiet about it.
  .taxify_env[[paste0(".version_checked.", name)]] <- TRUE
  out <- tryCatch(download_backbone(name, version = "latest", verbose = verbose),
                  error = function(e) NULL)
  if (!is.null(out) && file.exists(out)) return(out)

  if (requireNamespace("taxifydb", quietly = TRUE)) {
    tryCatch(taxifydb::build_register(verbose = verbose), error = function(e) NULL)
    if (file.exists(path)) return(path)
  }
  NULL
}

#' @rdname ensure_register_asset
#' @noRd
ensure_register <- function(verbose = TRUE) {
  ensure_register_asset("register", verbose = verbose)
}

#' @rdname ensure_register_asset
#' @noRd
ensure_coverage <- function(verbose = TRUE) {
  ensure_register_asset("coverage", verbose = verbose)
}


# ---- Build-from-source escape hatch ----

#' Build the genus register from source
#'
#' Rebuilds `genus_register.vtr` and `backend_coverage.vtr` locally instead of
#' downloading the published pair. The build itself lives in `taxifydb`, which
#' resolves every backbone in the register's fixed backbone set and can take
#' well over an hour; the download takes seconds and yields the same file, so
#' this is an escape hatch rather than the normal route.
#'
#' `taxify_download("register")` fetches the published pair.
#'
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return Path to `genus_register.vtr` (invisibly).
#' @seealso [taxify_load_register()] to load it into memory,
#'   [taxify_register_coverage()] to query backbone coverage for a genus.
#' @export
taxify_build_register <- function(verbose = TRUE) {
  require_taxifydb("Building the genus register")
  res <- taxifydb::build_register(verbose = verbose)
  invisible(if (is.list(res)) res$register else res)
}


# ---- User-facing functions (exported) ----

#' Load the unified genus register into memory
#'
#' Reads `genus_register.vtr` and caches it as a data.frame in
#' `.taxify_env$register`, downloading it on first use. Subsequent calls reuse
#' the cached version unless `force = TRUE`.
#'
#' The register contains one row per genus with columns `genus`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `kingdom_group`, `taxon_group` and
#' `life_form`.
#'
#' @param force Logical. If `TRUE`, reloads from disk even if already cached.
#'   Default `FALSE`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return The register data.frame (invisibly).
#' @export
taxify_load_register <- function(force = FALSE, verbose = TRUE) {
  if (!force && !is.null(.taxify_env$register)) {
    return(invisible(.taxify_env$register))
  }

  path <- ensure_register(verbose = verbose)
  if (is.null(path)) {
    stop(sprintf(
      paste0("Genus register not available at: %s\n",
             "Download it with taxify_download(\"register\"), or build it ",
             "locally with taxify_build_register()."),
      register_vtr_path()
    ), call. = FALSE)
  }

  if (verbose) message("Loading genus register from disk...")
  reg <- vectra::tbl(path) |> vectra::collect()
  .taxify_env$register <- reg

  if (verbose) message(sprintf("  %d genera loaded.", nrow(reg)))
  invisible(reg)
}


#' Look up a genus in the register
#'
#' Returns the register row for the given genus, or `NULL` if not found.
#' Auto-loads the register on first call.
#'
#' @param genus Character scalar. The genus name to look up.
#' @return A one-row data.frame, or `NULL` if the genus is not in the register.
#' @export
lookup_genus <- function(genus) {
  if (!is.character(genus) || length(genus) != 1L) {
    stop("genus must be a character scalar", call. = FALSE)
  }

  if (is.null(.taxify_env$register)) {
    taxify_load_register(verbose = FALSE)
  }

  reg <- .taxify_env$register
  hit <- reg[reg$genus == genus, , drop = FALSE]
  if (nrow(hit) == 0L) NULL else hit
}


#' Show backbone coverage for a genus
#'
#' Queries `backend_coverage.vtr` to determine which backbones contain the
#' given genus, along with the backbone version at time of indexing.
#'
#' @param genus Character scalar. The genus name to query.
#' @return A data.frame with columns `genus`, `backbone`, `version`,
#'   `date_added`. Returns a zero-row data.frame if the genus is not found
#'   in any backbone.
#' @export
taxify_register_coverage <- function(genus) {
  if (!is.character(genus) || length(genus) != 1L) {
    stop("genus must be a character scalar", call. = FALSE)
  }

  path <- ensure_coverage(verbose = FALSE)
  if (is.null(path)) {
    stop(sprintf(
      paste0("Backbone coverage not available at: %s\n",
             "Download it with taxify_download(\"register\"), or build it ",
             "locally with taxify_build_register()."),
      coverage_vtr_path()
    ), call. = FALSE)
  }

  query_df <- data.frame(query_genus = genus, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(query_df, tmp)

  result <- vectra::inner_join(
    vectra::tbl(tmp),
    vectra::tbl(path),
    by = c("query_genus" = "genus")
  ) |> vectra::collect()

  if (nrow(result) == 0L) {
    return(data.frame(
      genus      = character(0L),
      backbone   = character(0L),
      version    = character(0L),
      date_added = character(0L),
      stringsAsFactors = FALSE
    ))
  }

  # The published .vtr stores the column as `backend`; taxifydb writes it and
  # taxify only reads it, so the name it reports is renamed here rather than in
  # the asset.
  result$genus    <- result$query_genus
  result$backbone <- result$backend
  result[, c("genus", "backbone", "version", "date_added"), drop = FALSE]
}

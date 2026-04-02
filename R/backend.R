# ---- S3 backend interface ----
#
# Each backend (WFO, COL, GBIF) implements these generics.
# Adding a new backend is O(1): define the methods, done.

#' Create a new taxify backend object
#'
#' @param name Character string identifying the backend.
#' @param ... Additional backend-specific fields.
#' @param class Character vector of subclasses.
#' @return A taxify_backend S3 object.
#' @noRd
new_backend <- function(name, ..., class = character()) {
  structure(list(name = name, ...), class = c(class, "taxify_backend"))
}


#' Download a backbone database
#'
#' Downloads the latest Darwin Core snapshot for the specified backend and
#' converts it to vectra's `.vtr` format for fast repeated queries.
#'
#' Always re-downloads the latest release, overwriting any existing backbone.
#' Use [taxify()] for day-to-day matching — it auto-downloads on first use
#' and reuses the local copy thereafter.
#'
#' @param backend A `taxify_backend` object or a character string
#'   (e.g., `"wfo"`).
#' @param dest Character. Destination directory. Defaults to
#'   [taxify_data_dir()].
#' @param verbose Logical. Print progress messages.
#' @param ... Additional arguments passed to methods.
#' @return The path to the `.vtr` file (invisibly).
#' @export
taxify_download <- function(backend, dest = NULL, verbose = TRUE, ...) {
  if (is.character(backend)) {
    backend <- resolve_backend(backend)
    return(taxify_download(backend, dest = dest, verbose = verbose, ...))
  }
  UseMethod("taxify_download")
}


#' Load a backbone into memory
#'
#' @param backend A taxify_backend object.
#' @param path Character. Path to the .vtr file. If NULL, uses the default
#'   location from [taxify_data_dir()].
#' @param ... Additional arguments passed to methods.
#' @return A vectra node (lazy handle to the backbone).
#' @noRd
taxify_load <- function(backend, path = NULL, ...) {
  UseMethod("taxify_load")
}


#' Exact matching against a backbone
#'
#' @param backend A taxify_backend object.
#' @param names_df A data.frame with columns `original` and `cleaned`.
#' @param backbone A vectra node (the loaded backbone).
#' @param ... Additional arguments passed to methods.
#' @return A data.frame of matches.
#' @noRd
match_exact <- function(backend, names_df, backbone, ...) {
  UseMethod("match_exact")
}


#' Fuzzy matching against a backbone
#'
#' @param backend A taxify_backend object.
#' @param unmatched_df A data.frame of names that failed exact matching.
#' @param backbone A vectra node.
#' @param method Character. Distance algorithm.
#' @param threshold Numeric. Maximum normalized distance.
#' @param ... Additional arguments passed to methods.
#' @return A data.frame of fuzzy matches.
#' @noRd
match_fuzzy <- function(backend, unmatched_df, backbone,
                        method = "dl", threshold = 0.2, ...) {
  UseMethod("match_fuzzy")
}


#' Resolve synonyms to accepted names
#'
#' @param backend A taxify_backend object.
#' @param matches A data.frame with match results containing taxon_id and
#'   accepted_id_raw columns.
#' @param backbone A vectra node.
#' @param ... Additional arguments passed to methods.
#' @return A data.frame with resolved accepted names.
#' @noRd
resolve_synonyms <- function(backend, matches, backbone, ...) {
  UseMethod("resolve_synonyms")
}


#' Resolve a backend name to an S3 object
#'
#' @param backend Character string or taxify_backend object.
#' @return A taxify_backend object.
#' @noRd
resolve_backend <- function(backend) {
  if (inherits(backend, "taxify_backend")) return(backend)
  switch(backend,
    wfo = wfo_backend(),
    col = col_backend(),
    gbif = gbif_backend(),
    stop(sprintf("Unknown backend '%s'. Available: wfo, col, gbif", backend),
         call. = FALSE)
  )
}

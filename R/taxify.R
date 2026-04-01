#' Match taxonomic names against local backbone databases
#'
#' Matches a vector of taxonomic names against locally stored Darwin Core
#' backbone databases. Returns a data.frame with one row per input name
#' containing the matched name, accepted name, taxonomic hierarchy, and
#' match quality information.
#'
#' @param x Character vector of taxonomic names.
#' @param backend Character string or `taxify_backend` object. Currently
#'   only `"wfo"` (World Flora Online) is supported. Default `"wfo"`.
#' @param fuzzy Logical. Enable fuzzy matching for names that fail exact
#'   match. Default `TRUE`.
#' @param fuzzy_threshold Numeric 0--1. Maximum normalized string distance
#'   for fuzzy matches. Default `0.2` (roughly 1 edit per 5 characters).
#' @param fuzzy_method Character. One of `"dl"` (Damerau-Levenshtein,
#'   default), `"levenshtein"`, or `"jw"` (Jaro-Winkler).
#' @param version Character. Backbone version. Default `"latest"`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A data.frame with one row per input name and 15 columns:
#' \describe{
#'   \item{input_name}{The original name as provided.}
#'   \item{matched_name}{Full name in the backbone that matched.}
#'   \item{accepted_name}{Resolved accepted name (equals `matched_name`
#'     if not a synonym).}
#'   \item{taxon_id}{Backend-specific ID of the matched name.}
#'   \item{accepted_id}{ID of the accepted name.}
#'   \item{rank}{Taxonomic rank (species, subspecies, genus, etc.).}
#'   \item{family}{Family name.}
#'   \item{genus}{Genus name.}
#'   \item{epithet}{Specific epithet.}
#'   \item{authorship}{Authorship of the matched name.}
#'   \item{is_synonym}{Logical. Was the match a synonym?}
#'   \item{is_hybrid}{Logical. Was a hybrid marker detected in the input?}
#'   \item{match_type}{One of `"exact"`, `"exact_ci"`, `"fuzzy"`, or
#'     `"none"`.}
#'   \item{fuzzy_dist}{Normalized string distance (0--1), `NA` if exact.}
#'   \item{backend}{Which backend was used (e.g., `"wfo"`).}
#' }
#'
#' @examples
#' \dontrun{
#' # Match a few names (downloads WFO backbone on first use)
#' taxify(c("Quercus robur", "Pinus sylvestris"))
#'
#' # Disable fuzzy matching
#' taxify("Quercus robus", fuzzy = FALSE)
#'
#' # Use Jaro-Winkler similarity
#' taxify("Quercus robus", fuzzy_method = "jw")
#' }
#'
#' @export
taxify <- function(x,
                   backend = "wfo",
                   fuzzy = TRUE,
                   fuzzy_threshold = 0.2,
                   fuzzy_method = c("dl", "levenshtein", "jw"),
                   version = "latest",
                   verbose = TRUE) {

  fuzzy_method <- match.arg(fuzzy_method)

  # Validate input
  if (!is.character(x)) {
    stop("x must be a character vector", call. = FALSE)
  }
  if (length(x) == 0L) {
    stop("x must have at least one element", call. = FALSE)
  }

  # Resolve backend
  be <- resolve_backend(backend, version)

  # Ensure backbone is available (cache -> disk -> download)
  bb_path <- ensure_backbone(be, verbose = verbose)

  # Clean names
  if (verbose) message(sprintf("Matching %d names...", length(x)))
  names_df <- clean_names(x)

  # Exact matching
  result <- match_exact(be, names_df, bb_path)

  # Fuzzy matching on unmatched
  n_unmatched <- sum(is.na(result$match_type) & !is.na(names_df$cleaned))
  if (fuzzy && n_unmatched > 0L) {
    if (verbose) message(sprintf("  Fuzzy matching %d unmatched names...",
                                  n_unmatched))
    result <- match_fuzzy(be, result, bb_path,
                          method = fuzzy_method,
                          threshold = fuzzy_threshold)
  }

  # Resolve synonyms
  result <- resolve_synonyms(be, result, bb_path)

  # Fill backend column
  result$backend <- ifelse(is.na(result$match_type), NA_character_, be$name)

  # Set match_type = "none" for unmatched

  result$match_type[is.na(result$match_type) & !is.na(result$input_name)] <- "none"

  # Drop internal columns and return the 15-column schema
  result$taxonomicStatus <- NULL
  result$accepted_id_raw <- NULL

  # Reset row names
  rownames(result) <- NULL

  result
}

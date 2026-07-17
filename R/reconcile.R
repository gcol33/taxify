# ---- Reconcile a name list against current backbone treatment ----
#
# taxify() resolves each name on its own. reconcile() steps back and reports
# what a whole checklist looks like against a backbone's current treatment: which
# names are unchanged, which are now synonyms of a different accepted name, which
# were misspelled, which are ambiguous, which no longer resolve -- and which
# collapse together (several old names now pointing at one accepted taxon). It is
# the migration report for "here is last year's species list; what moved?".


#' Reconcile a checklist against a backbone's current treatment
#'
#' Classifies each name in a list against what a backbone currently accepts, so a
#' checklist assembled at one time can be checked against the taxonomy as it
#' stands now. Where [taxify()] returns the resolved match per name,
#' `reconcile()` adds the editorial verdict -- unchanged, now a synonym, a
#' misspelling, ambiguous, or unresolved -- and flags names that merge onto a
#' single accepted taxon.
#'
#' @param x Character vector of names (a checklist).
#' @param backend Character vector of backend names or a `taxify_backend`
#'   object, passed to [taxify()]. `NULL` (default) uses every installed
#'   backbone.
#' @param ... Further arguments passed to [taxify()] (e.g. `fuzzy`,
#'   `fuzzy_threshold`, `kingdom`).
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per input name, columns:
#' \describe{
#'   \item{input_name}{The name as supplied.}
#'   \item{accepted_name}{The name it resolves to now (`NA` if unresolved).}
#'   \item{status}{One of:
#'     `"unchanged"` (resolves to itself, still accepted),
#'     `"synonym"` (now a synonym of a different accepted name),
#'     `"misspelling"` (resolved by fuzzy/abbrev match to a corrected spelling),
#'     `"ambiguous"` (a homonym resolving to several accepted taxa; see
#'       [taxify_candidates()]),
#'     `"unresolved"` (no match).}
#'   \item{is_synonym}{Logical, from [taxify()].}
#'   \item{match_type}{The [taxify()] match type.}
#'   \item{merged}{Logical. `TRUE` when two or more input names resolve to this
#'     same accepted name (a many-to-one collapse).}
#'   \item{merged_with}{`|`-joined other input names sharing this accepted name,
#'     or `NA`.}
#'   \item{backend}{Backend that matched (`NA` if unresolved).}
#' }
#'
#' @seealso [taxify()], [taxify_candidates()] to expand the ambiguous rows,
#'   [synonyms()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Quercus pedunculata is now a synonym of Quercus robur; "Quercus robus" is a
#' # misspelling of it; a bad name is unresolved.
#' reconcile(c("Quercus robur", "Quercus pedunculata", "Quercus robus",
#'             "Notagenus imaginus"),
#'           backend = "wfo", verbose = FALSE)
#'
#' options(old)
#'
#' @export
reconcile <- function(x, backend = NULL, ..., verbose = TRUE) {
  if (!is.character(x) || length(x) == 0L) {
    stop("x must be a non-empty character vector.", call. = FALSE)
  }
  res <- taxify(x, backend = backend, verbose = verbose, ...)

  n  <- nrow(res)
  mt <- res$match_type
  resolved <- !is.na(res$accepted_id) & !is.na(mt) &
    !mt %in% c("none", "out_of_scope", "hybrid_formula")

  # Compare the input to its accepted name in the normalized (orthography- and
  # case-folded) space the matcher uses, so a case-only difference reads as
  # unchanged but a corrected typo does not.
  in_norm  <- normalize_epithets(clean_names(res$input_name)$cleaned)
  acc_norm <- normalize_epithets(res$accepted_name)
  same_name <- !is.na(in_norm) & !is.na(acc_norm) & in_norm == acc_norm

  is_amb <- !is.na(res$is_ambiguous) & res$is_ambiguous
  is_syn <- !is.na(res$is_synonym) & res$is_synonym
  is_misspell <- !is.na(mt) & mt %in% c("fuzzy", "abbrev")

  status <- rep("unresolved", n)
  status[resolved & same_name & !is_syn] <- "unchanged"
  status[resolved & is_misspell & !is_syn] <- "misspelling"
  status[resolved & is_syn] <- "synonym"
  status[resolved & is_amb]  <- "ambiguous"

  # Many-to-one collapse: >= 2 distinct inputs sharing one accepted name.
  acc <- res$accepted_name
  merged <- rep(FALSE, n)
  merged_with <- rep(NA_character_, n)
  keyable <- resolved & !is.na(acc)
  if (any(keyable)) {
    grp <- split(which(keyable), acc[keyable])
    for (rows in grp) {
      inputs <- unique(res$input_name[rows])
      if (length(inputs) >= 2L) {
        for (i in rows) {
          merged[i] <- TRUE
          others <- setdiff(inputs, res$input_name[i])
          merged_with[i] <- if (length(others)) paste(others, collapse = "|") else NA_character_
        }
      }
    }
  }

  out <- data.frame(
    input_name    = res$input_name,
    accepted_name = res$accepted_name,
    status        = status,
    is_synonym    = res$is_synonym,
    match_type    = mt,
    merged        = merged,
    merged_with   = merged_with,
    backend       = if ("backend" %in% names(res)) res$backend else NA_character_,
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL
  out
}

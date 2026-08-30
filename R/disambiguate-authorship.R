# ---- Authorship-aware homonym disambiguation ----
#
# A name reused by two authors (Pinus abies L. vs Pinus abies Thunb.) is a
# homonym: the same string points to different accepted taxa. Matching alone
# cannot separate them. But the query often carries the authorship that settles
# it, and an author the caller typed is an explicit choice of record, not a
# decoration -- so this pass runs over every matched row whose input carried
# one, not only the rows matching flagged `is_ambiguous`. A name that is unique
# in the backbone re-reads to a single row and resolves to what it already had,
# so the widening only bites where the backbone actually holds several records
# for the name (#53).
#
# The pass re-reads the backbone rows sharing the matched name, compares their
# authorship to the input's, and rewrites the row only when the author picks out
# exactly one accepted target. Rows without an input author are never touched.


#' Split an authorship citation into comparable author tokens
#'
#' Lowercases, strips accents, and cuts the citation at every non-alphanumeric
#' character, so `"(Mill.) D.A.Webb"` becomes `c("mill", "d", "a", "webb")`.
#' Unlike the squashed key from `normalize_authorship()`, this keeps the
#' abbreviation boundaries, which is what separates `L.` from `Lindl.`.
#'
#' @param x A single authorship string.
#' @return Character vector of tokens (empty when there are none).
#' @noRd
authorship_tokens <- function(x) {
  if (is.na(x)) return(character(0L))
  y <- .strip_accents(tolower(as.character(x)))
  y <- strsplit(gsub("[^a-z0-9]+", " ", y), " ", fixed = TRUE)[[1L]]
  y[nzchar(y)]
}

#' Whether an input citation is compatible with a backbone citation
#'
#' `TRUE` when every token of the input appears among the backbone row's
#' tokens -- an abbreviated citation read against a fuller one (`"L."` against
#' `"(L.) H.Karst."`). Token equality rather than substring containment is what
#' keeps `"L."` from matching `"Lindl."`; the substring rule this replaces let a
#' one-letter author key match nearly every citation.
#'
#' @param input_auth A single normalized-input authorship string.
#' @param cand_auth Character vector of backbone authorship strings.
#' @return Logical vector along `cand_auth`.
#' @noRd
authorship_compatible <- function(input_auth, cand_auth) {
  toks <- authorship_tokens(input_auth)
  if (length(toks) == 0L) return(rep(FALSE, length(cand_auth)))
  vapply(cand_auth, function(a) {
    ct <- authorship_tokens(a)
    length(ct) > 0L && all(toks %in% ct)
  }, logical(1L), USE.NAMES = FALSE)
}


#' Resolve homonyms by matching input authorship
#'
#' For each matched row whose input name carried an authorship, re-reads the
#' backbone rows sharing the matched name, compares their authorship to the
#' input's, and if exactly one accepted target survives, rewrites the row to that
#' resolution and clears any ambiguity. Rows with no input author, or where the
#' author does not single out one target, are left as they were.
#'
#' @param result The match result data.frame (post `run_match_stages`).
#' @param vtr_path Path to the backbone `.vtr`.
#' @return `result`, with any author-resolved rows rewritten.
#' @noRd
disambiguate_by_authorship <- function(result, vtr_path) {
  if (is.null(result$matched_name) || is.null(result$input_name)) return(result)
  rows <- which(!is.na(result$matched_name) & !is.na(result$input_name))
  if (length(rows) == 0L) return(result)

  auth_raw <- parse_authorship_vec(result$input_name[rows])
  auth_in  <- normalize_authorship(auth_raw)
  have_auth <- !is.na(auth_in)
  rows     <- rows[have_auth]
  auth_raw <- auth_raw[have_auth]
  auth_in  <- auth_in[have_auth]
  if (length(rows) == 0L) return(result)

  names_to_look <- unique(result$matched_name[rows])
  joined <- tryCatch(
    backbone_join(
      vtr_path, names_to_look, bb_key = "canonical_name",
      select_cols = c("canonical_name", "authorship", "taxon_id",
                      "accepted_taxon_id", "accepted_name", "is_synonym",
                      "taxon_rank", "accepted_family", "accepted_genus")),
    error = function(e) NULL)
  if (is.null(joined) || nrow(joined) == 0L ||
      !"authorship" %in% names(joined)) return(result)
  joined$auth_key <- normalize_authorship(joined$authorship)

  # One split, not a scan per row: the pass now sees every author-bearing input,
  # so a linear filter inside the loop would be quadratic on a large query set.
  by_name <- split(seq_len(nrow(joined)), joined$lookup)

  has_col <- function(nm) nm %in% names(result)

  for (k in seq_along(rows)) {
    i  <- rows[k]
    at <- by_name[[result$matched_name[i]]]
    if (is.null(at) || length(at) < 2L) next   # a unique name settles nothing
    cand <- joined[at, , drop = FALSE]

    # Exact author key first; then an abbreviated citation read against a fuller
    # one, compared token by token.
    hit <- which(!is.na(cand$auth_key) & cand$auth_key == auth_in[k])
    if (length(hit) == 0L) {
      hit <- which(authorship_compatible(auth_raw[k], cand$authorship))
    }
    if (length(hit) == 0L) next

    # Only resolve when the surviving rows agree on one accepted target.
    targets <- unique(cand$accepted_taxon_id[hit])
    targets <- targets[!is.na(targets)]
    if (length(targets) != 1L) next

    w <- hit[1L]
    if (has_col("taxon_id"))       result$taxon_id[i]       <- cand$taxon_id[w]
    if (has_col("authorship"))     result$authorship[i]     <- cand$authorship[w]
    if (has_col("accepted_id"))    result$accepted_id[i]    <- cand$accepted_taxon_id[w]
    if (has_col("accepted_name"))  result$accepted_name[i]  <- cand$accepted_name[w]
    if (has_col("is_synonym"))     result$is_synonym[i]     <- cand$is_synonym[w]
    if (has_col("rank") && "taxon_rank" %in% names(cand))
      result$rank[i] <- tolower(cand$taxon_rank[w])
    # Family/genus of the ACCEPTED taxon. `cand`/`w` is the matched synonym row,
    # so its own family/genus belong to the rejected homonym; embed_accepted()
    # carries the accepted taxon's classification on the accepted_* columns.
    if (has_col("family") && "accepted_family" %in% names(cand))
      result$family[i] <- cand$accepted_family[w]
    if (has_col("genus") && "accepted_genus" %in% names(cand))
      result$genus[i] <- cand$accepted_genus[w]
    if (has_col("is_ambiguous")) result$is_ambiguous[i] <- FALSE
    if (has_col("ambiguous_targets")) result$ambiguous_targets[i] <- NA_character_
  }
  result
}

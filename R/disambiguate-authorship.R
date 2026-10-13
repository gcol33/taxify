# ---- Authorship-aware homonym disambiguation ----
#
# A name reused by two authors (Pinus abies L. vs Pinus abies Thunb.) is a
# homonym: the same string points to different accepted taxa. Matching alone
# cannot separate them. But the query often carries the authorship that settles
# it, and an author the caller typed is an explicit choice of record, not a
# decoration -- so this pass runs over every matched row whose input carried
# one, not only the rows whose pick tied. A name that is unique
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
#' resolution and moves it to the front of `accepted_ids`; the other targets
#' stay listed, since the backbone still holds them under the name. Rows with no input author, or where the
#' author does not single out one target, are left as they were.
#'
#' @param result The match result data.frame (post `run_match_stages`).
#' @param vtr_path Path to the backbone `.vtr`.
#' @param input_authorship The authorship of each input, parallel to the rows
#'   of `result`, when the cleaner has parsed it (syntaxon names); `NULL` reads
#'   it from `input_name` with the taxon parser.
#' @param hierarchy Hierarchy columns of the backbone (`col_map$hierarchy`),
#'   rewritten with the resolution; `NULL` for none.
#' @return `result`, with any author-resolved rows rewritten.
#' @noRd
disambiguate_by_authorship <- function(result, vtr_path,
                                       input_authorship = NULL,
                                       hierarchy = NULL) {
  if (is.null(result$matched_name) || is.null(result$input_name)) return(result)
  rows <- which(!is.na(result$matched_name) & !is.na(result$input_name))
  if (length(rows) == 0L) return(result)

  auth_raw <- if (is.null(input_authorship)) {
    parse_authorship_vec(result$input_name[rows])
  } else {
    input_authorship[rows]
  }
  auth_in  <- normalize_authorship(auth_raw)
  have_auth <- !is.na(auth_in)
  rows     <- rows[have_auth]
  auth_raw <- auth_raw[have_auth]
  auth_in  <- auth_in[have_auth]
  if (length(rows) == 0L) return(result)

  names_to_look <- unique(result$matched_name[rows])
  joined <- name_records(vtr_path, names_to_look, hierarchy)
  if (is.null(joined) || nrow(joined) == 0L ||
      !"authorship" %in% names(joined)) return(result)
  joined$auth_key <- normalize_authorship(joined$authorship)

  # One split, not a scan per row: the pass now sees every author-bearing input,
  # so a linear filter inside the loop would be quadratic on a large query set.
  by_name <- split(seq_len(nrow(joined)), joined$lookup)

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

    result <- rewrite_pick(result, i, cand[hit[1L], , drop = FALSE],
                           hierarchy = hierarchy, basis = "authorship")
  }
  result
}


#' Every backbone record carrying one of a set of names
#'
#' The columns a post-pick stage needs to move a row to another record of the
#' same name: the record's own name and status, and its accepted taxon with that
#' taxon's author, family and genus. Shared by the authorship tiebreak and the
#' kingdom filter.
#'
#' @param vtr_path Path to the backbone `.vtr`.
#' @param names Canonical names to look up.
#' @param hierarchy Hierarchy columns of the backbone, or `NULL`.
#' @return A data.frame with a `lookup` column (the name asked for), or `NULL`
#'   when the backbone cannot be read.
#' @noRd
name_records <- function(vtr_path, names, hierarchy = NULL) {
  want_cols <- c("canonical_name", "authorship", "taxon_id",
                 "accepted_taxon_id", "accepted_name", "accepted_authorship",
                 "is_synonym", "taxonomic_status", "taxon_rank",
                 "accepted_family", "accepted_genus", hierarchy)
  available <- tryCatch(vtr_schema(vtr_path), error = function(e) NULL)
  if (is.null(available)) return(NULL)
  tryCatch(
    backbone_join(vtr_path, names, bb_key = "canonical_name",
                  select_cols = intersect(want_cols, available)),
    error = function(e) NULL)
}


#' Move a matched row to another record of the same name
#'
#' Rewrites row `i` of `result` to the backbone record `rec` (one row of
#' `name_records()`): the record's own ID, author, status and rank, and its
#' accepted taxon. The new accepted ID goes to the front of `accepted_ids`; the
#' previous target stays listed, since the backbone still holds it under the
#' name.
#'
#' @param result The match result data.frame.
#' @param i Row index to rewrite.
#' @param rec A one-row data.frame from `name_records()`.
#' @param hierarchy Hierarchy columns to rewrite, or `NULL`.
#' @param basis The stage that moved the row, recorded as its `pick_basis`.
#' @return `result` with row `i` rewritten.
#' @noRd
rewrite_pick <- function(result, i, rec, hierarchy = NULL, basis) {
  has_col <- function(nm) nm %in% names(result)
  result <- promote_accepted_id(result, i, rec$accepted_taxon_id, basis = basis)
  if (has_col("taxon_id"))       result$taxon_id[i]       <- rec$taxon_id
  if (has_col("authorship"))     result$authorship[i]     <- rec$authorship
  if (has_col("accepted_id"))    result$accepted_id[i]    <- rec$accepted_taxon_id
  if (has_col("accepted_name"))  result$accepted_name[i]  <- rec$accepted_name
  # `accepted_name` and `accepted_authorship` are one citation: writing the
  # name without its author would leave the rejected homonym's author beside
  # the selected name.
  if (has_col("accepted_authorship") && "accepted_authorship" %in% names(rec))
    result$accepted_authorship[i] <- rec$accepted_authorship
  if (has_col("is_synonym"))     result$is_synonym[i]     <- rec$is_synonym
  if (has_col("taxonomic_status") && "taxonomic_status" %in% names(rec))
    result$taxonomic_status[i] <- rec$taxonomic_status
  if (has_col("rank") && "taxon_rank" %in% names(rec))
    result$rank[i] <- tolower(rec$taxon_rank)
  # Family/genus of the ACCEPTED taxon. `rec` may be a synonym record, whose
  # own family/genus belong to the rejected homonym; embed_accepted() carries
  # the accepted taxon's classification on the accepted_* columns.
  if (has_col("family") && "accepted_family" %in% names(rec))
    result$family[i] <- rec$accepted_family
  if (has_col("genus") && "accepted_genus" %in% names(rec))
    result$genus[i] <- rec$accepted_genus
  for (h in intersect(hierarchy, intersect(names(rec), names(result))))
    result[[h]][i] <- rec[[h]]
  result
}

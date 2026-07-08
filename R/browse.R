# ---- Backbone browsing: reverse synonyms, classification, children ----
#
# taxify() resolves a name forward (synonym -> accepted). These verbs read the
# backbone the other ways: list the synonyms of an accepted name, attach the
# full higher classification, and list the accepted taxa contained in a genus or
# family. All three query the backbone .vtr directly through vectra.


#' Resolve a backend to its ready `.vtr` path
#'
#' Version-checks and downloads exactly as [taxify()] does, then returns the
#' local backbone path.
#'
#' @param backend A backend name or a `taxify_backend` object.
#' @param verbose Logical.
#' @return Character path to the backbone `.vtr`.
#' @noRd
backbone_path <- function(backend, verbose = TRUE) {
  if (inherits(backend, "taxify_backend")) {
    ensure_backends_current(backend$name, verbose = verbose)
    return(ensure_backbone(backend, verbose = verbose))
  }
  if (!is.character(backend) || length(backend) != 1L) {
    stop("backend must be a single backend name or a taxify_backend object.",
         call. = FALSE)
  }
  ensure_backends_current(backend, verbose = verbose)
  ensure_backbone(resolve_backend(backend), verbose = verbose)
}


#' Title-case a single taxon name (genus or family)
#' @noRd
title_case_taxon <- function(s) {
  s <- trimws(s)
  paste0(toupper(substring(s, 1L, 1L)), tolower(substring(s, 2L)))
}


#' Inner-join a backbone against a set of lookup values
#'
#' Writes the lookup values to a temp `.vtr` and inner-joins the backbone,
#' selecting `select_cols`, matching the vectorized pattern used throughout the
#' package.
#'
#' @param bb Backbone `.vtr` path.
#' @param values Character/other vector of lookup values.
#' @param bb_key Backbone column to join on.
#' @param select_cols Backbone columns to return (includes `bb_key`).
#' @param pre A function applied to `vectra::tbl(bb)` before the join (e.g. a
#'   `filter`), or NULL.
#' @return A collected data.frame with a `lookup` column plus `select_cols`.
#' @noRd
backbone_join <- function(bb, values, bb_key, select_cols, pre = NULL) {
  values <- unique(values[!is.na(values)])
  if (length(values) == 0L) return(NULL)
  lookup <- data.frame(lookup = values, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(lookup, tmp)
  right <- vectra::tbl(bb)
  if (!is.null(pre)) right <- pre(right)
  right <- right |> vectra::select(!!!lapply(unique(select_cols), as.name))
  vectra::inner_join(
    vectra::tbl(tmp), right,
    by = stats::setNames(bb_key, "lookup")
  ) |> vectra::collect()
}


#' List the synonyms of a name
#'
#' The reverse of the forward resolution [taxify()] does: each input name is
#' resolved to its accepted taxon, then every synonym that points to that
#' accepted taxon in the backbone is returned. Useful for auditing which
#' historical names collapse onto a current name.
#'
#' @param x Character vector of names (accepted names or synonyms; each is
#'   resolved to its accepted taxon first).
#' @param backend A single backend name (e.g. `"wfo"`) or a `taxify_backend`
#'   object. Default `"wfo"`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per synonym found, columns:
#' \describe{
#'   \item{input_name}{The queried name.}
#'   \item{accepted_name}{The accepted name the query resolved to.}
#'   \item{synonym}{A synonym of that accepted taxon.}
#'   \item{authorship}{Authorship of the synonym.}
#'   \item{rank}{Rank of the synonym.}
#'   \item{taxon_id}{Backend ID of the synonym.}
#'   \item{backend}{Backend used.}
#' }
#' Names that resolve to an accepted taxon with no synonyms contribute no rows.
#'
#' @seealso [taxify()] for the forward direction, [children()] to list the
#'   accepted taxa within a genus or family.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Amphibolurus vitticeps is a synonym of Pogona vitticeps
#' synonyms("Pogona vitticeps", backend = "reptiledb")
#'
#' options(old)
#'
#' @export
synonyms <- function(x, backend = "wfo", verbose = TRUE) {
  if (!is.character(x) || length(x) == 0L) {
    stop("x must be a non-empty character vector.", call. = FALSE)
  }
  be_name <- if (inherits(backend, "taxify_backend")) backend$name else backend
  bb <- backbone_path(backend, verbose = verbose)

  res <- taxify(x, backend = backend, fuzzy = TRUE, verbose = FALSE)
  keep <- !is.na(res$accepted_id)
  empty <- data.frame(
    input_name = character(0L), accepted_name = character(0L),
    synonym = character(0L), authorship = character(0L),
    rank = character(0L), taxon_id = character(0L), backend = character(0L),
    stringsAsFactors = FALSE
  )
  if (!any(keep)) return(empty)

  syn <- backbone_join(
    bb, res$accepted_id[keep], bb_key = "accepted_taxon_id",
    select_cols = c("accepted_taxon_id", "taxon_id", "canonical_name",
                    "authorship", "taxon_rank"),
    pre = function(t) vectra::filter(t, is_synonym == TRUE)
  )
  if (is.null(syn) || nrow(syn) == 0L) return(empty)

  # Expand: one row per (query, synonym) pointing to the same accepted taxon.
  q <- data.frame(
    accepted_id   = res$accepted_id[keep],
    input_name    = res$input_name[keep],
    accepted_name = res$accepted_name[keep],
    stringsAsFactors = FALSE
  )
  out <- merge(q, syn, by.x = "accepted_id", by.y = "lookup")
  if (nrow(out) == 0L) return(empty)

  out <- data.frame(
    input_name    = out$input_name,
    accepted_name = out$accepted_name,
    synonym       = out$canonical_name,
    authorship    = out$authorship,
    rank          = out$taxon_rank,
    taxon_id      = out$taxon_id,
    backend       = be_name,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$input_name, out$synonym), , drop = FALSE]
  rownames(out) <- NULL
  out
}


#' Add the full higher classification to a taxify result
#'
#' Attaches the Linnaean ranks above family (kingdom, phylum, class, order) to a
#' [taxify()] result by joining each matched row back to its backbone. The core
#' `taxify()` output already carries `family` and `genus`; this fills the ranks
#' above them, for whichever ranks the matched backbone stores. Rows matched by
#' different backends are each joined against their own backbone.
#'
#' @param x A data.frame returned by [taxify()].
#' @param ranks Character vector of ranks to attach. Default
#'   `c("kingdom", "phylum", "class", "order")`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return `x` with the requested rank columns added. A rank a backbone does not
#'   store is left `NA` (WFO, for example, carries no ranks above family).
#'
#' @seealso [add_col_info()], [add_gbif_info()] for backend-specific extras.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Naja naja", backend = "reptiledb") |>
#'   add_classification()
#'
#' options(old)
#'
#' @export
add_classification <- function(x, ranks = c("kingdom", "phylum", "class", "order"),
                               verbose = TRUE) {
  if (!is.data.frame(x) || !"accepted_id" %in% names(x)) {
    stop("x must be a taxify() result with an 'accepted_id' column.",
         call. = FALSE)
  }
  ranks <- as.character(ranks)
  for (r in ranks) if (!r %in% names(x)) x[[r]] <- NA_character_

  if (!"backend" %in% names(x)) return(x)
  bes <- unique(x$backend[!is.na(x$backend)])
  filled_any <- FALSE

  for (be_name in bes) {
    rows <- which(x$backend == be_name & !is.na(x$accepted_id))
    if (length(rows) == 0L) next
    bb <- tryCatch(backbone_path(be_name, verbose = verbose),
                   error = function(e) NULL)
    if (is.null(bb)) next
    schema <- names(vectra::collect(utils::head(vectra::tbl(bb), 1L)))
    avail <- intersect(ranks, schema)
    if (length(avail) == 0L) next

    joined <- backbone_join(
      bb, x$accepted_id[rows], bb_key = "taxon_id",
      select_cols = c("taxon_id", avail)
    )
    if (is.null(joined) || nrow(joined) == 0L) next
    joined <- joined[!duplicated(joined$lookup), , drop = FALSE]
    idx <- match(x$accepted_id[rows], joined$lookup)
    hit <- which(!is.na(idx))
    if (length(hit) == 0L) next
    for (r in avail) x[[r]][rows[hit]] <- joined[[r]][idx[hit]]
    filled_any <- TRUE
  }

  if (verbose && !filled_any) {
    message("add_classification(): no backbone in this result stores ranks ",
            "above family; classification columns left NA.")
  }
  x
}


#' Expand ambiguous matches into their candidate taxa
#'
#' Where [taxify()] meets an irreducible homonym -- a name whose synonyms point
#' to several accepted taxa at the same priority tier -- it records one candidate
#' in the scalar columns, sets `is_ambiguous = TRUE`, and lists the conflicting
#' accepted taxon IDs in `ambiguous_targets`. This verb expands those rows into
#' one row per candidate, resolved to full names against the backbone, so you can
#' choose the right taxon yourself instead of relying on the automatic tiebreak.
#'
#' @param x A [taxify()] result.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per (ambiguous input, candidate taxon):
#' \describe{
#'   \item{input_name}{The queried name.}
#'   \item{chosen}{The accepted name `taxify()` picked for that row.}
#'   \item{candidate}{A candidate accepted name.}
#'   \item{authorship}{Authorship of the candidate.}
#'   \item{rank}{Rank of the candidate.}
#'   \item{family}{Family of the candidate.}
#'   \item{genus}{Genus of the candidate.}
#'   \item{taxon_id}{Backend ID of the candidate.}
#'   \item{backend}{Backend used.}
#' }
#' Empty when no rows were ambiguous.
#'
#' @seealso [taxify()], [synonyms()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Homonyms are rare; on an unambiguous result this is an empty frame.
#' taxify("Quercus robur") |>
#'   taxify_candidates()
#'
#' options(old)
#'
#' @export
taxify_candidates <- function(x, verbose = TRUE) {
  req <- c("ambiguous_targets", "is_ambiguous", "backend", "accepted_id",
           "input_name", "accepted_name")
  if (!is.data.frame(x) || !all(req %in% names(x))) {
    stop("x must be a taxify() result with ambiguity columns.", call. = FALSE)
  }
  empty <- data.frame(
    input_name = character(0L), chosen = character(0L), candidate = character(0L),
    authorship = character(0L), rank = character(0L), family = character(0L),
    genus = character(0L), taxon_id = character(0L), backend = character(0L),
    stringsAsFactors = FALSE
  )
  amb <- which(!is.na(x$is_ambiguous) & x$is_ambiguous &
               !is.na(x$ambiguous_targets))
  if (length(amb) == 0L) {
    if (verbose) message("No ambiguous matches to expand.")
    return(empty)
  }

  # One (row, candidate id) per conflicting id, plus the chosen accepted id.
  long <- do.call(rbind, lapply(amb, function(i) {
    ids <- unique(c(x$accepted_id[i],
                    strsplit(x$ambiguous_targets[i], "\\|")[[1L]]))
    ids <- ids[!is.na(ids) & nzchar(ids)]
    if (length(ids) == 0L) return(NULL)
    data.frame(row = i, cand_id = ids, stringsAsFactors = FALSE)
  }))
  if (is.null(long) || nrow(long) == 0L) return(empty)

  out <- list()
  for (be_name in unique(x$backend[long$row])) {
    if (is.na(be_name)) next
    sub <- long[!is.na(x$backend[long$row]) & x$backend[long$row] == be_name, ,
                drop = FALSE]
    bb <- tryCatch(backbone_path(be_name, verbose = verbose),
                   error = function(e) NULL)
    if (is.null(bb)) next
    joined <- backbone_join(
      bb, sub$cand_id, bb_key = "taxon_id",
      select_cols = c("taxon_id", "canonical_name", "authorship", "taxon_rank",
                      "family", "genus")
    )
    if (is.null(joined) || nrow(joined) == 0L) next
    idx <- match(sub$cand_id, joined$lookup)
    hit <- which(!is.na(idx))
    if (length(hit) == 0L) next
    sub <- sub[hit, , drop = FALSE]
    idx <- idx[hit]
    out[[length(out) + 1L]] <- data.frame(
      input_name = x$input_name[sub$row],
      chosen     = x$accepted_name[sub$row],
      candidate  = joined$canonical_name[idx],
      authorship = joined$authorship[idx],
      rank       = joined$taxon_rank[idx],
      family     = joined$family[idx],
      genus      = joined$genus[idx],
      taxon_id   = sub$cand_id,
      backend    = be_name,
      stringsAsFactors = FALSE
    )
  }
  if (length(out) == 0L) return(empty)
  res <- do.call(rbind, out)
  res <- res[order(res$input_name, res$candidate), , drop = FALSE]
  rownames(res) <- NULL
  res
}


#' List the accepted taxa within a genus or family
#'
#' Returns the accepted taxa a backbone places inside a genus or family, so you
#' can build a checklist from the backbone rather than only validating one. The
#' parent is auto-detected: a genus is tried first, then a family.
#'
#' @param taxon A single genus or family name.
#' @param backend A single backend name (e.g. `"wfo"`) or a `taxify_backend`
#'   object. Default `"wfo"`.
#' @param rank Rank of the children to return (`"species"` by default), or
#'   `"any"` for every rank below the parent.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame of accepted taxa, columns: `name`, `authorship`, `rank`,
#'   `family`, `genus`, `taxon_id`, `parent_rank` (`"genus"` or `"family"`),
#'   `backend`. Empty if the parent is not found.
#'
#' @seealso [synonyms()], [taxify()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' children("Quercus")
#'
#' options(old)
#'
#' @export
children <- function(taxon, backend = "wfo", rank = "species", verbose = TRUE) {
  if (!is.character(taxon) || length(taxon) != 1L || is.na(taxon) ||
      !nzchar(trimws(taxon))) {
    stop("taxon must be a single non-empty name.", call. = FALSE)
  }
  be_name <- if (inherits(backend, "taxify_backend")) backend$name else backend
  bb <- backbone_path(backend, verbose = verbose)
  taxon <- title_case_taxon(taxon)

  parent <- taxon
  hits <- vectra::tbl(bb) |>
    vectra::filter(genus == parent & is_synonym == FALSE) |>
    vectra::select(canonical_name, authorship, taxon_rank, family, genus,
                   taxon_id) |>
    vectra::collect()
  parent_rank <- "genus"
  if (nrow(hits) == 0L) {
    hits <- vectra::tbl(bb) |>
      vectra::filter(family == parent & is_synonym == FALSE) |>
      vectra::select(canonical_name, authorship, taxon_rank, family, genus,
                     taxon_id) |>
      vectra::collect()
    parent_rank <- "family"
  }

  empty <- data.frame(
    name = character(0L), authorship = character(0L), rank = character(0L),
    family = character(0L), genus = character(0L), taxon_id = character(0L),
    parent_rank = character(0L), backend = character(0L),
    stringsAsFactors = FALSE
  )
  if (nrow(hits) == 0L) return(empty)

  if (!is.null(rank) && !identical(rank, "any")) {
    hits <- hits[!is.na(hits$taxon_rank) &
                 toupper(hits$taxon_rank) == toupper(rank), , drop = FALSE]
  }
  if (nrow(hits) == 0L) return(empty)

  out <- data.frame(
    name        = hits$canonical_name,
    authorship  = hits$authorship,
    rank        = hits$taxon_rank,
    family      = hits$family,
    genus       = hits$genus,
    taxon_id    = hits$taxon_id,
    parent_rank = parent_rank,
    backend     = be_name,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$name), , drop = FALSE]
  rownames(out) <- NULL
  out
}

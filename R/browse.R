# ---- Backbone browsing: reverse synonyms, classification, children ----
#
# taxify() resolves a name forward (synonym -> accepted). These verbs read the
# backbone the other ways: list the synonyms of an accepted name, attach the
# full higher classification, and list the accepted taxa contained in a genus or
# family. All three query the backbone .vtr directly through vectra.


#' Resolve a backbone to its ready `.vtr` path
#'
#' Version-checks and downloads exactly as [taxify()] does, then returns the
#' local backbone path.
#'
#' @param backbone A backbone name or a `taxify_backend` object.
#' @param verbose Logical.
#' @return Character path to the backbone `.vtr`.
#' @noRd
backbone_path <- function(backbone, verbose = TRUE) {
  if (inherits(backbone, "taxify_backend")) {
    ensure_backbones_current(backbone$name, verbose = verbose)
    return(ensure_backbone(backbone, verbose = verbose))
  }
  if (!is.character(backbone) || length(backbone) != 1L) {
    stop("backbone must be a single backbone name or a taxify_backend object.",
         call. = FALSE)
  }
  ensure_backbones_current(backbone, verbose = verbose)
  ensure_backbone(resolve_backend(backbone), verbose = verbose)
}


#' A zero-row data.frame with the columns and types of a `.vtr` file
#'
#' Reading them materializes the first row group, over a second on a large
#' backbone, so they are memoized for the session per path, size and
#' modification time: a file rewritten in place is read afresh.
#'
#' @param path Path to a `.vtr` file.
#' @return A data.frame with no rows.
#' @noRd
vtr_prototype <- function(path) {
  info <- file.info(path)
  key <- paste(normalizePath(path, mustWork = FALSE), info$size,
               as.numeric(info$mtime))
  hit <- memo_get(".vtr_proto", key)
  if (!is.null(hit)) return(hit)
  memo_set(".vtr_proto", key,
           vectra::collect(utils::head(vectra::tbl(path), 1L))[0L, , drop = FALSE])
}

#' Column names of a `.vtr` file
#'
#' @param path Path to a `.vtr` file.
#' @return Character vector of column names.
#' @noRd
vtr_schema <- function(path) names(vtr_prototype(path))


#' The name of a backbone given as a name or a `taxify_backend` object
#'
#' @param backbone A backbone name (or names) or a `taxify_backend` object.
#' @return Character.
#' @noRd
backbone_name_of <- function(backbone) {
  if (inherits(backbone, "taxify_backend")) backbone$name else backbone
}


#' Resolve a verb's input names through taxify()
#'
#' The one route by which the verbs that accept names ([synonyms()],
#' [upstream()], [sci2comm()], [comm2sci()], [reconcile()], [lowest_common()],
#' [class2tree()]) run them through [taxify()], so the matching arguments
#' (`fuzzy`, `fuzzy_threshold`, `fuzzy_method`, `aggregates`, `kingdom`,
#' `region`, `coords`, `range`) reach the matcher the same way from every verb.
#'
#' @param x Character vector of names.
#' @param backbone Passed to [taxify()].
#' @param ... Matching arguments passed to [taxify()]; must be named.
#' @param verbose Logical.
#' @return A `taxify_result`.
#' @noRd
taxify_input <- function(x, backbone, ..., verbose) {
  nms <- names(list(...))
  if (...length() > 0L && (is.null(nms) || any(!nzchar(nms)))) {
    stop("Arguments passed on to taxify() must be named ",
         "(e.g. fuzzy = FALSE).", call. = FALSE)
  }
  taxify(x, backbone = backbone, ..., verbose = verbose)
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
#' package. When matching has already loaded the backbone into memory this
#' session (`loaded_backbone_block()`) and the key is a string column, the rows
#' come from a hashed lookup on that copy instead of a scan of the file.
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
  blk <- if (is.null(pre)) loaded_backbone_block(bb)
  if (!is.null(blk) && is.character(vtr_prototype(bb)[[bb_key]])) {
    values <- as.character(values)
    hits <- vectra::block_lookup(blk, bb_key, values)
    out <- data.frame(lookup = values[hits$query_idx],
                      stringsAsFactors = FALSE)
    for (cc in setdiff(unique(select_cols), bb_key)) out[[cc]] <- hits[[cc]]
    return(out)
  }
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


#' Attach backbone columns to a taxify result (backbone-info doors)
#'
#' Shared engine behind [add_wfo_info()], [add_gbif_info()] and [add_col_info()]:
#' for the rows a given backbone matched, look up their `taxon_id` in that
#' backbone and attach extra columns through `backbone_join()` plus a vectorized
#' `match()` fill (the documented join strategy). An optional `extra_vtr`
#' describes a second join against a sidecar `.vtr` (COL's SpeciesProfile), whose
#' values are passed through a transform.
#'
#' @param x A [taxify()] result.
#' @param backbone A `taxify_backend` object.
#' @param col_map Named character vector: output column -> backbone source
#'   column. Output columns are attached as character.
#' @param enrichment_name,label Identifiers passed to `register_enrichment()`.
#' @param probe_cols Output columns whose non-NA state counts as enriched.
#' @param extra_vtr `NULL`, or a list with `suffix` (appended to the backbone
#'   path in place of `.vtr`), `key` (join column in the sidecar), `col_map`
#'   (output -> source), `na` (the sentinel the outputs are initialized to) and
#'   `transform` (applied to each filled value vector).
#' @return `x` with the attached columns and the enrichment registered.
#' @noRd
enrich_from_backbone <- function(x, backbone, col_map, enrichment_name, label,
                                 probe_cols, extra_vtr = NULL) {
  if (!"taxon_id" %in% names(x)) {
    stop("x must be a data.frame with a 'taxon_id' column (from taxify())",
         call. = FALSE)
  }

  be <- backbone
  vtr_path <- get_backbone_path(be$name)
  if (is.null(vtr_path)) {
    vtr_path <- tryCatch(taxify_load(be), error = function(e) NULL)
  }
  if (is.null(vtr_path) || !file.exists(vtr_path)) {
    stop(sprintf("%s backbone not found. Run taxify_download('%s') first.",
                 label, be$name), call. = FALSE)
  }

  # Typed NA init: character main columns, the sidecar's own sentinel for extras.
  for (out_col in names(col_map)) x <- set_col_value(x, out_col, NA_character_)
  if (!is.null(extra_vtr)) {
    for (out_col in names(extra_vtr$col_map)) {
      x <- set_col_value(x, out_col, extra_vtr$na)
    }
  }

  rows <- which(!is.na(x$taxon_id) &
                (!is.na(x$backbone) & x$backbone == be$name))

  # Main join: attach the backbone columns present in the schema.
  if (length(rows) > 0L) {
    schema <- vtr_schema(vtr_path)
    avail  <- intersect(unname(col_map), schema)
    if (length(avail) > 0L) {
      joined <- backbone_join(vtr_path, x$taxon_id[rows], bb_key = "taxon_id",
                              select_cols = c("taxon_id", avail))
      if (!is.null(joined) && nrow(joined) > 0L) {
        joined <- joined[!duplicated(joined$lookup), , drop = FALSE]
        idx <- match(x$taxon_id[rows], joined$lookup)
        hit <- which(!is.na(idx))
        for (out_col in names(col_map)) {
          src <- col_map[[out_col]]
          if (src %in% names(joined)) {
            x[[out_col]][rows[hit]] <- joined[[src]][idx[hit]]
          }
        }
      }
    }
  }

  # Sidecar join (COL SpeciesProfile): keyed on taxon_id, values transformed.
  if (!is.null(extra_vtr) && length(rows) > 0L) {
    sp_path <- sub("\\.vtr$", extra_vtr$suffix, vtr_path)
    if (file.exists(sp_path)) {
      sp_schema <- tryCatch(vtr_schema(sp_path),
                            error = function(e) character(0L))
      avail_ex <- intersect(unname(extra_vtr$col_map), sp_schema)
      if (extra_vtr$key %in% sp_schema && length(avail_ex) > 0L) {
        sp <- tryCatch(
          backbone_join(sp_path, x$taxon_id[rows], bb_key = extra_vtr$key,
                        select_cols = c(extra_vtr$key, avail_ex)),
          error = function(e) NULL)
        if (!is.null(sp) && nrow(sp) > 0L) {
          sp <- sp[!duplicated(sp$lookup), , drop = FALSE]
          idx <- match(x$taxon_id[rows], sp$lookup)
          hit <- which(!is.na(idx))
          for (out_col in names(extra_vtr$col_map)) {
            src <- extra_vtr$col_map[[out_col]]
            if (src %in% names(sp)) {
              x[[out_col]][rows[hit]] <- extra_vtr$transform(sp[[src]][idx[hit]])
            }
          }
        }
      }
    }
  }

  bb_meta <- read_backbone_meta(vtr_path)
  ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
  n_enriched <- sum(rowSums(!is.na(x[, probe_cols, drop = FALSE])) > 0L)
  register_enrichment(x, enrichment_name, label, ver, n_enriched)
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
#' @param backbone A single backbone name (e.g. `"wfo"`) or a `taxify_backend`
#'   object. `NULL` (default) uses the highest-priority installed backbone.
#' @param ... Matching arguments passed to [taxify()] when resolving `x`
#'   (e.g. `fuzzy`, `fuzzy_threshold`, `kingdom`, `region`). Must be named.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per (distinct input name, synonym); a name
#'   supplied more than once is reported once. Columns:
#' \describe{
#'   \item{input_name}{The queried name.}
#'   \item{accepted_name}{The accepted name the query resolved to.}
#'   \item{synonym}{A synonym of that accepted taxon.}
#'   \item{authorship}{Authorship of the synonym.}
#'   \item{rank}{Rank of the synonym.}
#'   \item{taxon_id}{Backend ID of the synonym.}
#'   \item{backbone}{Backend used.}
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
#' synonyms("Pogona vitticeps", backbone = "reptiledb")
#'
#' options(old)
#'
#' @export
synonyms <- function(x, backbone = NULL, ..., verbose = TRUE) {
  if (!is.character(x) || length(x) == 0L) {
    stop("x must be a non-empty character vector.", call. = FALSE)
  }
  backbone <- resolve_single_backend(backbone, verbose = verbose)
  bb_name <- backbone_name_of(backbone)
  bb <- backbone_path(backbone, verbose = verbose)

  res <- taxify_input(unique(x), backbone = backbone, ..., verbose = FALSE)
  keep <- !is.na(res$accepted_id)
  empty <- data.frame(
    input_name = character(0L), accepted_name = character(0L),
    synonym = character(0L), authorship = character(0L),
    rank = character(0L), taxon_id = character(0L), backbone = character(0L),
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
    backbone       = bb_name,
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
#' different backbones are each joined against their own backbone.
#'
#' @param x A data.frame returned by [taxify()].
#' @param ranks Character vector of ranks to attach. Default
#'   `c("kingdom", "phylum", "class", "order")`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return `x` with the requested rank columns added. A rank a backbone does not
#'   store is left `NA` (WFO, for example, carries no ranks above family).
#'
#' @seealso [add_col_info()], [add_gbif_info()] for backbone-specific extras.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Naja naja", backbone = "reptiledb") |>
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

  if (!"backbone" %in% names(x)) return(x)
  bes <- unique(x$backbone[!is.na(x$backbone)])
  filled_any <- FALSE

  for (bb_name in bes) {
    rows <- which(x$backbone == bb_name & !is.na(x$accepted_id))
    if (length(rows) == 0L) next
    bb <- tryCatch(backbone_path(bb_name, verbose = verbose),
                   error = function(e) NULL)
    if (is.null(bb)) next
    schema <- vtr_schema(bb)
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
#'   \item{backbone}{Backend used.}
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
  req <- c("ambiguous_targets", "is_ambiguous", "backbone", "accepted_id",
           "input_name", "accepted_name")
  if (!is.data.frame(x) || !all(req %in% names(x))) {
    stop("x must be a taxify() result with ambiguity columns.", call. = FALSE)
  }
  empty <- data.frame(
    input_name = character(0L), chosen = character(0L), candidate = character(0L),
    authorship = character(0L), rank = character(0L), family = character(0L),
    genus = character(0L), taxon_id = character(0L), backbone = character(0L),
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
  for (bb_name in unique(x$backbone[long$row])) {
    if (is.na(bb_name)) next
    sub <- long[!is.na(x$backbone[long$row]) & x$backbone[long$row] == bb_name, ,
                drop = FALSE]
    bb <- tryCatch(backbone_path(bb_name, verbose = verbose),
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
      backbone    = bb_name,
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
#' parent's rank is read from the backbone, as in [downstream()], restricted to
#' genus and family: `children()` is [downstream()] for a genus or family parent.
#'
#' @param taxon A single genus or family name.
#' @param backbone A single backbone name (e.g. `"wfo"`) or a `taxify_backend`
#'   object. `NULL` (default) uses the highest-priority installed backbone.
#' @param rank Rank of the children to return (`"species"` by default), or
#'   `"any"` (or `NULL`) for every rank below the parent. The parent itself is
#'   never returned.
#' @param kingdom Optional kingdom (or kingdoms) the parent belongs to, as in
#'   [taxify()] (`"plantae"`, `"animals"`, ...). A genus or family name can be
#'   used in more than one kingdom (*Morus* is both mulberries and gannets);
#'   `kingdom` picks one. Without it such a result mixes the kingdoms, with a
#'   warning.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame of accepted taxa, columns: `name`, `authorship`, `rank`,
#'   `kingdom_group`, `family`, `genus`, `taxon_id`, `parent`, `parent_rank`
#'   (`"genus"` or `"family"`), `backbone`. Empty if the parent is not found.
#'
#' @seealso [downstream()] to reach below a higher rank, [synonyms()],
#'   [taxify()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' children("Quercus", backbone = "wfo")
#'
#' options(old)
#'
#' @export
children <- function(taxon, backbone = NULL, rank = "species", kingdom = NULL,
                     verbose = TRUE) {
  collect_descendants(taxon, backbone = backbone, target_rank = rank,
                      kingdom = kingdom, parent_cols = c("genus", "family"),
                      caller = "children", verbose = verbose)
}

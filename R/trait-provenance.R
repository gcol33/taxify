# Per-value provenance: the references behind each trait value.
#
# An enrichment built with provenance (see taxifydb's attach_references())
# carries, beside a value column `<col>`, a `<col>_source` column of reference
# ids joined by "|", and ships a reference table `<name>_references.vtr` the
# ids resolve against. Its installed meta.json declares the table under
# `references`. At runtime the ids are qualified by the enrichment they come
# from (`austraits:Falster_2005`), since two sources may use the same id for
# different works; cite() resolves qualified ids to citations.


#' Reference table path of an installed enrichment build
#'
#' @param vtr_path Path to the enrichment `.vtr`.
#' @param name Enrichment name.
#' @return The path of the table when the build declares one, else `NULL`.
#' @noRd
enrichment_references_path <- function(vtr_path, name) {
  meta <- read_enrichment_meta(vtr_path)
  refs <- meta$references
  if (is.null(refs)) return(NULL)
  file <- refs$file %||% paste0(name, "_references.vtr")
  file.path(dirname(vtr_path), file)
}


#' Qualify reference cells with the enrichment they came from
#'
#' `"D1|D2"` from `austraits` becomes `"austraits:D1|austraits:D2"`.
#' @noRd
qualify_refs <- function(cells, source) {
  out <- rep(NA_character_, length(cells))
  ok  <- !is.na(cells) & nzchar(cells)
  out[ok] <- vapply(strsplit(cells[ok], "|", fixed = TRUE), function(p) {
    p <- p[nzchar(p)]
    paste(paste0(source, ":", p), collapse = "|")
  }, character(1L))
  out[!is.na(out) & !nzchar(out)] <- NA_character_
  out
}


#' Join reference cells into one: distinct ids, C-locale order
#' @noRd
join_refs <- function(cells) {
  ids <- unlist(strsplit(cells[!is.na(cells)], "|", fixed = TRUE),
                use.names = FALSE)
  ids <- ids[nzchar(ids)]
  if (!length(ids)) return(NA_character_)
  paste(sort(unique(ids), method = "radix"), collapse = "|")
}


#' Qualified reference ids behind one trait source's values
#'
#' Joins the source's `<col>_source` column through the same engine the value
#' took (`.trait_join_one()`), so aggregate fallback and cross-backbone recovery
#' reach the same rows. A source whose build declares no reference table, or
#' whose `.vtr` has no provenance column for this trait, yields all `NA`. Rows
#' where the harmonized value is `NA` (no record, or a value the crosswalk does
#' not map) carry no references.
#'
#' @param x The taxify result.
#' @param sp The registry source slot.
#' @param value The source's harmonized values, aligned to `x`.
#' @return Character vector aligned to `x`.
#' @noRd
.trait_join_refs <- function(x, sp, value,
                             aggregate_trait_fallback =
                               getOption("taxify.aggregate_trait_fallback", TRUE)) {
  na  <- rep(NA_character_, nrow(x))
  vtr <- tryCatch(ensure_enrichment(sp$enrichment, verbose = FALSE),
                  error = function(e) NULL)
  if (is.null(vtr) || is.null(enrichment_references_path(vtr, sp$enrichment))) {
    return(na)
  }
  scol <- paste0(sp$col, "_source")
  if (!scol %in% vtr_schema(vtr)) return(na)
  raw <- .trait_join_one(x, sp$enrichment, scol, "categorical",
                         join_col = sp$join_col %||% "accepted_name",
                         group = sp$group, warn = FALSE,
                         aggregate_trait_fallback = aggregate_trait_fallback)
  if (is.null(raw)) return(na)
  raw[is.na(value)] <- NA_character_
  qualify_refs(raw, sp$enrichment)
}


#' References behind each coalesced value
#'
#' The sources that produced a row's reported value, and the union of their
#' references. Under `"first"` and `"complete"` that is the one source named;
#' under `"median"` and `"mean"` every source entering the aggregate; under
#' `"vote"`, `"min"` and `"max"` only the sources whose value equals the one
#' reported.
#'
#' @param per_src Named list of per-source harmonized values, priority order.
#' @param per_refs Named list of per-source qualified reference cells.
#' @param co The `.coalesce_sources()` result.
#' @param combine The reducer that produced `co`.
#' @return Character vector aligned to the rows.
#' @noRd
.coalesce_refs <- function(per_src, per_refs, co, combine) {
  n   <- length(co$value)
  out <- rep(NA_character_, n)
  exact <- combine %in% c("vote", "min", "max")
  for (i in which(!is.na(co$value) & !is.na(co$source))) {
    srcs <- strsplit(co$source[i], ",", fixed = TRUE)[[1L]]
    if (exact) {
      srcs <- srcs[vapply(srcs, function(s) {
        v <- per_src[[s]][i]
        !is.na(v) && v == co$value[i]
      }, logical(1L))]
    }
    out[i] <- join_refs(vapply(srcs, function(s) per_refs[[s]][i],
                               character(1L)))
  }
  out
}


#' Split qualified reference ids into source and id
#'
#' @param ids Character vector of cells, each `|`-joined.
#' @param source `NULL` for qualified ids (`<enrichment>:<id>`, split at the
#'   first colon), or one enrichment name the bare ids belong to.
#' @return data.frame with `ref`, `source`, `ref_id`, one row per distinct id
#'   in order of first appearance.
#' @noRd
parse_ref_ids <- function(ids, source = NULL) {
  toks <- unlist(strsplit(as.character(ids[!is.na(ids)]), "|", fixed = TRUE),
                 use.names = FALSE)
  toks <- unique(trimws(toks[nzchar(trimws(toks))]))
  if (!is.null(source)) {
    return(data.frame(ref = paste0(source, ":", toks),
                      source = rep(source, length(toks)), ref_id = toks,
                      stringsAsFactors = FALSE))
  }
  pos <- regexpr(":", toks, fixed = TRUE)
  bare <- toks[pos < 1L]
  if (length(bare)) {
    stop(sprintf(
      paste0("Reference id(s) without a source prefix: %s. Pass `source =` ",
             "for ids read straight from an enrichment's <col>_source column."),
      paste(utils::head(bare, 5L), collapse = ", ")), call. = FALSE)
  }
  data.frame(ref = toks, source = substr(toks, 1L, pos - 1L),
             ref_id = substring(toks, pos + 1L), stringsAsFactors = FALSE)
}


#' Look up reference ids in the enrichments' reference tables
#'
#' @param parsed A `parse_ref_ids()` result.
#' @return `parsed` with `citation` and `doi` (plus any further columns the
#'   tables carry). An id absent from its table keeps `NA` and is warned about;
#'   an id the table holds without a citation (a source naming a reference it
#'   does not cite) keeps `NA` quietly, with the table's `note` where it has one.
#' @noRd
resolve_ref_ids <- function(parsed) {
  parsed$citation <- rep(NA_character_, nrow(parsed))
  parsed$doi      <- rep(NA_character_, nrow(parsed))
  found           <- rep(FALSE, nrow(parsed))
  for (src in unique(parsed$source)) {
    vtr <- ensure_enrichment(src, verbose = FALSE)
    if (is.null(vtr)) {
      stop(sprintf("Enrichment '%s' is not available.", src), call. = FALSE)
    }
    path <- enrichment_references_path(vtr, src)
    if (is.null(path) || !file.exists(path)) {
      stop(sprintf(
        paste0("Enrichment '%s' has no reference table installed. Its build ",
               "may predate per-value provenance; reinstall it with ",
               "taxify_download_enrichment(\"%s\")."), src, src),
        call. = FALSE)
    }
    tab <- as.data.frame(vectra::collect(vectra::tbl(path)),
                         stringsAsFactors = FALSE)
    rows <- which(parsed$source == src)
    at   <- match(parsed$ref_id[rows], as.character(tab$ref_id))
    found[rows] <- !is.na(at)
    for (col in setdiff(names(tab), "ref_id")) {
      if (!col %in% names(parsed)) parsed[[col]] <- rep(NA, nrow(parsed))
      parsed[[col]][rows] <- tab[[col]][at]
    }
  }
  miss <- parsed$ref[!found]
  if (length(miss)) {
    warning(sprintf("%d reference id(s) not found in their source's table: %s",
                    length(miss), paste(utils::head(miss, 5L), collapse = ", ")),
            call. = FALSE)
  }
  parsed
}

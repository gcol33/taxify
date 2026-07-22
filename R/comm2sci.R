# ---- Common (vernacular) name -> scientific name ----
#
# taxify() and the backbones take scientific names. This is the reverse door:
# resolve a common name ("polar bear", "oak") to the accepted scientific
# name(s) it stands for, by reading the bundled `common_names` enrichment the
# other direction. add_common_names() goes scientific -> common; comm2sci()
# goes common -> scientific.


#' Case variants of a common name for a case-tolerant lookup
#'
#' Vernacular tables store names inconsistently cased ("Polar Bear", "polar
#' bear", "OAK"). Rather than scan and lowercase the whole column, we look up a
#' small bounded set of the likely casings through the fast indexed join.
#'
#' @param s Character scalar.
#' @return Character vector of distinct case variants.
#' @noRd
common_name_variants <- function(s) {
  s <- trimws(s)
  low   <- tolower(s)
  up    <- toupper(s)
  sent  <- paste0(toupper(substring(low, 1L, 1L)), substring(low, 2L))
  words <- strsplit(low, "\\s+")[[1L]]
  title <- paste(paste0(toupper(substring(words, 1L, 1L)),
                        substring(words, 2L)), collapse = " ")
  unique(c(s, low, up, sent, title))
}


#' Resolve common (vernacular) names to scientific names
#'
#' The reverse of [add_common_names()]: given a common name, return the accepted
#' scientific name(s) it refers to. Reads the bundled `common_names` enrichment
#' (GBIF, NCBI, and Open Tree vernaculars) offline; the first call may trigger
#' the one-time download. A common name is frequently ambiguous (several species
#' share "bluebell", "robin"), so the result can carry more than one row per
#' query.
#'
#' @param x Character vector of common names.
#' @param lang Character. Restrict to one language: an ISO 639-1 code (`"en"`,
#'   `"de"`, ...) as used by the GBIF source, or `NA` for the untagged
#'   NCBI/Open Tree names. `NULL` (default) searches every language. List the
#'   languages present with `enrichment_groups("common_names")`.
#' @param resolve Logical. When `FALSE` (default), return the lookup table
#'   (common name -> scientific name). When `TRUE`, run the matched scientific
#'   names through [taxify()] and return a `taxify_result` (with a leading
#'   `query_common` column), so the result pipes straight into the `add_*()`
#'   enrichments.
#' @param backbone Passed to [taxify()] when `resolve = TRUE`; `NULL` (default)
#'   uses every installed backbone. Ignored when `resolve = FALSE`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return When `resolve = FALSE`, a data.frame with one row per
#'   (query, scientific match):
#' \describe{
#'   \item{input_name}{The common name as supplied.}
#'   \item{common_name}{The vernacular name as stored in the source (its
#'     casing, which may differ from `input_name`).}
#'   \item{accepted_name}{The accepted scientific name.}
#'   \item{lang}{Language tag of the vernacular name (`NA` for NCBI/Open Tree).}
#' }
#' A query with no match contributes no rows. When `resolve = TRUE`, a
#' `taxify_result` for the distinct matched scientific names, with `query_common`
#' prepended.
#'
#' @seealso [add_common_names()] for the forward direction (scientific ->
#'   common), [taxify()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # The bundled example database maps "example_common_name" to Quercus robur;
#' # against the full download this is where "pedunculate oak" would resolve.
#' comm2sci("example_common_name")
#'
#' # Resolve straight to a taxify_result you can enrich
#' comm2sci("example_common_name", resolve = TRUE, backbone = "wfo")
#'
#' options(old)
#'
#' @export
comm2sci <- function(x, lang = NULL, resolve = FALSE, backbone = NULL,
                     verbose = TRUE) {
  if (!is.character(x) || length(x) == 0L) {
    stop("x must be a non-empty character vector.", call. = FALSE)
  }
  x_in <- x[!is.na(x) & nzchar(trimws(x))]

  empty <- data.frame(
    input_name = character(0L), common_name = character(0L),
    accepted_name = character(0L), lang = character(0L),
    stringsAsFactors = FALSE
  )
  if (length(x_in) == 0L) {
    if (resolve) return(taxify(character(0L), backbone = backbone,
                               verbose = FALSE))
    return(empty)
  }

  vtr_path <- ensure_enrichment("common_names", verbose = verbose)
  if (is.null(vtr_path)) {
    stop(paste0(
      "comm2sci(): the 'common_names' data is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      call. = FALSE)
  }

  # variant -> query map (many variants per query), then one indexed join.
  vmap <- do.call(rbind, lapply(x_in, function(q) {
    data.frame(input_name = q, variant = common_name_variants(q),
               stringsAsFactors = FALSE)
  }))
  vmap <- vmap[!duplicated(vmap[c("input_name", "variant")]), , drop = FALSE]

  hit <- .enrichment_vtr_lookup(
    vtr_path, join_key = "common_name",
    keys = vmap$variant, src_cols = c("canonical_name", "lang"))
  if (is.null(hit) || nrow(hit) == 0L) {
    if (resolve) return(taxify(character(0L), backbone = backbone,
                               verbose = FALSE))
    return(empty)
  }

  # Map each matched vernacular (lookup_name == the variant) back to its input_name.
  out <- merge(vmap, hit, by.x = "variant", by.y = "lookup_name")
  if (nrow(out) == 0L) {
    if (resolve) return(taxify(character(0L), backbone = backbone,
                               verbose = FALSE))
    return(empty)
  }

  if (!is.null(lang)) {
    out <- if (length(lang) == 1L && is.na(lang)) {
      out[is.na(out$lang), , drop = FALSE]
    } else {
      out[!is.na(out$lang) & out$lang %in% lang, , drop = FALSE]
    }
  }
  if (nrow(out) == 0L) {
    if (resolve) return(taxify(character(0L), backbone = backbone,
                               verbose = FALSE))
    return(empty)
  }

  tab <- data.frame(
    input_name           = out$input_name,
    common_name     = out$variant,
    accepted_name = out$canonical_name,
    lang            = out$lang,
    stringsAsFactors = FALSE
  )
  tab <- tab[!duplicated(tab[c("input_name", "accepted_name", "lang")]), ,
             drop = FALSE]
  tab <- tab[order(tab$input_name, tab$accepted_name,
                   is.na(tab$lang), tab$lang), , drop = FALSE]
  rownames(tab) <- NULL

  if (!resolve) return(tab)

  # Resolve the distinct scientific names, then re-expand to keep every input_name
  # (a query can map to several names, a name to several queries).
  sci <- unique(tab$accepted_name)
  res <- taxify(sci, backbone = backbone, verbose = verbose)
  ridx <- match(tab$accepted_name, res$input_name)
  resolved <- res[ridx, , drop = FALSE]
  resolved <- cbind(query_common = tab$input_name, resolved,
                    stringsAsFactors = FALSE)
  rownames(resolved) <- NULL
  meta <- attr(res, "taxify_meta")
  attr(resolved, "taxify_meta") <- meta
  class(resolved) <- c("taxify_result", "data.frame")
  resolved
}


#' Resolve scientific names to common (vernacular) names
#'
#' The forward direction of [comm2sci()]: given a scientific name, return the
#' common name(s) it is known by. Reads the bundled `common_names` enrichment
#' (GBIF, NCBI, and Open Tree vernaculars) offline; the first call may trigger
#' the one-time download. Where [add_common_names()] attaches vernaculars to a
#' [taxify()] result as columns, `sci2comm()` takes bare names and returns the
#' long lookup table -- one row per (name, vernacular). A name maps to many
#' common names (across languages and synonyms), so a query can carry several
#' rows.
#'
#' @param x Character vector of scientific names.
#' @param lang Character. Restrict to one language: an ISO 639-1 code (`"en"`,
#'   `"de"`, ...) as used by the GBIF source, or `NA` for the untagged
#'   NCBI/Open Tree names. `NULL` (default) returns every language. List the
#'   languages present with `enrichment_groups("common_names")`.
#' @param resolve Logical. When `TRUE` (default), each input is run through
#'   [taxify()] first so a synonym or misspelling reports its accepted taxon's
#'   vernaculars. When `FALSE`, the input name is looked up verbatim (faster,
#'   offline; use when the names are already accepted).
#' @param backbone Passed to [taxify()] when `resolve = TRUE`; `NULL` (default)
#'   uses every installed backbone. Ignored when `resolve = FALSE`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per (query, vernacular):
#' \describe{
#'   \item{input_name}{The scientific name as supplied.}
#'   \item{accepted_name}{The accepted name looked up (equals `input_name` when
#'     `resolve = FALSE` or the input_name was already accepted).}
#'   \item{common_name}{A vernacular name.}
#'   \item{lang}{Language tag (`NA` for NCBI/Open Tree).}
#' }
#' A query with no vernacular contributes no rows.
#'
#' @seealso [comm2sci()] for the reverse direction (common -> scientific),
#'   [add_common_names()] to attach vernaculars to a [taxify()] result.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # The bundled example maps Quercus robur -> "example_common_name" (en + de)
#' sci2comm("Quercus robur", resolve = FALSE)
#'
#' options(old)
#'
#' @export
sci2comm <- function(x, lang = NULL, resolve = TRUE, backbone = NULL,
                     verbose = TRUE) {
  if (!is.character(x) || length(x) == 0L) {
    stop("x must be a non-empty character vector.", call. = FALSE)
  }
  x_in <- x[!is.na(x) & nzchar(trimws(x))]

  empty <- data.frame(
    input_name = character(0L), accepted_name = character(0L),
    common_name = character(0L), lang = character(0L),
    stringsAsFactors = FALSE
  )
  if (length(x_in) == 0L) return(empty)

  vtr_path <- ensure_enrichment("common_names", verbose = verbose)
  if (is.null(vtr_path)) {
    stop(paste0(
      "sci2comm(): the 'common_names' data is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      call. = FALSE)
  }

  # input_name -> the scientific name to look up (accepted name when resolving).
  if (resolve) {
    res <- taxify(x_in, backbone = backbone, fuzzy = TRUE, verbose = verbose)
    acc <- data.frame(input_name = res$input_name,
                      accepted_name = res$accepted_name,
                      stringsAsFactors = FALSE)
    acc <- acc[!is.na(acc$accepted_name), , drop = FALSE]
  } else {
    acc <- data.frame(input_name = x_in, accepted_name = x_in,
                      stringsAsFactors = FALSE)
  }
  if (nrow(acc) == 0L) return(empty)

  hit <- .enrichment_vtr_lookup(
    vtr_path, join_key = "canonical_name",
    keys = acc$accepted_name, src_cols = c("common_name", "lang"))
  if (is.null(hit) || nrow(hit) == 0L) return(empty)

  out <- merge(acc, hit, by.x = "accepted_name", by.y = "lookup_name")
  if (nrow(out) == 0L) return(empty)

  if (!is.null(lang)) {
    out <- if (length(lang) == 1L && is.na(lang)) {
      out[is.na(out$lang), , drop = FALSE]
    } else {
      out[!is.na(out$lang) & out$lang %in% lang, , drop = FALSE]
    }
  }
  if (nrow(out) == 0L) return(empty)

  tab <- data.frame(
    input_name           = out$input_name,
    accepted_name = out$accepted_name,
    common_name     = out$common_name,
    lang            = out$lang,
    stringsAsFactors = FALSE
  )
  tab <- tab[!duplicated(tab[c("input_name", "common_name", "lang")]), , drop = FALSE]
  tab <- tab[order(tab$input_name, is.na(tab$lang), tab$lang, tab$common_name), ,
             drop = FALSE]
  rownames(tab) <- NULL
  tab
}

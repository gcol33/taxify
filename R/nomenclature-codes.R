# ---- Nomenclature codes: which name pipeline a backbone runs ----
#
# A backbone holds the names of one nomenclature. The taxon backbones hold
# botanical, zoological and prokaryote names (genus + epithet, the ICN / ICZN /
# ICNP shape); a syntaxon backbone holds vegetation units under the
# International Code of Phytosociological Nomenclature. The matching engine
# (exact -> case-insensitive -> normalized key -> blocked fuzzy) is shared, but
# how a written name is cleaned, which key folds its spelling variants, which
# stages apply and which hierarchy the result reports differ by code. Each code
# is one entry here; a backbone names its code in `.backbone_registry()`, and
# the engine reads the entry through `code_spec()`.


# Column map of a syntaxon backbone .vtr. The block key the fuzzy pass groups
# candidates by is the name's first word (`block_key`), the counterpart of a
# taxon backbone's genus. `hierarchy` lists the accepted unit's ancestor
# columns, broadest first, which every match writes into the result.
.syntaxon_col_map <- list(
  name       = "canonical_name",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  genus      = "block_key",
  id         = "taxon_id",
  rank       = "taxon_rank",
  status     = "taxonomic_status",
  acc_id     = "accepted_name_usage_id",
  authorship = "authorship",
  acc_name   = "accepted_name",
  is_synonym = "is_synonym",
  hierarchy  = c("class", "order", "alliance", "association")
)


#' The nomenclature codes taxify matches names under
#'
#' Fields of each entry:
#' \describe{
#'   \item{label}{Human label for messages.}
#'   \item{clean}{The cleaner: written names -> the engine's names frame.}
#'   \item{normalize}{The normalization key, applied to the query at match
#'     time and to the backbone at build time by `precompute_keys()`.}
#'   \item{col_map}{Column map of the code's backbones.}
#'   \item{genus_structure}{Whether names have a genus/epithet structure. The
#'     stages that read it (abbreviated genus, the species fallback of an
#'     infraspecific name, the genus register's kingdom and life form, the
#'     out-of-scope prefilter, hybrid formulas, aggregates, basionyms) run only
#'     for such a code.}
#'   \item{fuzzy_filter}{`NULL`, or a function `(matches, names_df, name_col)`
#'     dropping fuzzy candidates the code rules out.}
#'   \item{pre_fuzzy}{`NULL`, or a stage `(backend, result, names_df,
#'     vtr_path)` run between the exact passes and the fuzzy pass, for the
#'     code's own ways of writing a name short (a syntaxon without its
#'     epithets).}
#'   \item{post_fuzzy}{`NULL`, or a stage of the same shape run after the
#'     fuzzy pass.}
#'   \item{drop_cols}{Result columns that do not apply to the code.}
#' }
#' @return A named list of code entries.
#' @noRd
.nomenclature_codes <- function() {
  list(
    taxon = list(
      label           = "taxonomic",
      clean           = clean_names,
      normalize       = normalize_epithets,
      col_map         = .backbone_col_map,
      genus_structure = TRUE,
      fuzzy_filter    = NULL,
      pre_fuzzy       = NULL,
      post_fuzzy      = NULL,
      drop_cols       = character(0L)
    ),
    syntaxon = list(
      label           = "syntaxonomic",
      clean           = clean_syntaxon_names,
      normalize       = normalize_syntaxon_name,
      col_map         = .syntaxon_col_map,
      genus_structure = FALSE,
      fuzzy_filter    = filter_fuzzy_syntaxon,
      pre_fuzzy       = match_syntaxon_query_short,
      post_fuzzy      = match_syntaxon_backbone_short,
      drop_cols       = c("family", "genus", "epithet", "is_hybrid",
                          "hybrid_type", "aggregate_fallback", "kingdom_group",
                          "taxon_group", "life_form", "qualifier_position")
    )
  )
}


#' One nomenclature code's entry
#'
#' @param code A code name (`"taxon"`, `"syntaxon"`).
#' @return The entry from `.nomenclature_codes()`.
#' @noRd
code_spec <- function(code) {
  spec <- .nomenclature_codes()[[code]]
  if (is.null(spec)) {
    stop(sprintf("Unknown nomenclature code '%s'. Known: %s.", code,
                 paste(names(.nomenclature_codes()), collapse = ", ")),
         call. = FALSE)
  }
  spec
}


#' The nomenclature code of each backbone
#'
#' @param name Character vector of backbone names, or a `taxify_backend`.
#' @return Character vector of codes, `NA` for an unknown name.
#' @keywords internal
#' @export
#' @examples
#' backbone_code(c("wfo", "evc"))
backbone_code <- function(name) {
  if (inherits(name, "taxify_backend")) return(name$code %||% "taxon")
  reg <- .backbone_registry()
  reg$code[match(name, reg$name)]
}


#' The one nomenclature code a set of backbones shares
#'
#' A name is matched under one code, so a fallback chain or comparison across
#' backbones of different codes has no meaning: a taxon name looked up in a
#' syntaxon backbone, or the reverse, can only produce false matches.
#'
#' @param backbone Character vector of backbone names, or a `taxify_backend`.
#' @return A single code.
#' @noRd
shared_code <- function(backbone) {
  codes <- unique(backbone_code(backbone))
  codes <- codes[!is.na(codes)]
  if (length(codes) > 1L) {
    stop(sprintf(paste0(
      "Backbones of different nomenclature codes cannot be combined: %s. ",
      "Match taxon names and syntaxon names in separate calls."),
      paste(sprintf("%s (%s)", backbone_name_of(backbone),
                    backbone_code(backbone)), collapse = ", ")),
      call. = FALSE)
  }
  if (length(codes) == 0L) "taxon" else codes
}


#' Shape a result to the columns its nomenclature code reports
#'
#' Drops the columns that do not apply to the code (a syntaxon has no family,
#' genus or epithet) and places the hierarchy columns after `rank`.
#'
#' @param result The match result data.frame.
#' @param code A nomenclature code.
#' @return `result`, reshaped.
#' @noRd
shape_result_for_code <- function(result, code) {
  spec <- code_spec(code)
  keep <- setdiff(names(result), spec$drop_cols)
  hier <- intersect(spec$col_map$hierarchy, keep)
  if (length(hier)) {
    rest <- setdiff(keep, hier)
    at <- match("rank", rest)
    keep <- append(rest, hier, after = if (is.na(at)) length(rest) else at)
  }
  result[, keep, drop = FALSE]
}

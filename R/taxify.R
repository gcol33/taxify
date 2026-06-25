#' Match taxonomic names against local backbone databases
#'
#' Matches a vector of taxonomic names against locally stored Darwin Core
#' backbone databases. Returns a data.frame with one row per input name
#' containing the matched name, accepted name, taxonomic hierarchy, and
#' match quality information.
#'
#' When multiple backends are specified, names are matched against each
#' backend in order. Names matched by an earlier backend are not re-matched
#' by later ones (fallback chain).
#'
#' @param x Character vector of taxonomic names.
#' @param backend Character vector of backend names (e.g., `"wfo"`, `"col"`,
#'   `"gbif"`) or a single `taxify_backend` object. When multiple backends
#'   are given, they are tried in order as a fallback chain. Default `"wfo"`.
#' @param fuzzy Logical. Enable fuzzy matching for names that fail exact
#'   match. Default `TRUE`.
#' @param fuzzy_threshold Numeric. Maximum allowed distance for fuzzy matches.
#'   Two modes depending on the value:
#'   - **Fractional** (`0 < fuzzy_threshold < 1`): normalized distance
#'     (edits / max name length). Default `0.2` is about 1 edit per 5 characters.
#'   - **Integer** (`fuzzy_threshold >= 1`): maximum raw edit count, e.g.
#'     `fuzzy_threshold = 2L` allows at most 2 insertions/deletions/substitutions
#'     regardless of name length. Not supported for `fuzzy_method = "jw"`.
#' @param fuzzy_method Character. One of `"dl"` (Damerau-Levenshtein,
#'   default), `"levenshtein"`, or `"jw"` (Jaro-Winkler).
#' @param aggregates Character. How to treat species aggregates (names with an
#'   `agg.` / `s.l.` qualifier). `"preserve"` (default) keeps the aggregate as
#'   its own concept: it matches the backbone's aggregate taxon
#'   (`"<binomial> aggr."`) where one exists, otherwise falls back to the
#'   binomial. `"collapse"` strips the marker and matches the binomial species,
#'   the way any non-aggregate name is matched. Either way the qualifier is
#'   recorded in the `qualifier` column.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A data.frame with one row per input name and the following columns:
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
#'   \item{accepted_authorship}{Authorship of the accepted name. For a synonym
#'     this is the author of the resolved accepted name, not the synonym's own
#'     author, so `accepted_name` and `accepted_authorship` together form the
#'     accepted name's full citation.}
#'   \item{is_synonym}{Logical. Was the match a synonym?}
#'   \item{is_hybrid}{Logical. Was a hybrid marker detected in the input?}
#'   \item{qualifier}{Canonical taxonomic qualifier found in the input name
#'     (`"cf."`, `"aff."`, `"agg."`, `"s.l."`, `"s.str."`, `"sp."`, ...), or
#'     `NA`. Spelling variants are folded to one token (`"aggr."`, `"agg"` and
#'     `"sensu lato"` all map to `"agg."`/`"s.l."`).}
#'   \item{qualifier_position}{`"genus"` when the qualifier leads the name and
#'     qualifies the whole name (e.g. `"Cf. Pinus sylvestris"`), `"species"`
#'     when it qualifies the species (inline `cf.` or trailing `agg.`), `NA`
#'     when there is no qualifier.}
#'   \item{match_type}{One of `"exact"`, `"exact_ci"`, `"fuzzy"`, `"abbrev"`
#'     (an abbreviated genus such as `"Q. robur"` resolved via genus initial
#'     plus epithet), or `"none"`.}
#'   \item{fuzzy_dist}{Normalized string distance (0--1), `NA` if exact.}
#'   \item{is_ambiguous}{Logical. `TRUE` when the matched scientificName had
#'     multiple synonym rows pointing to different accepted taxa at the same
#'     priority tier (homonym ambiguity). Disambiguated via
#'     `nomenclaturalStatus = "Valid"` when that column is in the backbone;
#'     for irreducible ambiguity, the scalar columns hold one candidate.}
#'   \item{ambiguous_targets}{Character. `|`-joined list of conflicting
#'     accepted taxon IDs when `is_ambiguous = TRUE`; `NA` otherwise.}
#'   \item{backend}{Which backend was used (e.g., `"wfo"`, `"col"`,
#'     `"gbif"`).}
#'   \item{backbone_version}{Backend name, version, and download date
#'     (e.g., `"wfo:2024-12 (2026-04-01)"`). Useful for reproducibility.}
#' }
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Match a few names
#' taxify(c("Quercus robur", "Pinus sylvestris"))
#'
#' # Disable fuzzy matching
#' taxify("Quercus robus", fuzzy = FALSE)
#'
#' # Fallback chain: try WFO first, then COL for unmatched
#' taxify(c("Quercus robur", "Panthera leo"),
#'        backend = c("wfo", "col"))
#'
#' options(old)
#'
#' @export
taxify <- function(x,
                   backend = "wfo",
                   fuzzy = TRUE,
                   fuzzy_threshold = 0.2,
                   fuzzy_method = c("dl", "levenshtein", "jw"),
                   aggregates = c("preserve", "collapse"),
                   verbose = TRUE) {

  fuzzy_method <- match.arg(fuzzy_method)
  aggregates   <- match.arg(aggregates)

  if (!is.character(x)) {
    stop("x must be a character vector", call. = FALSE)
  }
  if (length(x) == 0L) {
    stop("x must have at least one element", call. = FALSE)
  }

  # Handle single backend object
  if (inherits(backend, "taxify_backend")) {
    ensure_backends_current(backend$name, verbose = verbose)
    return(taxify_single(x, backend, fuzzy, fuzzy_threshold, fuzzy_method,
                         aggregates, verbose))
  }

  if (!is.character(backend) || length(backend) == 0L) {
    stop("backend must be a character vector or taxify_backend object",
         call. = FALSE)
  }

  ensure_backends_current(backend, verbose = verbose)

  if (length(backend) == 1L) {
    be <- resolve_backend(backend)
    return(taxify_single(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                         aggregates, verbose))
  }

  # Multi-backend fallback chain
  if (verbose) message(sprintf("Matching %d names against %d backends: %s",
                                length(x), length(backend),
                                paste(backend, collapse = " -> ")))

  names_df <- attach_agg_key(clean_names(x), aggregates)
  result <- NULL

  for (be_name in backend) {
    be <- resolve_backend(be_name)
    bb_path <- ensure_backbone(be, verbose = verbose)

    if (is.null(result)) {
      # First backend: match all names
      if (verbose) message(sprintf("  [%s] Matching %d names...",
                                    be_name, nrow(names_df)))

      result <- run_match_stages(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                                 fuzzy_method, verbose = verbose,
                                 label = be_name)

      matched <- !is.na(result$match_type)
      result$backend <- ifelse(matched, be$name, NA_character_)
      bb_ver <- format_backbone_version(bb_path, be$name, be$version)
      result$backbone_version[matched] <- bb_ver
    } else {
      # Subsequent backends: only try unmatched names
      unmatched_idx <- which(is.na(result$match_type) &
                             !is.na(result$input_name))
      if (length(unmatched_idx) == 0L) {
        if (verbose) message(sprintf("  [%s] Skipped (all names matched)",
                                      be_name))
        next
      }

      if (verbose) message(sprintf("  [%s] Matching %d remaining names...",
                                    be_name, length(unmatched_idx)))

      sub_names_df <- data.frame(
        original = names_df$original[unmatched_idx],
        cleaned = names_df$cleaned[unmatched_idx],
        is_hybrid = names_df$is_hybrid[unmatched_idx],
        qualifier = names_df$qualifier[unmatched_idx],
        qualifier_position = names_df$qualifier_position[unmatched_idx],
        is_aggregate = names_df$is_aggregate[unmatched_idx],
        agg_key = names_df$agg_key[unmatched_idx],
        genus_only = names_df$genus_only[unmatched_idx],
        hybrid_name = names_df$hybrid_name[unmatched_idx],
        genus_abbrev = names_df$genus_abbrev[unmatched_idx],
        stringsAsFactors = FALSE
      )

      sub_result <- run_match_stages(be, sub_names_df, bb_path, fuzzy,
                                     fuzzy_threshold, fuzzy_method,
                                     verbose = verbose, label = be_name)

      # Merge sub_result back into main result
      matched_in_sub <- which(!is.na(sub_result$match_type))
      if (length(matched_in_sub) > 0L) {
        bb_ver <- format_backbone_version(bb_path, be$name, be$version)
        for (j in matched_in_sub) {
          i <- unmatched_idx[j]
          result$matched_name[i]      <- sub_result$matched_name[j]
          result$accepted_name[i]     <- sub_result$accepted_name[j]
          result$taxon_id[i]          <- sub_result$taxon_id[j]
          result$accepted_id[i]       <- sub_result$accepted_id[j]
          result$rank[i]              <- sub_result$rank[j]
          result$family[i]            <- sub_result$family[j]
          result$genus[i]             <- sub_result$genus[j]
          result$epithet[i]           <- sub_result$epithet[j]
          result$authorship[i]        <- sub_result$authorship[j]
          result$accepted_authorship[i] <- sub_result$accepted_authorship[j] %||%
                                          NA_character_
          result$is_synonym[i]        <- sub_result$is_synonym[j]
          result$match_type[i]        <- sub_result$match_type[j]
          result$fuzzy_dist[i]        <- sub_result$fuzzy_dist[j]
          result$is_ambiguous[i]      <- sub_result$is_ambiguous[j] %||% NA
          result$ambiguous_targets[i] <- sub_result$ambiguous_targets[j] %||%
                                          NA_character_
          result$backend[i]           <- be$name
          result$backbone_version[i]  <- bb_ver
        }
      }
    }
  }

  # Set match_type = "none" for still-unmatched
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  # Ensure classification columns always exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  # Carry input-side qualifier info (rows are 1:1 with names_df)
  result$qualifier          <- names_df$qualifier
  result$qualifier_position <- names_df$qualifier_position

  result <- enrich_with_register(result, names_df, backend)
  rownames(result) <- NULL
  as_taxify_result(result, backend = backend)
}


#' Run the full matching pipeline against a single backend
#'
#' @param x Character vector of names.
#' @param be A taxify_backend object.
#' @param fuzzy Logical.
#' @param fuzzy_threshold Numeric.
#' @param fuzzy_method Character.
#' @param verbose Logical.
#' @return A data.frame with the 16-column output schema.
#' @noRd
taxify_single <- function(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                          aggregates = "preserve", verbose) {
  bb_path <- ensure_backbone(be, verbose = verbose)

  if (verbose) message(sprintf("Matching %d names...", length(x)))
  names_df <- attach_agg_key(clean_names(x), aggregates)

  result <- run_match_stages(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                             fuzzy_method, verbose = verbose)

  matched <- !is.na(result$match_type)
  result$backend <- ifelse(matched, be$name, NA_character_)
  result$backbone_version[matched] <- format_backbone_version(
    bb_path, be$name, be$version
  )
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  # Ensure classification columns always exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  # Carry input-side qualifier info (rows are 1:1 with names_df)
  result$qualifier          <- names_df$qualifier
  result$qualifier_position <- names_df$qualifier_position

  result <- enrich_with_register(result, names_df, be$name)
  rownames(result) <- NULL
  as_taxify_result(result, backend = be$name)
}


#' Attach the aggregate-taxon lookup key to a cleaned-names frame
#'
#' In preserve mode, aggregate-concept rows get `agg_key = "<binomial> aggr."`,
#' the form that the aggregate-bearing backbones (Euro+Med, WoRMS) use for their
#' dedicated aggregate taxa. `match_exact_compiled()` tries this key before the
#' binomial. In collapse mode every `agg_key` is `NA`, so the aggregate pass is a
#' no-op and aggregates match as plain binomials.
#'
#' @param names_df Data.frame from `clean_names()`.
#' @param aggregates `"preserve"` or `"collapse"`.
#' @return `names_df` with an `agg_key` column.
#' @noRd
attach_agg_key <- function(names_df, aggregates = "preserve") {
  names_df$agg_key <- NA_character_
  if (identical(aggregates, "preserve")) {
    rows <- which(names_df$is_aggregate & !is.na(names_df$cleaned))
    if (length(rows)) {
      names_df$agg_key[rows] <- paste0(names_df$cleaned[rows], " aggr.")
    }
  }
  names_df
}


#' Run the core matching stages against one backend
#'
#' The shared sequence used by both the single-backend and multi-backend paths:
#' exact matching, the out-of-scope prefilter, abbreviated-genus resolution,
#' then (optionally) fuzzy matching of whatever remains.
#'
#' @param be A taxify_backend object.
#' @param names_df Data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr file.
#' @param fuzzy Logical. Enable the fuzzy pass.
#' @param fuzzy_threshold Numeric. Fuzzy distance threshold.
#' @param fuzzy_method Character. Fuzzy distance method.
#' @param verbose Logical.
#' @param label Optional backend label for verbose messages (NULL = no prefix).
#' @return The match result data.frame.
#' @noRd
run_match_stages <- function(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                             fuzzy_method, verbose = FALSE, label = NULL) {
  pre <- if (is.null(label)) "  " else sprintf("  [%s] ", label)
  n_unresolved <- function(res) {
    sum(is.na(res$match_type) & !is.na(names_df$cleaned))
  }

  result <- match_exact(be, names_df, bb_path)
  result <- prefilter_out_of_scope(result, names_df, be$name)

  if (n_unresolved(result) > 0L) {
    result <- match_abbrev_genus(be, result, names_df, bb_path)
  }

  n_un <- n_unresolved(result)
  if (fuzzy && n_un > 0L) {
    if (verbose) message(sprintf("%sFuzzy matching %d unmatched...", pre, n_un))
    result <- match_fuzzy(be, result, bb_path, method = fuzzy_method,
                          threshold = fuzzy_threshold, names_df = names_df)
  }
  result
}


#' Pre-filter out-of-scope names before fuzzy matching
#'
#' Checks unmatched names against the genus register and backend coverage.
#' Names whose genus is known but not covered by the requested backend are
#' marked `"out_of_scope"` immediately.
#'
#' @param result The match result data.frame after exact matching.
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param backend Character scalar or vector of backend names being tried.
#' @return The result data.frame, possibly with some NA match_type rows
#'   promoted to `"out_of_scope"`.
#' @noRd
prefilter_out_of_scope <- function(result, names_df, backend) {
  reg <- tryCatch({
    if (is.null(.taxify_env$register)) {
      path <- register_vtr_path()
      if (file.exists(path)) taxify_load_register(verbose = FALSE)
    }
    .taxify_env$register
  }, error = function(e) NULL)

  if (is.null(reg) || nrow(reg) == 0L) return(result)

  covered_genera <- tryCatch({
    cov_path <- coverage_vtr_path()
    if (file.exists(cov_path)) {
      be_names <- if (is.character(backend)) backend else backend$name
      covered <- character(0)
      for (be in be_names) {
        cache_key <- paste0("coverage_", be)
        if (is.null(.taxify_env[[cache_key]])) {
          cov <- vectra::tbl(cov_path) |>
            vectra::filter(backend == be) |>
            vectra::collect()
          .taxify_env[[cache_key]] <- cov$genus
        }
        covered <- union(covered, .taxify_env[[cache_key]])
      }
      covered
    } else {
      NULL
    }
  }, error = function(e) NULL)

  if (is.null(covered_genera)) return(result)

  reg_lookup <- stats::setNames(seq_len(nrow(reg)), reg$genus)

  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))
  if (length(unmatched_rows) == 0L) return(result)

  cleaned_um <- names_df$cleaned[unmatched_rows]
  raw_um     <- result$input_name[unmatched_rows]
  genus_names <- ifelse(!is.na(cleaned_um) & nzchar(cleaned_um),
                        sub(" .*", "", cleaned_um),
                        ifelse(!is.na(raw_um) & nzchar(raw_um),
                               sub(" .*", "", trimws(raw_um)),
                               NA_character_))

  in_register   <- !is.na(genus_names) & nzchar(genus_names) &
                   !is.na(reg_lookup[genus_names])
  not_covered   <- !genus_names %in% covered_genera
  oos_mask      <- in_register & not_covered

  if (any(oos_mask)) {
    result$match_type[unmatched_rows[oos_mask]] <- "out_of_scope"
  }

  result
}


#' Enrich unmatched names using the unified genus register
#'
#' @param result The match result data.frame.
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param backend Character scalar or vector of backend names that were tried.
#' @return The result data.frame with life_form enrichment.
#' @noRd
enrich_with_register <- function(result, names_df, backend) {
  reg <- tryCatch({
    if (is.null(.taxify_env$register)) {
      path <- register_vtr_path()
      if (file.exists(path)) taxify_load_register(verbose = FALSE)
    }
    .taxify_env$register
  }, error = function(e) NULL)

  if (is.null(reg) || nrow(reg) == 0L) return(result)

  covered_genera <- tryCatch({
    cov_path <- coverage_vtr_path()
    if (file.exists(cov_path)) {
      be_names <- if (is.character(backend)) backend else backend$name
      covered <- character(0)
      for (be in be_names) {
        cache_key <- paste0("coverage_", be)
        if (is.null(.taxify_env[[cache_key]])) {
          cov <- vectra::tbl(cov_path) |>
            vectra::filter(backend == be) |>
            vectra::collect()
          .taxify_env[[cache_key]] <- cov$genus
        }
        covered <- union(covered, .taxify_env[[cache_key]])
      }
      covered
    } else {
      NULL
    }
  }, error = function(e) NULL)

  # Ensure classification columns exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  has_kingdom_group <- "kingdom_group" %in% names(reg)
  has_taxon_group   <- "taxon_group"   %in% names(reg)

  reg_lookup <- stats::setNames(seq_len(nrow(reg)), reg$genus)

  active_rows <- which(!is.na(result$input_name))
  if (length(active_rows) == 0L) return(result)

  mt <- result$match_type[active_rows]
  is_matched <- !is.na(mt) & mt != "none" & mt != "out_of_scope"

  genus_names <- rep(NA_character_, length(active_rows))

  if (any(is_matched)) {
    m_idx <- which(is_matched)
    m_rows <- active_rows[m_idx]
    g <- result$genus[m_rows]
    fallback <- is.na(g) | !nzchar(g)
    if (any(fallback)) {
      mn <- result$matched_name[m_rows[fallback]]
      g[fallback] <- ifelse(!is.na(mn), sub(" .*", "", mn), NA_character_)
    }
    genus_names[m_idx] <- g
  }

  if (any(!is_matched)) {
    u_idx <- which(!is_matched)
    u_rows <- active_rows[u_idx]
    cleaned_u <- names_df$cleaned[u_rows]
    raw_u     <- result$input_name[u_rows]
    genus_names[u_idx] <- ifelse(
      !is.na(cleaned_u) & nzchar(cleaned_u),
      sub(" .*", "", cleaned_u),
      ifelse(!is.na(raw_u) & nzchar(raw_u),
             sub(" .*", "", trimws(raw_u)),
             NA_character_)
    )
  }

  reg_idx <- unname(reg_lookup[genus_names])
  found <- !is.na(reg_idx)

  if (any(found)) {
    f_rows <- active_rows[found]
    f_idx  <- reg_idx[found]
    result$life_form[f_rows] <- reg$life_form[f_idx]
    if (has_kingdom_group) result$kingdom_group[f_rows] <- reg$kingdom_group[f_idx]
    if (has_taxon_group)   result$taxon_group[f_rows]   <- reg$taxon_group[f_idx]
  }

  if (!is.null(covered_genera)) {
    none_mask <- !is.na(mt) & mt == "none" & found
    if (any(none_mask)) {
      none_genera <- genus_names[none_mask]
      not_covered <- !none_genera %in% covered_genera
      if (any(not_covered)) {
        oos_rows <- active_rows[which(none_mask)[not_covered]]
        result$match_type[oos_rows] <- "out_of_scope"
      }
    }
  }

  result
}


#' Attach the taxify_result class and metadata attribute
#'
#' @param result A data.frame with the standard 16+ column schema.
#' @param backend Character vector of backend name(s) that were tried.
#' @return The same data.frame, classed as `c("taxify_result", "data.frame")`.
#' @noRd
as_taxify_result <- function(result, backend) {
  n_input <- nrow(result)

  mt <- result$match_type
  tally <- list(
    exact            = sum(mt == "exact",       na.rm = TRUE),
    case_insensitive = sum(mt == "exact_ci",    na.rm = TRUE),
    fuzzy            = sum(mt == "fuzzy",        na.rm = TRUE),
    abbrev           = sum(mt == "abbrev",      na.rm = TRUE),
    out_of_scope     = sum(mt == "out_of_scope", na.rm = TRUE),
    unmatched        = sum(mt == "none",         na.rm = TRUE)
  )

  # Out-of-scope breakdown by taxon_group
  oos_rows <- result[!is.na(mt) & mt == "out_of_scope", , drop = FALSE]
  tg_col   <- if ("taxon_group" %in% names(oos_rows)) "taxon_group" else "life_form"
  if (nrow(oos_rows) > 0L && tg_col %in% names(oos_rows)) {
    oos_tg  <- oos_rows[[tg_col]]
    oos_be  <- if ("backend" %in% names(oos_rows)) {
      oos_rows$backend
    } else {
      rep(backend[1L], nrow(oos_rows))
    }
    oos_tg[is.na(oos_tg)] <- "unknown"
    oos_be[is.na(oos_be)]  <- backend[1L]
    oos_combo_df   <- data.frame(taxon_group = oos_tg, backend = oos_be,
                                 stringsAsFactors = FALSE)
    oos_tally_df   <- aggregate(
      rep(1L, nrow(oos_combo_df)) ~ taxon_group + backend,
      data = oos_combo_df,
      FUN  = sum
    )
    names(oos_tally_df)[names(oos_tally_df) ==
                          "rep(1L, nrow(oos_combo_df))"] <- "n"
    oos_tally_df   <- oos_tally_df[order(oos_tally_df$taxon_group), , drop = FALSE]
    rownames(oos_tally_df) <- NULL
  } else {
    oos_tally_df <- data.frame(
      taxon_group = character(0L),
      backend     = character(0L),
      n           = integer(0L),
      stringsAsFactors = FALSE
    )
  }

  # Full taxon_group breakdown
  tg_col_all <- if ("taxon_group" %in% names(result)) "taxon_group" else "life_form"
  lf_tally_df <- if (tg_col_all %in% names(result)) {
    tg_vals <- result[[tg_col_all]]
    tg_vals[is.na(tg_vals)] <- "unknown"
    tg_tbl <- sort(table(tg_vals), decreasing = TRUE)
    data.frame(
      taxon_group = names(tg_tbl),
      n           = as.integer(tg_tbl),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  } else {
    data.frame(taxon_group = character(0L), n = integer(0L),
               stringsAsFactors = FALSE)
  }

  # Unmatched rows' taxon_group breakdown
  none_rows   <- result[!is.na(mt) & mt == "none", , drop = FALSE]
  tg_col_none <- if ("taxon_group" %in% names(none_rows)) "taxon_group" else "life_form"
  none_lf_df  <- if (nrow(none_rows) > 0L && tg_col_none %in% names(none_rows)) {
    tg_vals <- none_rows[[tg_col_none]]
    tg_vals[is.na(tg_vals)] <- "unknown"
    tg_tbl <- sort(table(tg_vals), decreasing = TRUE)
    data.frame(
      taxon_group = names(tg_tbl),
      n           = as.integer(tg_tbl),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  } else {
    data.frame(taxon_group = character(0L), n = integer(0L),
               stringsAsFactors = FALSE)
  }

  version <- NA_character_
  if ("backbone_version" %in% names(result)) {
    bv <- result$backbone_version[!is.na(result$backbone_version)]
    if (length(bv) > 0L) {
      version <- sub("^[^:]+:([^ ]+).*$", "\\1", bv[1L])
    }
  }

  meta <- list(
    backend                   = backend,
    version                   = version,
    n_input                   = n_input,
    match_tally               = tally,
    out_of_scope_tally        = oos_tally_df,
    life_form_tally           = lf_tally_df,
    unmatched_life_form_tally = none_lf_df
  )

  attr(result, "taxify_meta") <- meta
  class(result) <- c("taxify_result", "data.frame")
  result
}

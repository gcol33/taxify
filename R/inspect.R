#' Inspect a name list for probable typos and other anomalies
#'
#' A quality-control pass over a name list. By default `inspect()` does not match
#' names against backbones: on a plain character vector it runs the checks that
#' need no matching -- the genus register and the rest of the batch -- and is fast
#' and offline. To also surface the match-based anomalies (`typo`, `synonym`,
#' `ambiguous`, `geographic`), either set `backbones = TRUE` (matches against
#' every installed backbone, listed in the report) or match yourself first and
#' inspect the result (`taxify(x) |> inspect()`). Either way it returns only the
#' rows that look anomalous, each labelled with what stands out and, where known,
#' the name to use instead.
#'
#' Checks that need no matching (run on a character vector or a result):
#' \describe{
#'   \item{`unknown`}{The genus is not in the genus register -- the union of all
#'     12 backbones' genera -- so no backbone recognises it. The strong "probably
#'     not a real name" signal.}
#'   \item{`near_duplicate`}{A near-twin of a more frequent name in the same list
#'     (small edit distance), so probably a misspelling of it. Computed from the
#'     list alone, so it catches typos in names no backbone contains.}
#'   \item{`outlier_group`}{The name's kingdom group (from the register) is a tiny
#'     minority of an otherwise group-coherent list -- the lone animal or fungus
#'     among plants, typically a cross-kingdom homonym typo.}
#' }
#' Checks read from a `taxify()` result (only present when you inspect one):
#' \describe{
#'   \item{`typo`}{Resolved only after fuzzy correction (`match_type = "fuzzy"`):
#'     the input most likely contains a spelling error; `suggestion` is the name.}
#'   \item{`ambiguous`}{A homonym resolving to more than one accepted taxon.}
#'   \item{`geographic`}{The matched species is real but has no WCVP record in the
#'     declared `region` / `coords` (vascular plants only).}
#'   \item{`out_of_range`}{No region declared, yet the matched species' range falls
#'     outside the list's main TDWG continents (skipped for globally spread
#'     lists).}
#'   \item{`case`}{Resolved only after ignoring case (`match_type = "exact_ci"`).}
#'   \item{`synonym`}{The input is an outdated synonym; `suggestion` is the
#'     current accepted name.}
#' }
#' Rows with no anomaly are dropped.
#'
#' Each row gets a `tier` describing what it needs, not how bad it is:
#' `unresolved` (no usable name -- act on it), `review` (a name is there but its
#' identity is uncertain -- verify it), or `note` (correct, optional cleanup).
#' `unknown` is `unresolved`; the identity-uncertain labels are `review`; `case`
#' and `synonym` are `note`. An anomaly may be intended, so the tier is a triage
#' hint, not a verdict.
#'
#' The list-context labels (`near_duplicate`, `out_of_range`, `outlier_group`)
#' judge a name against the rest of the batch, so they cannot apply to a single
#' name: `inspect()` on one name warns and reports only the per-name labels. The
#' register checks (`unknown`, and the register-derived `outlier_group`) need the
#' genus register installed; without it they are skipped (with a message at
#' `verbose`).
#'
#' @param x A character vector of names, or a `taxify_result` from [taxify()].
#' @param backbones Logical. When `x` is a character vector, `TRUE` matches it
#'   against every installed backbone (via [taxify()]) so the match-based labels
#'   are available; `FALSE` (default) runs the register and list checks only, with
#'   no matching. The backbones used are printed in the report header. Ignored
#'   when `x` is already a `taxify_result` (it was matched already).
#' @param region,coords,range Geographic constraint for the `geographic` /
#'   `out_of_range` checks, as in [taxify()]. These act on a `taxify_result`
#'   (which carries the accepted names they need); on a character vector there is
#'   nothing matched to place, so they have no effect.
#' @param min_tier Lowest tier to report: `"note"` (default, everything),
#'   `"review"`, or `"unresolved"`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A `taxify_inspection` data.frame (one row per anomalous name, ordered
#'   most-notable first) with columns `input_name`, `suggestion` (the name to use
#'   instead, or `NA`), `anomalies` (`|`-joined labels), `tier` (ordered factor
#'   `note` < `review` < `unresolved`), `reason`, `fuzzy_dist`, and `backend`.
#'   Zero rows means nothing stood out.
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # On raw names: register + list checks (no matching)
#' inspect(c("Quercus robur", "Bogusus fakus", "Carexus mysteriosa",
#'           "Carexus mysteriosa", "Carexus mysteryosa"))
#'
#' # Opt in to matching to also get typos, synonyms, ambiguity
#' inspect(c("Quercus robur", "Quercus robus"), backbones = TRUE)
#'
#' # Or match yourself and inspect the result
#' taxify(c("Quercus robur", "Quercus robus")) |> inspect()
#'
#' options(old)
#'
#' @seealso [taxify()], [taxify_regions()]
#' @export
inspect <- function(x,
                    backbones = FALSE,
                    region = NULL,
                    coords = NULL,
                    range = c("present", "native", "introduced"),
                    min_tier = c("note", "review", "unresolved"),
                    verbose = TRUE) {
  range    <- match.arg(range)
  min_tier <- match.arg(min_tier)

  if (inherits(x, "taxify_result")) {
    res <- x
  } else if (is.character(x)) {
    if (isTRUE(backbones)) {
      # Opt-in matching: run taxify() against every installed backbone so the
      # match-derived labels (typo, synonym, ...) become available. The report
      # header records which backbones were used.
      inst <- installed_backbones()
      if (length(inst) == 0L) {
        warning("inspect(): backbones = TRUE but none are installed; running ",
                "the register and list checks only.", call. = FALSE)
        res <- bare_taxify_result(x)
      } else {
        res <- tryCatch(
          taxify(x, backend = inst, region = region, coords = coords,
                 range = range, verbose = verbose),
          error = function(e) {
            warning("inspect(): backbone matching failed (",
                    conditionMessage(e), "); register and list checks only.",
                    call. = FALSE)
            bare_taxify_result(x)
          }
        )
      }
    } else {
      res <- bare_taxify_result(x)
    }
  } else {
    stop("`x` must be a character vector or a taxify_result.", call. = FALSE)
  }

  region_codes <- resolve_region(region, coords, verbose = FALSE)
  build_inspection(res, region_codes, range, min_tier, verbose = verbose)
}


#' A minimal taxify_result for the no-matching path
#'
#' Carries the inputs with `match_type = NA` so [inspect()] runs the checks that
#' need no matching (register, near-duplicate, kingdom outlier) on a character
#' vector without touching a backbone.
#'
#' @param x Character vector of input names.
#' @return A `taxify_result` with `input_name` and an all-`NA` `match_type`.
#' @noRd
bare_taxify_result <- function(x) {
  structure(
    data.frame(input_name = x, match_type = NA_character_,
               stringsAsFactors = FALSE),
    class = c("taxify_result", "data.frame")
  )
}


#' Load the genus register data.frame, or NULL if unavailable
#' @noRd
inspect_load_register <- function() {
  tryCatch({
    if (is.null(.taxify_env$register)) {
      p <- register_vtr_path()
      if (file.exists(p)) taxify_load_register(verbose = FALSE)
    }
    .taxify_env$register
  }, error = function(e) NULL)
}


#' Classify the rows of a taxify result into an anomaly-only inspection report
#'
#' @param res A `taxify_result` data.frame.
#' @param region_codes Validated TDWG Level 3 codes, or `NULL`.
#' @param range_mode One of `"present"`, `"native"`, `"introduced"`.
#' @param min_tier Lowest tier to keep.
#' @param verbose Logical.
#' @return A `taxify_inspection` data.frame.
#' @noRd
build_inspection <- function(res, region_codes = NULL, range_mode = "present",
                             min_tier = "note", verbose = TRUE) {
  n  <- nrow(res)
  mt <- res$match_type

  col <- function(nm, default) if (nm %in% names(res)) res[[nm]] else default
  acc       <- col("accepted_name",     rep(NA_character_, n))
  fd        <- col("fuzzy_dist",        rep(NA_real_, n))
  amb_tgt   <- col("ambiguous_targets", rep(NA_character_, n))
  backend   <- col("backend",           rep(NA_character_, n))
  syn_raw   <- col("is_synonym",        rep(FALSE, n))
  amb_raw   <- col("is_ambiguous",      rep(FALSE, n))
  input     <- res$input_name

  is_true <- function(v) !is.na(v) & v
  matched <- !is.na(mt) & mt %in% c("exact", "exact_ci", "fuzzy", "abbrev")

  min_batch  <- getOption("taxify.inspect_min_batch", 4L)
  dominance  <- getOption("taxify.inspect_dominance", 0.7)
  minor_frac <- getOption("taxify.inspect_minor_frac", 0.1)

  gtok <- sub(" .*", "", trimws(input))
  gtok[is.na(input) | !nzchar(trimws(input))] <- NA_character_

  # ---- genus register (the recognition authority) ----
  reg        <- inspect_load_register()
  reg_genera <- if (!is.null(reg) && nrow(reg) > 0L) reg$genus else NULL
  reg_kmap   <- if (!is.null(reg) && "kingdom_group" %in% names(reg)) {
    stats::setNames(reg$kingdom_group, reg$genus)
  } else {
    NULL
  }

  # unknown: an unresolved name whose genus the register does not contain
  m_unknown      <- rep(FALSE, n)
  reason_unknown <- rep(NA_character_, n)
  unresolved     <- is.na(mt) | mt %in% c("none", "out_of_scope")
  if (any(unresolved)) {
    if (!is.null(reg_genera)) {
      hit <- unresolved & !is.na(gtok) & !(gtok %in% reg_genera)
      m_unknown[hit]      <- TRUE
      reason_unknown[hit] <- sprintf("genus '%s' is not in the taxonomic register",
                                     gtok[hit])
    } else if (verbose) {
      message("  inspect(): genus register not installed; ",
              "skipping the genus-recognition check.")
    }
  }

  # kingdom group: from the result if present, else looked up by genus
  kg <- col("kingdom_group", rep(NA_character_, n))
  if (!is.null(reg_kmap) && any(is.na(kg))) {
    fill     <- is.na(kg) & !is.na(gtok)
    kg[fill] <- unname(reg_kmap[gtok[fill]])
  }

  # ---- match-derived per-name labels (only fire on a taxify result) ----
  m_typo      <- !is.na(mt) & mt == "fuzzy"
  m_case      <- !is.na(mt) & mt == "exact_ci"
  m_synonym   <- matched & is_true(syn_raw)
  m_ambiguous <- is_true(amb_raw)

  # ---- list-context labels: need the rest of the batch ----
  n_active <- sum(!is.na(input))
  if (n_active == 1L) {
    warning("inspect(): list-context anomaly checks need a batch of names; ",
            "with a single name only the per-name checks run.", call. = FALSE)
  }

  dup_target <- near_duplicate_targets(input)
  m_neardup  <- !is.na(dup_target)

  # kingdom-group outlier (uses the kingdom from result or register)
  m_outlier      <- rep(FALSE, n)
  reason_outlier <- rep(NA_character_, n)
  grp_known      <- !is.na(kg) & nzchar(kg) & kg != "unknown" & !m_unknown
  if (sum(grp_known) >= min_batch) {
    g   <- kg[grp_known]
    tab <- sort(table(g), decreasing = TRUE)
    dom <- names(tab)[1L]
    if (length(tab) > 1L && as.integer(tab[1L]) / length(g) >= dominance) {
      minor_cap    <- max(1L, floor(minor_frac * length(g)))
      minor_groups <- names(tab)[as.integer(tab) <= minor_cap & names(tab) != dom]
      hit <- grp_known & kg %in% minor_groups
      m_outlier[hit]      <- TRUE
      reason_outlier[hit] <- sprintf("%s outlier (list is mostly %s)",
                                     kg[hit], dom)
    }
  }

  # list-inferred range outlier (only when no region was declared)
  m_range      <- rep(FALSE, n)
  reason_range <- rep(NA_character_, n)
  if ((is.null(region_codes) || length(region_codes) == 0L) &&
      sum(matched) >= min_batch) {
    rr <- range_outlier_rows(acc, matched, min_batch, verbose)
    m_range      <- rr$mask
    reason_range <- rr$reason
  }

  # declared-region geographic outlier
  reason_geo <- if (length(region_codes) <= 3L && length(region_codes) > 0L) {
    sprintf("outside region (%s) per WCVP", paste(region_codes, collapse = ", "))
  } else {
    "outside region per WCVP"
  }
  m_geo <- rep(FALSE, n)
  if (!is.null(region_codes) && length(region_codes) > 0L && any(matched)) {
    sets <- tryCatch(
      region_range_sets(acc[matched], region_codes, range_mode, verbose = verbose),
      error = function(e) NULL
    )
    if (!is.null(sets)) {
      m_geo <- matched & (acc %in% sets$has_data) & !(acc %in% sets$present)
    }
  }

  # ---- assemble ----
  flag_defs <- list(
    list(name = "unknown",       mask = m_unknown,   rank = 3L,
         reason = reason_unknown),
    list(name = "typo",          mask = m_typo,      rank = 2L,
         reason = rep("likely misspelling", n)),
    list(name = "near_duplicate", mask = m_neardup,  rank = 2L,
         reason = sprintf("near-duplicate of more frequent '%s'", dup_target)),
    list(name = "ambiguous",     mask = m_ambiguous, rank = 2L,
         reason = ifelse(!is.na(amb_tgt),
                         sprintf("ambiguous (targets: %s)", amb_tgt),
                         "ambiguous match")),
    list(name = "geographic",    mask = m_geo,       rank = 2L,
         reason = rep(reason_geo, n)),
    list(name = "out_of_range",  mask = m_range,     rank = 2L,
         reason = reason_range),
    list(name = "outlier_group", mask = m_outlier,   rank = 2L,
         reason = reason_outlier),
    list(name = "case",          mask = m_case,      rank = 1L,
         reason = rep("case mismatch", n)),
    list(name = "synonym",       mask = m_synonym,   rank = 1L,
         reason = rep("outdated synonym", n))
  )

  anomalies_chr <- rep("", n)
  reasons_chr   <- rep("", n)
  tier_num      <- rep(0L, n)

  for (fdf in flag_defs) {
    idx <- which(fdf$mask & !is.na(input))
    if (!length(idx)) next
    anomalies_chr[idx] <- ifelse(nzchar(anomalies_chr[idx]),
                                 paste(anomalies_chr[idx], fdf$name, sep = "|"),
                                 fdf$name)
    reasons_chr[idx] <- ifelse(nzchar(reasons_chr[idx]),
                               paste(reasons_chr[idx], fdf$reason[idx],
                                     sep = "; "),
                               fdf$reason[idx])
    tier_num[idx] <- pmax(tier_num[idx], fdf$rank)
  }

  tier_floor <- c(note = 1L, review = 2L, unresolved = 3L)[[min_tier]]
  keep       <- which(tier_num >= tier_floor & !is.na(input))
  ord        <- keep[order(-tier_num[keep], input[keep])]
  tier_lab   <- c("note", "review", "unresolved")

  # suggestion: accepted name when matched, else the in-list dominant spelling
  suggestion <- ifelse(matched, acc, NA_character_)
  nd_only    <- m_neardup & !matched
  suggestion[nd_only] <- dup_target[nd_only]

  out <- data.frame(
    input_name = input[ord],
    suggestion = suggestion[ord],
    anomalies  = anomalies_chr[ord],
    tier       = factor(tier_lab[tier_num[ord]], levels = tier_lab,
                        ordered = TRUE),
    reason     = reasons_chr[ord],
    fuzzy_dist = fd[ord],
    backend    = backend[ord],
    stringsAsFactors = FALSE
  )
  rownames(out) <- NULL

  bk <- attr(res, "taxify_meta")$backend
  if (is.null(bk)) bk <- unique(backend[!is.na(backend)])
  bk <- bk[!is.na(bk)]

  tier_counts <- table(factor(tier_lab[tier_num[keep]], levels = tier_lab))
  attr(out, "taxify_inspection_meta") <- list(
    n_input     = n_active,
    n_flagged   = length(keep),
    tier_counts = tier_counts,
    backbones   = bk
  )
  class(out) <- c("taxify_inspection", "data.frame")
  out
}


#' Find, for each name, a more frequent near-identical name in the same list
#'
#' Clusters the input by Levenshtein distance (base [adist()], no dependency)
#' on a case- and whitespace-folded key. A name is a near-duplicate when another
#' name within a small edit distance occurs strictly more often, so the rarer
#' spelling is the likely typo of the common one. Returns the common spelling to
#' suggest. Frequency-gated: a lone pair (each seen once) gives no signal.
#'
#' @param x Character vector of input names.
#' @return Character vector the length of `x`: the suggested spelling, or `NA`
#'   where the name is not a near-duplicate of a more frequent one.
#' @noRd
near_duplicate_targets <- function(x) {
  n   <- length(x)
  out <- rep(NA_character_, n)
  key <- gsub("\\s+", " ", tolower(trimws(x)))
  valid <- !is.na(key) & nzchar(key)
  if (sum(valid) < 2L) return(out)

  u   <- unique(key[valid])
  cap <- getOption("taxify.inspect_dup_max", 4000L)
  if (length(u) < 2L || length(u) > cap) return(out)

  cnt <- table(key[valid])
  rep_spelling <- tapply(x[valid], key[valid], function(v) {
    names(sort(table(v), decreasing = TRUE))[1L]
  })

  d   <- utils::adist(u)
  nch <- nchar(u)
  target_u <- rep(NA_character_, length(u))
  for (i in seq_along(u)) {
    near <- which(d[i, ] >= 1L & d[i, ] <= 2L)
    if (!length(near)) next
    shorter <- pmin(nch[i], nch[near])
    near <- near[d[i, near] / shorter <= 0.25 & shorter >= 5L]
    if (!length(near)) next
    ci   <- as.integer(cnt[u[i]])
    more <- near[as.integer(cnt[u[near]]) > ci]
    if (!length(more)) next
    best <- more[which.max(as.integer(cnt[u[more]]))]
    target_u[i] <- rep_spelling[[u[best]]]
  }

  out <- target_u[match(key, u)]
  out
}


#' Flag matched species whose range falls outside the list's main continents
#'
#' Rolls each matched species' WCVP range up to TDWG Level 1 continents
#' (via `species_range_continents()`), finds the smallest set of continents
#' covering the bulk (default 80%) of placed species by greedy set cover, and --
#' only when that core set is small (a regionally coherent list) -- flags the
#' species occurring on none of those continents. A globally spread list needs
#' many continents to reach the bulk, fails the coherence gate, and flags
#' nothing.
#'
#' @param acc Accepted names (length n, aligned to the result rows).
#' @param matched Logical mask of matched rows (length n).
#' @param min_batch Minimum number of placed species to attempt the check.
#' @param verbose Logical.
#' @return List with `mask` (logical, length n) and `reason` (character, length
#'   n, `NA` off-mask).
#' @noRd
range_outlier_rows <- function(acc, matched, min_batch, verbose = FALSE) {
  n     <- length(acc)
  blank <- list(mask = rep(FALSE, n), reason = rep(NA_character_, n))

  cmap <- tryCatch(species_range_continents(acc[matched], verbose = verbose),
                   error = function(e) NULL)
  if (is.null(cmap) || length(cmap) == 0L) return(blank)

  conts  <- cmap[acc]                       # per row; NULL where no data
  placed <- matched & vapply(conts, function(z) !is.null(z) && length(z) > 0L,
                             logical(1L))
  np <- sum(placed)
  if (np < min_batch) return(blank)

  coverage <- getOption("taxify.inspect_range_coverage", 0.8)
  max_dom  <- getOption("taxify.inspect_range_maxdom", 2L)
  target   <- ceiling(coverage * np)

  pl_idx   <- which(placed)
  pl_conts <- conts[pl_idx]
  covered  <- rep(FALSE, np)
  dom      <- character(0L)
  repeat {
    if (sum(covered) >= target) break
    rem <- which(!covered)
    counts <- table(unlist(lapply(pl_conts[rem], unique)))
    if (length(counts) == 0L) break
    best <- names(counts)[which.max(counts)]
    dom  <- c(dom, best)
    covered <- covered |
      vapply(pl_conts, function(z) best %in% z, logical(1L))
    if (length(dom) >= max_dom + 1L) break
  }
  if (length(dom) == 0L || length(dom) > max_dom) return(blank)

  in_dom <- vapply(conts, function(z) !is.null(z) && any(z %in% dom),
                   logical(1L))
  mask   <- placed & !in_dom
  if (!any(mask)) return(blank)

  tab <- wgsrpd_table()
  core <- if (!is.null(tab)) {
    l1 <- stats::setNames(tab$level1_name, tab$level1_code)
    paste(unique(unname(l1[dom])), collapse = ", ")
  } else {
    paste(dom, collapse = ", ")
  }
  reason <- rep(NA_character_, n)
  reason[mask] <- sprintf("range outside the list's main area (%s)", core)
  list(mask = mask, reason = reason)
}


#' Print a taxify inspection report
#'
#' @param x A `taxify_inspection` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.taxify_inspection <- function(x, ...) {
  meta <- attr(x, "taxify_inspection_meta")
  rule <- strrep("\u2500", 60)
  cat(sprintf("\u2500\u2500 taxify inspection %s\n", strrep("\u2500", 42)))
  if (!is.null(meta)) {
    cat(sprintf("  %d names inspected  |  %d with anomalies\n",
                meta$n_input, meta$n_flagged))
    bk <- meta$backbones
    if (!is.null(bk) && length(bk)) {
      cat(sprintf("  backbones: %s\n", paste(bk, collapse = ", ")))
    } else {
      cat("  backbones: none (register + list checks only)\n")
    }
    tc <- meta$tier_counts
    if (!is.null(tc) && sum(tc) > 0L) {
      parts <- sprintf("%s: %d", names(tc), as.integer(tc))
      parts <- parts[as.integer(tc) > 0L]
      cat(sprintf("  %s\n", paste(rev(parts), collapse = "   ")))
    }
  }
  cat(sprintf("  %s\n", rule))

  if (nrow(x) == 0L) {
    cat("  nothing stood out\n")
    return(invisible(x))
  }

  inw   <- max(nchar(x$input_name))
  sugs  <- ifelse(is.na(x$suggestion), "?", x$suggestion)
  sugw  <- max(nchar(sugs))
  tierw <- max(nchar(as.character(x$tier)))
  for (i in seq_len(nrow(x))) {
    cat(sprintf("  [%-*s] %-*s  ->  %-*s  %s\n",
                tierw, as.character(x$tier[i]), inw, x$input_name[i],
                sugw, sugs[i], x$reason[i]))
  }
  invisible(x)
}

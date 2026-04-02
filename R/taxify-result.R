# ---- taxify_result S3 class ----
#
# taxify() returns a classed data.frame with metadata attached as an attribute.
# print() delegates to the standard data.frame method — no extra noise.
# summary() prints a human-readable digest of match quality and life-form scope.


#' Print a taxify_result
#'
#' Delegates to the standard data.frame print method.
#'
#' @param x A `taxify_result` object.
#' @param ... Passed to the next method.
#' @return `x`, invisibly.
#' @export
print.taxify_result <- function(x, ...) {
  NextMethod()
  invisible(x)
}


#' Summarise a taxify_result
#'
#' Prints a compact digest of match quality and life-form scope to the console.
#' Uses `cat()` so output is captured by `capture.output()` and rendered
#' correctly in knitr chunks.
#'
#' @param object A `taxify_result` object.
#' @param ... Ignored.
#' @return `object`, invisibly.
#' @export
summary.taxify_result <- function(object, ...) {
  meta <- attr(object, "taxify_meta")
  if (is.null(meta)) {
    cat("taxify result (no metadata attached)\n")
    return(invisible(object))
  }

  tally   <- meta$match_tally
  oos_df  <- meta$out_of_scope_tally   # data.frame: life_form, backend, n
  lf_df   <- meta$life_form_tally      # data.frame: life_form, n

  n_input   <- meta$n_input
  n_matched <- (tally$exact %||% 0L) +
               (tally$case_insensitive %||% 0L) +
               (tally$fuzzy %||% 0L)
  n_oos     <- tally$out_of_scope %||% 0L
  n_none    <- tally$unmatched %||% 0L

  # Header
  backend_str <- paste(toupper(meta$backend), collapse = " + ")
  version_str <- if (!is.null(meta$version) && !is.na(meta$version)) {
    sprintf(" v%s", meta$version)
  } else {
    ""
  }
  rule <- strrep("\u2500", 60)

  cat(sprintf("\u2500\u2500 taxify results %s\n", rule))
  cat(sprintf("  backend: %s%s  |  %d names submitted\n\n",
              backend_str, version_str, n_input))

  # Matched line
  cat(sprintf("  matched     %5d  (exact: %d, case-insensitive: %d, fuzzy: %d)\n",
              n_matched,
              tally$exact %||% 0L,
              tally$case_insensitive %||% 0L,
              tally$fuzzy %||% 0L))

  # Helper: pick the label column (taxon_group if present, else life_form)
  tally_label_col <- function(df) {
    if (!is.null(df) && "taxon_group" %in% names(df)) "taxon_group" else "life_form"
  }

  # Out-of-scope line (only if n > 0)
  if (n_oos > 0L) {
    oos_parts <- character(0L)
    if (!is.null(oos_df) && nrow(oos_df) > 0L) {
      lc <- tally_label_col(oos_df)
      oos_parts <- vapply(seq_len(nrow(oos_df)), function(i) {
        sprintf("%s: %d", oos_df[[lc]][i], oos_df$n[i])
      }, character(1L))
    }
    oos_backends <- if (!is.null(oos_df) && nrow(oos_df) > 0L) {
      unique(oos_df$backend)
    } else {
      meta$backend
    }
    tip_backends <- setdiff(c("wfo", "col", "gbif"), oos_backends)
    tip_str <- if (length(tip_backends) > 0L) {
      sprintf(" \u2014 not in %s, try backend = \"%s\"",
              paste(toupper(oos_backends), collapse = "/"),
              paste(tip_backends, collapse = "\", \""))
    } else {
      ""
    }

    if (length(oos_parts) > 0L) {
      cat(sprintf("  out of scope%5d  (%s%s)\n",
                  n_oos, paste(oos_parts, collapse = ", "), tip_str))
    } else {
      cat(sprintf("  out of scope%5d%s\n", n_oos, tip_str))
    }
  }

  # Unmatched line (always shown, breakdown by taxon_group helps diagnose)
  if (n_none > 0L) {
    none_lf_parts <- character(0L)
    if (!is.null(lf_df) && nrow(lf_df) > 0L) {
      none_tally <- meta$unmatched_life_form_tally %||% lf_df
      if (!is.null(none_tally) && nrow(none_tally) > 0L) {
        lc <- tally_label_col(none_tally)
        none_lf_parts <- vapply(seq_len(nrow(none_tally)), function(i) {
          sprintf("%s: %d", none_tally[[lc]][i], none_tally$n[i])
        }, character(1L))
      }
    }
    if (length(none_lf_parts) > 0L) {
      cat(sprintf("  unmatched   %5d  (taxon_group: %s)\n",
                  n_none, paste(none_lf_parts, collapse = ", ")))
    } else {
      cat(sprintf("  unmatched   %5d\n", n_none))
    }
  }

  cat(sprintf("  %s\n", rule))

  # Taxon-group summary line
  if (!is.null(lf_df) && nrow(lf_df) > 0L) {
    lc <- tally_label_col(lf_df)
    lf_parts <- vapply(seq_len(nrow(lf_df)), function(i) {
      sprintf("%s: %d", lf_df[[lc]][i], lf_df$n[i])
    }, character(1L))
    cat(sprintf("  taxon groups: %s\n", paste(lf_parts, collapse = "  ")))
  }

  invisible(object)
}

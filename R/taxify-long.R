#' Reshape grouped enrichment columns to long format
#'
#' Converts wide-format columns produced by grouped enrichments (e.g.,
#' `invasive_status_AT`, `invasive_status_DE`) back to long format with
#' one row per species x group combination.
#'
#' @param x A data.frame, typically a [taxify()] result after applying
#'   a grouped enrichment like [add_griis()],
#'   [add_alien_first_records()], or [add_wcvp()].
#' @param cols Character vector of base column names to reshape. These are
#'   the column names without the group suffix (e.g., `"invasive_status"`,
#'   not `"invasive_status_AT"`). If omitted, auto-detected from the
#'   enrichment metadata stamped by the `add_*()` functions.
#' @param group_col Character. Name for the output group column.
#'   If omitted, auto-detected from enrichment metadata (e.g.,
#'   `"country_code"` for invasive status or alien first records).
#' @param drop_na Logical. If `TRUE`, drop rows where all value columns
#'   are `NA`. Default `FALSE`.
#'
#' @return A data.frame in long format. All columns from `x` that are not
#'   part of the reshape are preserved. The reshaped columns use their base
#'   names (without suffix), and a new `group_col` column contains the
#'   group code extracted from the suffix.
#'
#' @details
#' When `cols` and `group_col` are omitted, `taxify_long()` reads the
#' reshape metadata attached by grouped enrichment functions
#' ([add_griis()], [add_alien_first_records()], [add_wcvp()],
#' [add_common_names()]). If multiple grouped enrichments were applied,
#' all are reshaped together (they must share the same group column).
#'
#' Column matching uses the explicit base names in `cols` to avoid ambiguity.
#' For example, given `cols = c("alien_first_record",
#' "alien_first_record_source")`, the column `alien_first_record_source_AT`
#' is correctly matched to base `alien_first_record_source` (not
#' `alien_first_record` with suffix `source_AT`), because longer base names
#' are matched first.
#'
#' If the columns in `x` exactly match `cols` (no suffixed variants), the
#' data is already in single-group format. In this case, the data.frame is
#' returned unchanged with `group_col` set to `NA`.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Auto-detected: no cols or group_col needed
#' taxify("Robinia pseudoacacia") |>
#'   add_alien_first_records(country = c("AT", "DE")) |>
#'   taxify_long()
#'
#' # Explicit: override auto-detection
#' taxify("Robinia pseudoacacia") |>
#'   add_griis(country = c("AT", "DE")) |>
#'   taxify_long(cols = "invasive_status", group_col = "country")
#'
#' options(old)
#'
#' @export
taxify_long <- function(x, cols = NULL, group_col = NULL, drop_na = FALSE) {
  if (!is.data.frame(x)) {
    stop(sprintf("x must be a data.frame, got %s", class(x)[1L]),
         call. = FALSE)
  }

  # Auto-detect from enrichment metadata if cols/group_col not provided
  if (is.null(cols) || is.null(group_col)) {
    reshape_meta <- attr(x, "taxify_reshape")
    if (is.null(reshape_meta) || length(reshape_meta) == 0L) {
      stop(paste0(
        "Cannot auto-detect reshape columns. Either:\n",
        "  - Provide 'cols' and 'group_col' explicitly, or\n",
        "  - Apply a grouped enrichment (add_griis, ",
        "add_alien_first_records, etc.) first."
      ), call. = FALSE)
    }
    if (is.null(cols)) {
      cols <- unique(unlist(lapply(reshape_meta, `[[`, "cols")))
    }
    if (is.null(group_col)) {
      group_cols <- unique(vapply(reshape_meta, `[[`, character(1L), "group_col"))
      if (length(group_cols) > 1L) {
        stop(sprintf(
          paste0("Multiple group columns detected: %s. ",
                 "Specify 'group_col' explicitly."),
          paste(group_cols, collapse = ", ")
        ), call. = FALSE)
      }
      group_col <- group_cols
    }
  }

  if (length(cols) == 0L || !is.character(cols)) {
    stop("cols must be a non-empty character vector of base column names.",
         call. = FALSE)
  }

  all_names <- names(x)

  # Single-group case: base columns exist without suffixes
  if (all(cols %in% all_names)) {
    # Check if there are also suffixed versions
    has_suffixed <- any(vapply(cols, function(base) {
      any(grepl(paste0("^", base, "_.+$"), all_names))
    }, logical(1L)))
    if (!has_suffixed) {
      x[[group_col]] <- NA_character_
      return(x)
    }
  }

  # Detect suffixed columns: match longest base first to avoid ambiguity
  bases_sorted <- cols[order(nchar(cols), decreasing = TRUE)]
  remaining <- all_names
  col_assignments <- list()  # base -> list of (suffix, full_col_name)

  for (base in bases_sorted) {
    pattern <- paste0("^", base, "_(.+)$")
    matches <- grep(pattern, remaining, value = TRUE)
    if (length(matches) > 0L) {
      suffixes <- sub(pattern, "\\1", matches)
      col_assignments[[base]] <- data.frame(
        suffix   = suffixes,
        full_col = matches,
        stringsAsFactors = FALSE
      )
      remaining <- setdiff(remaining, matches)
    }
  }

  if (length(col_assignments) == 0L) {
    stop(sprintf(
      "No suffixed columns found for base names: %s\nAvailable columns: %s",
      paste(cols, collapse = ", "),
      paste(all_names, collapse = ", ")
    ), call. = FALSE)
  }

  # Union of all suffixes across bases (pad NA where a base lacks a suffix)
  groups <- sort(unique(unlist(lapply(col_assignments, function(ca) ca$suffix))))

  # Identify id columns (everything not being reshaped)
  reshape_cols <- unlist(lapply(col_assignments, function(ca) ca$full_col),
                         use.names = FALSE)
  id_cols <- setdiff(all_names, reshape_cols)

  # Build long data: one sub-frame per group, then rbind
  frames <- vector("list", length(groups))
  for (i in seq_along(groups)) {
    g <- groups[i]
    frame <- x[, id_cols, drop = FALSE]
    frame[[group_col]] <- g
    for (base in names(col_assignments)) {
      ca <- col_assignments[[base]]
      idx <- which(ca$suffix == g)
      if (length(idx) == 1L) {
        frame[[base]] <- x[[ca$full_col[idx]]]
      } else {
        frame[[base]] <- NA
      }
    }
    frames[[i]] <- frame
  }

  out <- do.call(rbind, frames)
  rownames(out) <- NULL

  if (drop_na) {
    value_cols <- names(col_assignments)
    all_na <- rowSums(!is.na(out[, value_cols, drop = FALSE])) == 0L
    out <- out[!all_na, , drop = FALSE]
    rownames(out) <- NULL
  }

  out
}

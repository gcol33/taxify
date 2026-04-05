#' Reshape grouped enrichment columns to long format
#'
#' Converts wide-format columns produced by grouped enrichments (e.g.,
#' `invasive_status_AT`, `invasive_status_DE`) back to long format with
#' one row per species x group combination.
#'
#' @param x A data.frame, typically a [taxify()] result after applying
#'   a grouped enrichment like [add_invasive_status()],
#'   [add_alien_first_records()], or [add_wcvp()].
#' @param cols Character vector of base column names to reshape. These are
#'   the column names without the group suffix (e.g., `"invasive_status"`,
#'   not `"invasive_status_AT"`).
#' @param group_col Character. Name for the output group column.
#'   Default `"group"`.
#' @param drop_na Logical. If `TRUE`, drop rows where all value columns
#'   are `NA`. Default `FALSE`.
#'
#' @return A data.frame in long format. All columns from `x` that are not
#'   part of the reshape are preserved. The reshaped columns use their base
#'   names (without suffix), and a new `group_col` column contains the
#'   group code extracted from the suffix.
#'
#' @details
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
#' \dontrun{
#' # Reshape invasive status for multiple countries
#' taxify("Robinia pseudoacacia") |>
#'   add_invasive_status(country = c("AT", "DE")) |>
#'   taxify_long(cols = "invasive_status", group_col = "country")
#'
#' # Reshape alien first records (3 columns per country)
#' taxify("Robinia pseudoacacia") |>
#'   add_alien_first_records(country = c("AT", "DE")) |>
#'   taxify_long(
#'     cols = c("alien_first_record", "alien_first_record_source",
#'              "alien_first_record_reference"),
#'     group_col = "country"
#'   )
#' }
#'
#' @export
taxify_long <- function(x, cols, group_col = "group", drop_na = FALSE) {
  if (!is.data.frame(x)) {
    stop(sprintf("x must be a data.frame, got %s", class(x)[1L]),
         call. = FALSE)
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

  # Extract unique suffixes — must be identical across all matched bases
  suffix_sets <- lapply(col_assignments, function(ca) sort(ca$suffix))
  ref_suffixes <- suffix_sets[[1L]]
  for (i in seq_along(suffix_sets)) {
    if (!identical(suffix_sets[[i]], ref_suffixes)) {
      stop(sprintf(
        paste0("Suffix mismatch: base '%s' has suffixes [%s] but '%s' has [%s].\n",
               "All base columns must have the same set of group suffixes."),
        names(suffix_sets)[1L], paste(ref_suffixes, collapse = ", "),
        names(suffix_sets)[i], paste(suffix_sets[[i]], collapse = ", ")
      ), call. = FALSE)
    }
  }

  groups <- ref_suffixes

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
      src_col <- ca$full_col[ca$suffix == g]
      frame[[base]] <- x[[src_col]]
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

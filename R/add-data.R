#' Add custom data by taxonomic matching
#'
#' Joins an external data source (CSV file or data.frame) to a [taxify()]
#' result. Species names in the external data are matched through the same
#' backbone(s) used in the original `taxify()` call, and the join is performed
#' on `accepted_id` --- so synonyms in either dataset resolve to the same key.
#'
#' @param x A data.frame returned by [taxify()].
#' @param data One of:
#'   - A **data.frame** already in R.
#'   - A **file path** to a `.csv`, `.csv.gz`, `.xlsx`, `.sqlite`/`.db`, or
#'     `.vtr` file (read via vectra).
#' @param species_col Character. Name of the column in `data` that contains
#'   species names. If `NULL` (default), auto-detected by matching `head(10)`
#'   of each character column against the backbone.
#' @param table Character. Required when `data` is a SQLite file --- the table
#'   name to read.
#' @param cols Character vector of column names from `data` to join. If `NULL`
#'   (default), all columns except `species_col` are joined.
#' @param fuzzy Logical. Enable fuzzy matching for names in `data`.
#'   Default `TRUE`.
#' @param fuzzy_threshold Numeric. Maximum allowed distance for fuzzy matches.
#'   Default `0.2`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return The input data.frame with additional columns from `data`, joined
#'   via backbone-resolved `accepted_id`. Columns from `data` that collide
#'   with existing columns in `x` are prefixed with `"data_"`.
#'
#' @details
#' The workflow:
#' 1. Read `data` (CSV or data.frame).
#' 2. Identify the species column (explicit or auto-detected).
#' 3. Match species names through the same backbone(s) as the original
#'    `taxify()` call, obtaining `accepted_id` for each row.
#' 4. Check for conflicting duplicates: if multiple rows in `data` resolve
#'    to the same `accepted_id` with different values, an error is raised.
#'    Exact duplicates produce a warning and are deduplicated.
#' 5. Left-join on `accepted_id`.
#'
#' ## Auto-detection
#' When `species_col` is not specified, `add_data()` takes the first 10 rows
#' of each character column and runs them through `taxify()`. The column with
#' the highest match rate is selected. If no column achieves at least 50%
#' matches, an error is raised asking the user to specify `species_col`
#' explicitly.
#'
#' @examples
#' \dontrun{
#' result <- taxify(c("Quercus robur", "Pinus sylvestris"))
#'
#' # From a CSV file (auto-detect species column)
#' result |> add_data("my_traits.csv")
#'
#' # From a SQLite database
#' result |> add_data("traits.sqlite", table = "plant_traits")
#'
#' # From a data.frame with explicit species column
#' traits <- data.frame(species = c("Quercus robur", "Pinus sylvestris"),
#'                       height = c(30, 25))
#' result |> add_data(traits, species_col = "species")
#'
#' # Select specific columns
#' result |> add_data(traits, species_col = "species", cols = "height")
#' }
#'
#' @export
add_data <- function(x, data,
                     species_col = NULL,
                     table = NULL,
                     cols = NULL,
                     fuzzy = TRUE,
                     fuzzy_threshold = 0.2,
                     verbose = TRUE) {

  if (!"accepted_id" %in% names(x)) {
    stop("x must have an 'accepted_id' column (from taxify())", call. = FALSE)
  }

  meta <- attr(x, "taxify_meta")
  if (is.null(meta) || is.null(meta$backend)) {
    stop("x has no taxify_meta -- was it created by taxify()?", call. = FALSE)
  }
  backend <- meta$backend

  # ---- Read data ----
  if (is.character(data) && length(data) == 1L) {
    data_label <- basename(data)
    if (!file.exists(data)) {
      stop(sprintf("File not found: %s", data), call. = FALSE)
    }
    ext <- tolower(tools::file_ext(data))
    if (ext %in% c("sqlite", "db")) {
      if (is.null(table)) {
        stop("table argument is required for SQLite files.", call. = FALSE)
      }
      data <- vectra::tbl_sqlite(data, table) |> vectra::collect()
    } else if (ext == "csv" || (ext == "gz" && grepl("\\.csv\\.gz$", data, ignore.case = TRUE))) {
      data <- vectra::tbl_csv(data) |> vectra::collect()
    } else if (ext == "xlsx") {
      if (!requireNamespace("openxlsx2", quietly = TRUE)) {
        stop("Reading .xlsx files requires the openxlsx2 package.\n  Install with: install.packages(\"openxlsx2\")",
             call. = FALSE)
      }
      data <- vectra::tbl_xlsx(data) |> vectra::collect()
    } else if (ext == "vtr") {
      data <- vectra::tbl(data) |> vectra::collect()
    } else {
      stop(sprintf(
        "Unsupported file format '.%s'. Supported: .csv, .csv.gz, .xlsx, .sqlite, .db, .vtr.\n  For other formats, read into a data.frame first.",
        ext
      ), call. = FALSE)
    }
  } else if (is.data.frame(data)) {
    data_label <- deparse(substitute(data))
    if (nchar(data_label) > 40L) data_label <- "custom data.frame"
  } else {
    stop("data must be a file path or a data.frame", call. = FALSE)
  }

  if (nrow(data) == 0L) {
    stop("data has 0 rows", call. = FALSE)
  }

  # ---- Detect species column ----
  if (is.null(species_col)) {
    species_col <- detect_species_col(data, backend, verbose = verbose)
  } else {
    if (!species_col %in% names(data)) {
      stop(sprintf("species_col '%s' not found in data. Available: %s",
                   species_col, paste(names(data), collapse = ", ")),
           call. = FALSE)
    }
  }

  # ---- Select trait columns ----
  if (is.null(cols)) {
    cols <- setdiff(names(data), species_col)
  } else {
    missing <- setdiff(cols, names(data))
    if (length(missing) > 0L) {
      stop(sprintf("Column(s) not found in data: %s",
                   paste(missing, collapse = ", ")),
           call. = FALSE)
    }
  }
  if (length(cols) == 0L) {
    stop("No trait columns to join (data only has the species column)",
         call. = FALSE)
  }

  # ---- Match data species through the backbone ----
  species_names <- data[[species_col]]
  if (verbose) {
    message(sprintf("Matching %d names from '%s' through %s backbone...",
                    length(species_names), species_col,
                    paste(toupper(backend), collapse = " + ")))
  }

  data_matched <- taxify(species_names, backend = backend,
                         fuzzy = fuzzy, fuzzy_threshold = fuzzy_threshold,
                         verbose = verbose)

  data$`.add_data_accepted_id` <- data_matched$accepted_id

  # ---- Drop rows that didn't match ----
  n_data_unmatched <- sum(is.na(data$`.add_data_accepted_id`))
  data_joinable <- data[!is.na(data$`.add_data_accepted_id`), , drop = FALSE]

  if (nrow(data_joinable) == 0L) {
    if (verbose) {
      message("0 names in data matched the backbone -- no columns added.")
    }
    return(register_enrichment(x, data_label, data_label, NA_character_, 0L))
  }

  # ---- Check for conflicting duplicates ----
  trait_data <- data_joinable[, c(".add_data_accepted_id", cols), drop = FALSE]
  dup_ids <- trait_data$`.add_data_accepted_id`[
    duplicated(trait_data$`.add_data_accepted_id`)
  ]
  dup_ids <- unique(dup_ids)

  if (length(dup_ids) > 0L) {
    # Check each duplicate: are the trait values identical or conflicting?
    conflicting <- character(0L)
    for (did in dup_ids) {
      rows <- trait_data[trait_data$`.add_data_accepted_id` == did, cols,
                         drop = FALSE]
      # Compare all rows to the first row
      first_row <- rows[1L, , drop = FALSE]
      is_identical <- vapply(seq_len(nrow(rows))[-1L], function(i) {
        identical_row(first_row, rows[i, , drop = FALSE])
      }, logical(1L))
      if (!all(is_identical)) {
        conflicting <- c(conflicting, did)
      }
    }

    if (length(conflicting) > 0L) {
      # Build informative error
      examples <- utils::head(conflicting, 3L)
      example_names <- vapply(examples, function(aid) {
        idx <- which(data_matched$accepted_id == aid)[1L]
        if (!is.na(idx)) data_matched$accepted_name[idx] else aid
      }, character(1L))
      stop(sprintf(
        paste0("%d species in data resolved to the same accepted_id but ",
               "have different trait values.\n",
               "  Examples: %s\n",
               "  Clean the data so each species has one set of values, ",
               "or subset with the `cols` argument."),
        length(conflicting),
        paste(sprintf("'%s' (%s)", example_names, examples), collapse = ", ")
      ), call. = FALSE)
    }

    # Exact duplicates: warn and deduplicate
    n_dup_rows <- sum(duplicated(trait_data$`.add_data_accepted_id`))
    warning(sprintf(
      "%d duplicate rows in data (same accepted_id, identical values) -- deduplicated.",
      n_dup_rows
    ), call. = FALSE)
    trait_data <- trait_data[!duplicated(trait_data$`.add_data_accepted_id`), ,
                            drop = FALSE]
  }

  # ---- Handle column name collisions ----
  existing_cols <- names(x)
  collision <- intersect(cols, existing_cols)
  col_rename <- stats::setNames(cols, cols)
  if (length(collision) > 0L) {
    if (verbose) {
      message(sprintf("Prefixing colliding column(s) with 'data_': %s",
                      paste(collision, collapse = ", ")))
    }
    for (cc in collision) {
      col_rename[cc] <- paste0("data_", cc)
    }
  }

  # ---- Left join on accepted_id ----
  join_lookup <- stats::setNames(
    seq_len(nrow(trait_data)),
    trait_data$`.add_data_accepted_id`
  )

  for (col in cols) {
    out_name <- col_rename[col]
    x[[out_name]] <- NA
    for (i in which(!is.na(x$accepted_id))) {
      idx <- join_lookup[x$accepted_id[i]]
      if (!is.na(idx)) {
        x[[out_name]][i] <- trait_data[[col]][idx]
      }
    }
  }

  # ---- Summary ----
  n_joined <- sum(!is.na(x$accepted_id) &
                    x$accepted_id %in% trait_data$`.add_data_accepted_id`)

  if (verbose) {
    n_x_valid <- sum(!is.na(x$accepted_id))
    message(sprintf(
      "add_data: %d of %d species matched (%0.1f%%). %d names in data unmatched.",
      n_joined, n_x_valid, 100 * n_joined / max(n_x_valid, 1L),
      n_data_unmatched
    ))
  }

  register_enrichment(x, data_label, data_label, NA_character_, n_joined)
}


#' Compare two single-row data.frames for value equality
#'
#' Handles NA == NA as TRUE (both missing = same value).
#'
#' @param a Single-row data.frame.
#' @param b Single-row data.frame.
#' @return Logical scalar.
#' @noRd
identical_row <- function(a, b) {
  for (col in names(a)) {
    va <- a[[col]]
    vb <- b[[col]]
    if (is.na(va) && is.na(vb)) next
    if (is.na(va) || is.na(vb)) return(FALSE)
    if (va != vb) return(FALSE)
  }
  TRUE
}


#' Auto-detect the species name column in a data.frame
#'
#' Tests each character column by matching `head(10)` against the backbone.
#' Returns the column with the highest match rate.
#'
#' @param data A data.frame.
#' @param backend Character vector of backend names.
#' @param verbose Logical.
#' @return Column name (character scalar).
#' @noRd
detect_species_col <- function(data, backend, verbose = TRUE) {
  char_cols <- names(data)[vapply(data, is.character, logical(1L))]

  if (length(char_cols) == 0L) {
    stop("No character columns in data. Specify species_col explicitly.",
         call. = FALSE)
  }

  if (verbose) {
    message(sprintf("Auto-detecting species column among %d character columns...",
                    length(char_cols)))
  }

  n_probe <- min(10L, nrow(data))
  best_col <- NULL
  best_rate <- 0

  for (col in char_cols) {
    probe_names <- utils::head(data[[col]], n_probe)
    probe_names <- probe_names[!is.na(probe_names) & nzchar(probe_names)]
    if (length(probe_names) == 0L) next

    probe_result <- tryCatch(
      taxify(probe_names, backend = backend, verbose = FALSE),
      error = function(e) NULL
    )
    if (is.null(probe_result)) next

    match_rate <- sum(probe_result$match_type != "none") / length(probe_names)
    if (verbose) {
      message(sprintf("  '%s': %d/%d matched (%0.0f%%)",
                      col, sum(probe_result$match_type != "none"),
                      length(probe_names), 100 * match_rate))
    }

    if (match_rate > best_rate) {
      best_rate <- match_rate
      best_col <- col
    }
  }

  if (is.null(best_col) || best_rate < 0.5) {
    stop(sprintf(
      paste0("Could not auto-detect species column (best match rate: %0.0f%%).\n",
             "  Specify species_col explicitly."),
      100 * best_rate
    ), call. = FALSE)
  }

  if (verbose) {
    message(sprintf("Detected species column: '%s' (%0.0f%% match rate)",
                    best_col, 100 * best_rate))
  }
  best_col
}

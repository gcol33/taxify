#' Export a taxify result to file
#'
#' Writes a [taxify()] result (with any enrichments) to disk in one of several
#' formats. The default `.vtr` format preserves column types and is fast to
#' re-read with [add_data()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param path Character. Output file path. The format is inferred from the
#'   extension: `.vtr`, `.csv`, `.tsv`, or `.xlsx`.
#' @param overwrite Logical. Overwrite an existing file? Default `FALSE`.
#'
#' @return Invisibly returns `path`.
#'
#' @examples
#' \dontrun{
#' result <- taxify(c("Quercus robur", "Pinus sylvestris"))
#' result |> add_conservation_status() |> export_data("my_results.vtr")
#' result |> export_data("my_results.csv")
#' result |> export_data("my_results.tsv")
#' }
#'
#' @export
export_data <- function(x, path, overwrite = FALSE) {
  if (!is.data.frame(x)) {
    stop("x must be a data.frame", call. = FALSE)
  }
  if (!is.character(path) || length(path) != 1L) {
    stop("path must be a single file path", call. = FALSE)
  }
  if (file.exists(path) && !overwrite) {
    stop(sprintf("File already exists: %s\n  Use overwrite = TRUE to replace it.",
                 path), call. = FALSE)
  }

  ext <- tolower(tools::file_ext(path))
  if (ext == "") {
    path <- paste0(path, ".vtr")
    ext <- "vtr"
    message(sprintf("No extension detected, writing as .vtr: %s", path))
  }

  if (ext == "vtr") {
    vectra::write_vtr(x, path)
  } else if (ext == "csv") {
    vectra::write_csv(x, path)
  } else if (ext == "tsv") {
    utils::write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE)
  } else if (ext == "xlsx") {
    if (!requireNamespace("openxlsx2", quietly = TRUE)) {
      stop("Writing .xlsx files requires the openxlsx2 package.\n  Install with: install.packages(\"openxlsx2\")",
           call. = FALSE)
    }
    openxlsx2::write_xlsx(x, path)
  } else {
    stop(sprintf(
      "Unsupported format '.%s'. Supported: .vtr, .csv, .tsv, .xlsx.",
      ext
    ), call. = FALSE)
  }

  invisible(path)
}

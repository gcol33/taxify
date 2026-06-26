#' Add WCVP native range status
#'
#' Joins WCVP (World Checklist of Vascular Plants, Kew) native range
#' data to a [taxify()] result, filtered by TDWG botanical region.
#'
#' @param x A data.frame returned by [taxify()].
#' @param region Character. TDWG Level 3 region code(s), or `"all"`. See
#'   [taxify_regions()] for the full list of codes.
#'   \itemize{
#'     \item Single code (e.g., `"BGM"` for Belgium): adds `native_status`
#'       column (no suffix).
#'     \item Multiple codes (e.g., `c("BGM", "GER")`): adds
#'       `native_status_BGM`, `native_status_GER`.
#'     \item `"all"`: adds one column per region in the dataset.
#'   }
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional column(s):
#' \describe{
#'   \item{native_status}{One of `"native"`, `"introduced"`, `"extinct"`,
#'     or `NA` if not recorded for that region.}
#' }
#'
#' @details
#' Source: WCVP (Kew, CC BY). Coverage: ~340k plant species.
#' Plants only.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur") |>
#'   add_wcvp(region = "EUR")
#'
#' taxify("Quercus robur") |>
#'   add_wcvp(region = c("EUR", "NAM"))
#'
#' options(old)
#'
#' @export
add_wcvp <- function(x, region, verbose = TRUE) {
  if (missing(region)) {
    stop("'region' is required. Use a TDWG Level 3 code (e.g., \"BGM\") or \"all\".",
         call. = FALSE)
  }
  enrich_by_group(
    x,
    enrichment_name = "wcvp",
    group_col       = "tdwg_code",
    groups          = region,
    value_cols      = c(native_status = "native_status"),
    source_label    = "WCVP (Kew)",
    verbose         = verbose
  )
}

#' Add WCVP native range status
#'
#' Joins WCVP (World Checklist of Vascular Plants, Kew) native range
#' data to a [taxify()] result, filtered by TDWG botanical region.
#'
#' @param x A data.frame returned by [taxify()].
#' @param region Character. TDWG Level 2 region code(s), or `"all"`.
#'   \itemize{
#'     \item Single code (e.g., `"EUR"`): adds `native_status` column
#'       (no suffix).
#'     \item Multiple codes (e.g., `c("EUR", "NAM")`): adds
#'       `native_status_EUR`, `native_status_NAM`.
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
    stop("'region' is required. Use a TDWG Level 2 code (e.g., \"EUR\") or \"all\".",
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

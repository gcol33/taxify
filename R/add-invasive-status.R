#' Add invasive species status
#'
#' Joins GRIIS (Global Register of Introduced and Invasive Species) data
#' to a [taxify()] result, filtered by country.
#'
#' @param x A data.frame returned by [taxify()].
#' @param country Character. ISO 3166-1 alpha-2 country code(s), or `"all"`.
#'   \itemize{
#'     \item Single code (e.g., `"AT"`): adds `invasive_status` column
#'       (no suffix).
#'     \item Multiple codes (e.g., `c("AT", "DE")`): adds
#'       `invasive_status_AT`, `invasive_status_DE`.
#'     \item `"all"`: adds one column per country in the dataset.
#'   }
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional column(s):
#' \describe{
#'   \item{invasive_status}{One of `"native"`, `"introduced"`, `"invasive"`,
#'     or `NA` if not recorded for that country.}
#' }
#'
#' @details
#' Source: GRIIS (Zenodo combined CSV, CC BY 4.0, 196 countries).
#' Coverage: ~23k name x country combinations.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Robinia pseudoacacia") |>
#'   add_invasive_status(country = "AT")
#'
#' taxify("Robinia pseudoacacia") |>
#'   add_invasive_status(country = c("AT", "DE"))
#'
#' options(old)
#'
#' @export
add_invasive_status <- function(x, country, verbose = TRUE) {
  if (missing(country)) {
    stop("'country' is required. Use an ISO 3166-1 alpha-2 code (e.g., \"AT\") or \"all\".",
         call. = FALSE)
  }
  enrich_by_group(
    x,
    enrichment_name = "griis",
    group_col       = "country_code",
    groups          = country,
    value_cols      = c(invasive_status = "invasive_status"),
    source_label    = "GRIIS",
    verbose         = verbose
  )
}

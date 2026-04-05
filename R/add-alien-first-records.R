#' Add alien species first record years
#'
#' Joins alien species first record data to a [taxify()] result, filtered
#' by country. Data from the Global Alien Species First Record Database
#' (Seebens et al. 2017).
#'
#' @param x A data.frame returned by [taxify()].
#' @param country Character. ISO 3166-1 alpha-2 country code(s), or `"all"`.
#'   \itemize{
#'     \item Single code (e.g., `"AT"`): adds columns without suffix.
#'     \item Multiple codes (e.g., `c("AT", "DE")`): adds columns with
#'       country suffix (e.g., `alien_first_record_AT`).
#'     \item `"all"`: adds one column set per country in the dataset.
#'   }
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional column(s):
#' \describe{
#'   \item{alien_first_record}{Year of the first record (integer), or `NA`
#'     if not recorded for that country.}
#'   \item{alien_first_record_source}{Database that contributed the record
#'     (e.g., `"GAVIA"`, `"CABI ISC"`).}
#'   \item{alien_first_record_reference}{Original citation or reference for
#'     the record.}
#' }
#'
#' @details
#' Source: Global Alien Species First Record Database v3.1
#' (Seebens et al. 2017, Nature Communications 8, 14435). CC BY 4.0.
#' Coverage: ~77k species x country combinations across all taxa.
#'
#' @examples
#' \dontrun{
#' taxify("Robinia pseudoacacia") |>
#'   add_alien_first_records(country = "AT")
#'
#' taxify(c("Robinia pseudoacacia", "Ailanthus altissima")) |>
#'   add_alien_first_records(country = c("AT", "DE"))
#' }
#'
#' @export
add_alien_first_records <- function(x, country, verbose = TRUE) {
  if (missing(country)) {
    stop("'country' is required. Use an ISO 3166-1 alpha-2 code (e.g., \"AT\") or \"all\".",
         call. = FALSE)
  }
  enrich_by_group(
    x,
    enrichment_name = "alien_first_records",
    group_col       = "country_code",
    groups          = country,
    value_cols      = c(
      alien_first_record           = "alien_first_record",
      alien_first_record_source    = "alien_first_record_source",
      alien_first_record_reference = "alien_first_record_reference"
    ),
    source_label    = "Alien first records (Seebens et al.)",
    na_types        = list(alien_first_record = NA_integer_),
    verbose         = verbose
  )
}

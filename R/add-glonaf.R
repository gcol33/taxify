#' Add naturalized alien flora status (GloNAF)
#'
#' Joins GloNAF (Global Naturalized Alien Flora) data to a [taxify()]
#' result, filtered by region.
#'
#' @param x A data.frame returned by [taxify()].
#' @param region Character. GloNAF region identifier(s), or `"all"`.
#'   Regions are ISO 3166 alpha-3 country codes extended with dot notation
#'   for sub-national units (e.g., `"DEU"` for Germany, `"USA.CA"` for
#'   California). List them with `enrichment_groups("glonaf")`.
#'   \itemize{
#'     \item Single region: adds `naturalized` column (no suffix).
#'     \item Multiple regions: adds `naturalized_<region>` columns.
#'     \item `"all"`: adds one column per region in the dataset.
#'   }
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional column(s):
#' \describe{
#'   \item{naturalized}{`1` if the species is recorded as
#'     naturalized in that region, `NA` otherwise.}
#' }
#'
#' @details
#' Source: GloNAF v2.0 (van Kleunen et al. 2019, Davis et al. 2025,
#' CC BY 4.0). Coverage: ~16k alien plant taxa across ~1,300 regions.
#' Plants only.
#'
#' @references
#' van Kleunen M et al. (2019) The Global Naturalized Alien Flora
#' (GloNAF) database. Ecology 100:e02542. \doi{10.1002/ecy.2542}
#'
#' Davis AJS et al. (2025) The updated Global Naturalized Alien Flora
#' (GloNAF 2.0) database. Ecology 106:e70245. \doi{10.1002/ecy.70245}
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Robinia pseudoacacia") |>
#'   add_glonaf(region = "DEU")
#'
#' taxify("Robinia pseudoacacia") |>
#'   add_glonaf(region = c("DEU", "AUT"))
#'
#' options(old)
#'
#' @export
add_glonaf <- function(x, region, verbose = TRUE) {
  if (missing(region)) {
    stop("'region' is required. Use a GloNAF region code or \"all\".",
         call. = FALSE)
  }
  enrich_by_group(
    x,
    enrichment_name = "glonaf",
    group_col       = "region_id",
    groups          = region,
    value_cols      = c(naturalized = "naturalized"),
    source_label    = "GloNAF",
    verbose         = verbose
  )
}

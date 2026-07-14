#' Add United States freshwater fish traits (FishTraits)
#'
#' Joins ecological and life-history traits of United States freshwater fishes
#' from FishTraits (Frimpong & Angermeier 2009) to a [taxify()] result by looking
#' up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{ft_common_name}{Common name.}
#'   \item{ft_native}{Whether native to the contiguous United States.}
#'   \item{ft_max_length_cm}{Maximum total length (cm).}
#'   \item{ft_longevity_yr}{Maximum reported age (years).}
#'   \item{ft_maturity_age_yr}{Age at maturity (years).}
#'   \item{ft_fecundity_max}{Maximum fecundity.}
#'   \item{ft_repro_guild}{Reproductive guild.}
#'   \item{ft_min_temp_c}{Lower temperature tolerance (deg C).}
#'   \item{ft_max_temp_c}{Upper temperature tolerance (deg C).}
#'   \item{ft_extinct}{Whether recorded as extinct.}
#' }
#' `cols = "all"` also attaches the ten diet-category flags, salinity tolerance,
#' flow preferences, migratory strategy, listing status, and the ITIS TSN.
#'
#' @details
#' Source: FishTraits v14.3 (USGS ScienceBase), a public-domain U.S. Government
#' work. North American freshwater fishes.
#'
#' @references
#' Frimpong EA, Angermeier PL (2009) FishTraits: a database of ecological and
#' life-history traits of freshwater fishes of the United States. Fisheries
#' 34:487-495.
#'
#' @examples
#' \dontrun{
#' # Downloads the enrichment on first use.
#' taxify("Micropterus salmoides", backend = "gbif") |>
#'   add_fishtraits()
#' }
#'
#' @export
add_fishtraits <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("common_name", "native", "max_length_cm", "longevity_yr",
            "maturity_age_yr", "fecundity_max", "repro_guild",
            "min_temp_c", "max_temp_c", "extinct")
  col_map <- stats::setNames(base, paste0("ft_", base))
  enrich_simple(
    x, enrichment_name = "fishtraits", col_map = col_map,
    source_label = "FishTraits (Frimpong & Angermeier 2009)",
    cols = cols, col_prefix = "ft_", out_prefix = "ft_", verbose = verbose
  )
}

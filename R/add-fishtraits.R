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
#'   \item{fishtraits_ft_common_name}{Common name.}
#'   \item{fishtraits_ft_native}{Whether native to the contiguous United States.}
#'   \item{fishtraits_ft_max_length_cm}{Maximum total length (cm).}
#'   \item{fishtraits_ft_longevity_yr}{Maximum reported age (years).}
#'   \item{fishtraits_ft_maturity_age_yr}{Age at maturity (years).}
#'   \item{fishtraits_ft_fecundity_max}{Maximum fecundity.}
#'   \item{fishtraits_ft_repro_guild}{Reproductive guild.}
#'   \item{fishtraits_ft_min_temp_c}{Lower temperature tolerance (deg C).}
#'   \item{fishtraits_ft_max_temp_c}{Upper temperature tolerance (deg C).}
#'   \item{fishtraits_ft_extinct}{Whether recorded as extinct.}
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
#' taxify("Micropterus salmoides", backbone = "gbif") |>
#'   add_fishtraits()
#' }
#'
#' @export
add_fishtraits <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_fishtraits, cols = cols, verbose = verbose)
}


.door_fishtraits <- list(
  enrichment_name = "fishtraits",
  col_map = c(
    ft_common_name = "common_name",
    ft_native = "native",
    ft_max_length_cm = "max_length_cm",
    ft_longevity_yr = "longevity_yr",
    ft_maturity_age_yr = "maturity_age_yr",
    ft_fecundity_max = "fecundity_max",
    ft_repro_guild = "repro_guild",
    ft_min_temp_c = "min_temp_c",
    ft_max_temp_c = "max_temp_c",
    ft_extinct = "extinct"
  ),
  source_label = "FishTraits (Frimpong & Angermeier 2009)"
)

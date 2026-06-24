#' Add amphibian life-history traits (AmphiBIO)
#'
#' Joins AmphiBIO amphibian life-history and ecological traits to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{body_size_mm}{Maximum body size in mm (snout-vent length).}
#'   \item{age_maturity_d}{Age at maturity in days.}
#'   \item{longevity_d}{Maximum longevity in days.}
#'   \item{litter_size}{Clutch/litter size.}
#'   \item{reproductive_output}{Reproductive output per year.}
#'   \item{offspring_size_mm}{Offspring size in mm.}
#'   \item{direct_development}{Direct development (0/1).}
#'   \item{larval}{Has larval stage (0/1).}
#'   \item{aquatic}{Aquatic habitat (0/1).}
#'   \item{fossorial}{Fossorial habitat (0/1).}
#'   \item{arboreal}{Arboreal habitat (0/1).}
#'   \item{diurnal}{Diurnal activity (0/1).}
#'   \item{nocturnal_amphibio}{Nocturnal activity (0/1). Named
#'     \code{nocturnal_amphibio} to avoid collision with EltonTraits'
#'     \code{nocturnal} column.}
#' }
#'
#' @details
#' Source: AmphiBIO (Oliveira et al. 2017, CC BY 4.0).
#' Coverage: ~6,800 amphibian species. Amphibians only.
#'
#' @references
#' Oliveira BF, Sao-Pedro VA, Santos-Barrera G, Penone C, Costa GC (2017)
#' AmphiBIO, a global database for amphibian ecological traits. Scientific
#' Data 4:170123.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Bufo bufo", backend = "gbif") |>
#'   add_amphibio()
#'
#' options(old)
#'
#' @export
add_amphibio <- function(x, verbose = TRUE) {
  col_map <- c(
    body_size_mm        = "body_size_mm",
    age_maturity_d      = "age_maturity_d",
    longevity_d         = "longevity_d",
    litter_size         = "litter_size",
    reproductive_output = "reproductive_output",
    offspring_size_mm   = "offspring_size_mm",
    direct_development  = "direct_development",
    larval              = "larval",
    aquatic             = "aquatic",
    fossorial           = "fossorial",
    arboreal            = "arboreal",
    diurnal             = "diurnal",
    nocturnal_amphibio  = "nocturnal_amphibio"
  )
  na_types <- list(
    body_size_mm        = NA_real_,
    age_maturity_d      = NA_real_,
    longevity_d         = NA_real_,
    litter_size         = NA_real_,
    reproductive_output = NA_real_,
    offspring_size_mm   = NA_real_,
    direct_development  = NA_integer_,
    larval              = NA_integer_,
    aquatic             = NA_integer_,
    fossorial           = NA_integer_,
    arboreal            = NA_integer_,
    diurnal             = NA_integer_,
    nocturnal_amphibio  = NA_integer_
  )
  enrich_simple(
    x,
    enrichment_name = "amphibio",
    col_map         = col_map,
    source_label    = "AmphiBIO",
    na_types        = na_types,
    verbose         = verbose
  )
}

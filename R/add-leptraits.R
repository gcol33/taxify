#' Add butterfly traits (LepTraits)
#'
#' Joins LepTraits 1.0 butterfly life-history and ecological traits to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{wingspan_mm}{Wingspan in mm (midpoint of lower and upper bounds).}
#'   \item{voltinism}{Number of generations per year.}
#'   \item{diapause_stage}{Overwintering/diapause life stage.}
#'   \item{canopy_affinity}{Canopy association category.}
#'   \item{edge_affinity}{Edge/gap affinity category.}
#'   \item{moisture_affinity}{Moisture affinity category.}
#'   \item{disturbance_affinity}{Disturbance affinity category.}
#'   \item{n_hostplant_families}{Number of host plant families used.}
#'   \item{flight_months}{Number of months with adult flight activity.}
#' }
#'
#' @details
#' Source: LepTraits 1.0 (Shirey et al. 2022, CC0). Coverage: ~12.4k
#' butterfly species globally (Papilionoidea).
#'
#' @references
#' Shirey V et al. (2022) LepTraits 1.0: A globally comprehensive dataset
#' of butterfly traits. Scientific Data 9:398.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Vanessa cardui", backend = "gbif") |>
#'   add_leptraits()
#'
#' options(old)
#'
#' @export
add_leptraits <- function(x, verbose = TRUE) {
  col_map <- c(
    wingspan_mm           = "wingspan_mm",
    voltinism             = "voltinism",
    diapause_stage        = "diapause_stage",
    canopy_affinity       = "canopy_affinity",
    edge_affinity         = "edge_affinity",
    moisture_affinity     = "moisture_affinity",
    disturbance_affinity  = "disturbance_affinity",
    n_hostplant_families  = "n_hostplant_families",
    flight_months         = "flight_months"
  )
  na_types <- list(
    wingspan_mm          = NA_real_,
    voltinism            = NA_real_,
    diapause_stage       = NA_character_,
    canopy_affinity      = NA_character_,
    edge_affinity        = NA_character_,
    moisture_affinity    = NA_character_,
    disturbance_affinity = NA_character_,
    n_hostplant_families = NA_integer_,
    flight_months        = NA_integer_
  )
  enrich_simple(
    x,
    enrichment_name = "leptraits",
    col_map         = col_map,
    source_label    = "LepTraits",
    na_types        = na_types,
    verbose         = verbose
  )
}

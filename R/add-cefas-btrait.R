#' Add benthic invertebrate traits (Cefas)
#'
#' Joins biological traits of North-West European continental-shelf benthic
#' macrofauna from the Cefas biological-traits database to a [taxify()] result by
#' looking up `genus`. The source fuzzy-codes traits at genus level, and each
#' trait is reduced to its highest-scoring modality, so the join is on `genus`
#' rather than `accepted_name`: every species in a coded genus is annotated.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{cefas_body_size}{Maximum body-size class.}
#'   \item{cefas_morphology}{Body morphology.}
#'   \item{cefas_lifespan}{Life-span class.}
#'   \item{cefas_living_habit}{Living habit.}
#'   \item{cefas_feeding_mode}{Feeding mode.}
#'   \item{cefas_mobility}{Mobility.}
#'   \item{cefas_bioturbation}{Bioturbation mode.}
#' }
#' `cols = "all"` also attaches egg and larval development and sediment position.
#'
#' @details
#' Source: North-West European continental-shelf benthos biological-traits
#' database, Cefas Data Hub (\doi{10.14466/CefasDataHub.123}), Open Government
#' Licence v3.0.
#'
#' @references
#' Centre for Environment, Fisheries and Aquaculture Science (2022) North-West
#' European continental-shelf benthos biological-traits database.
#' \doi{10.14466/CefasDataHub.123}
#'
#' @examples
#' \dontrun{
#' # Downloads the enrichment on first use.
#' taxify("Abra alba", backend = "gbif") |>
#'   add_cefas_btrait()
#' }
#'
#' @export
add_cefas_btrait <- function(x, cols = NULL, verbose = TRUE) {
  base <- c("body_size", "morphology", "lifespan", "living_habit",
            "feeding_mode", "mobility", "bioturbation")
  col_map <- stats::setNames(base, paste0("cefas_", base))
  enrich_simple(
    x, enrichment_name = "cefas_btrait", col_map = col_map,
    source_label = "Cefas benthic traits", join_col = "genus",
    cols = cols, col_prefix = "cefas_", out_prefix = "cefas_", verbose = verbose
  )
}

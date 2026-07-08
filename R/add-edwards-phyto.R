#' Add phytoplankton nutrient-uptake traits (Edwards et al.)
#'
#' Joins species-level phytoplankton nutrient physiology (Droop/Monod uptake and
#' growth parameters for ammonium, nitrate and phosphorus, plus cell size and
#' carbon content) to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The curated set:
#' \describe{
#'   \item{edwards_taxon_group}{Coarse phytoplankton group (diatom, green, ...).}
#'   \item{edwards_habitat_system}{Habitat (marine/freshwater).}
#'   \item{edwards_cell_volume}{Cell volume (micron^3).}
#'   \item{edwards_carbon_per_cell}{Carbon content per cell (pg C).}
#'   \item{edwards_mu_inf_nit}{Maximum growth rate on nitrate (per day).}
#'   \item{edwards_k_nit}{Half-saturation constant for growth on nitrate.}
#'   \item{edwards_qmin_nit}{Minimum cell nitrogen quota.}
#'   \item{edwards_mu_inf_p}{Maximum growth rate on phosphorus (per day).}
#'   \item{edwards_k_p}{Half-saturation constant for growth on phosphorus.}
#'   \item{edwards_qmin_p}{Minimum cell phosphorus quota.}
#' }
#' With `cols = "all"` the full set of ammonium/nitrate/phosphorus uptake and
#' quota parameters (`vmax_amm`, `mu_nit`, `vmax_p`, `qmax_p`, ...) is attached under
#' their source names. All uptake/quota traits are joined on `accepted_name`.
#'
#' @details Source: Edwards et al. (2015, Ecology, CC BY 4.0), a compilation of
#'   phytoplankton nutrient-utilization traits for ~130 species. Single-source
#'   physiological data with no cross-source analogue, so it is surfaced through
#'   this door rather than the cross-source [add_trait()] verb.
#'
#' @references
#' Edwards KF, Thomas MK, Klausmeier CA, Litchman E (2015) Phytoplankton growth
#' and the interaction of light and temperature: A synthesis at the species and
#' community level. Ecology 96(9):2554-2564. \doi{10.1890/14-2252.1}
#'
#' @examples
#' \donttest{
#' taxify("Thalassiosira pseudonana", backend = "gbif") |>
#'   add_edwards_phyto()
#' }
#'
#' @export
add_edwards_phyto <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c(
    edwards_taxon_group    = "taxon_group",
    edwards_habitat_system = "habitat_system"
  )
  num_cols <- c(
    edwards_cell_volume     = "cell_volume",
    edwards_carbon_per_cell = "carbon_per_cell",
    edwards_mu_inf_nit      = "mu_inf_nit",
    edwards_k_nit           = "k_nit",
    edwards_qmin_nit        = "qmin_nit",
    edwards_mu_inf_p        = "mu_inf_p",
    edwards_k_p             = "k_p",
    edwards_qmin_p          = "qmin_p"
  )
  col_map <- c(cat_cols, num_cols)
  enrich_simple(
    x,
    enrichment_name = "edwards_phyto",
    col_map         = col_map,
    source_label    = "Edwards phytoplankton nutrient traits",
    cols            = cols,
    verbose         = verbose
  )
}

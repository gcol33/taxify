#' Add root traits (GRooT)
#'
#' Joins species-level root traits from the Global Root Traits (GRooT) database
#' to a [taxify()] result by looking up `accepted_name`. GRooT aggregates root
#' trait records to per-species means. The `.vtr` carries the full GRooT trait
#' set (38 root traits); the default attaches the nine best-populated key traits,
#' and `cols = "all"` attaches every one. Run `enrichment_cols("groot")` to list
#' them.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the nine key traits below, \code{"all"} every GRooT trait, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns (per-species means). The
#'   default set:
#' \describe{
#'   \item{groot_root_diameter}{Mean root diameter.}
#'   \item{groot_specific_root_length}{Specific root length.}
#'   \item{groot_root_tissue_density}{Root tissue density.}
#'   \item{groot_root_n_concentration}{Root nitrogen concentration.}
#'   \item{groot_root_c_concentration}{Root carbon concentration.}
#'   \item{groot_root_mass_fraction}{Root mass fraction.}
#'   \item{groot_lateral_spread}{Lateral spread.}
#'   \item{groot_root_mycorrhizal_colonization}{Root mycorrhizal colonization
#'     intensity.}
#'   \item{groot_rooting_depth}{Maximum rooting depth.}
#' }
#' `cols = "all"` additionally attaches root chemistry (P/K/Ca/Mg/Mn
#' concentrations, C:N and N:P ratios), architecture (branching density and
#' ratio, stele diameter and fraction, cortex thickness, vessel diameter and
#' number), turnover (root lifespan, production, turnover rate, litter mass-loss
#' rate), and specific root area, respiration, and dry-matter content, among
#' others. Units follow the GRooT data paper; see the reference below.
#'
#' @details
#' Source: GRooT database (Guerrero-Ramirez et al. 2021). Vascular plants.
#' GRooT data are publicly available and used here with the data-paper
#' citation requested by the authors.
#'
#' @references
#' Guerrero-Ramirez NR et al. (2021) Global root traits (GRooT) database.
#' Global Ecology and Biogeography 30:25-37. \doi{10.1111/geb.13179}
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Abies alba") |>
#'   add_groot()
#'
#' options(old)
#'
#' @export
add_groot <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_groot, cols = cols, verbose = verbose)
}


.door_groot <- list(
  enrichment_name = "groot",
  col_map = c(
    root_diameter = "root_diameter",
    specific_root_length = "specific_root_length",
    root_tissue_density = "root_tissue_density",
    root_n_concentration = "root_n_concentration",
    root_c_concentration = "root_c_concentration",
    root_mass_fraction = "root_mass_fraction",
    lateral_spread = "lateral_spread",
    root_mycorrhizal_colonization = "root_mycorrhizal_colonization",
    rooting_depth = "rooting_depth"
  ),
  source_label = "GRooT"
)

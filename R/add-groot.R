#' Add root traits (GRooT)
#'
#' Joins species-level root traits from the Global Root Traits (GRooT) database
#' to a [taxify()] result by looking up `accepted_name`. GRooT aggregates root
#' trait records to per-species means; this layer carries the nine
#' best-populated key traits.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns (per-species means):
#' \describe{
#'   \item{root_diameter}{Mean root diameter.}
#'   \item{specific_root_length}{Specific root length.}
#'   \item{root_tissue_density}{Root tissue density.}
#'   \item{root_n_concentration}{Root nitrogen concentration.}
#'   \item{root_c_concentration}{Root carbon concentration.}
#'   \item{root_mass_fraction}{Root mass fraction.}
#'   \item{lateral_spread}{Lateral spread.}
#'   \item{root_mycorrhizal_colonization}{Root mycorrhizal colonization
#'     intensity.}
#'   \item{rooting_depth}{Maximum rooting depth.}
#' }
#' Units follow the GRooT data paper; see the reference below.
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
add_groot <- function(x, verbose = TRUE) {
  cols <- c(
    "root_diameter", "specific_root_length", "root_tissue_density",
    "root_n_concentration", "root_c_concentration", "root_mass_fraction",
    "lateral_spread", "root_mycorrhizal_colonization", "rooting_depth"
  )
  col_map  <- stats::setNames(cols, cols)
  na_types <- stats::setNames(rep(list(NA_real_), length(cols)), cols)
  enrich_simple(
    x,
    enrichment_name = "groot",
    col_map         = col_map,
    source_label    = "GRooT",
    na_types        = na_types,
    verbose         = verbose
  )
}

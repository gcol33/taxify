#' Add mammal parasite burden (GMPD 2.0)
#'
#' Joins host-level parasite summaries from the Global Mammal Parasite Database
#' (Stephens et al. 2017) to a [taxify()] result by looking up `accepted_name`.
#' The database's host-parasite association records are aggregated to one row per
#' host species.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{gmpd_parasite_richness}{Distinct parasite species recorded for the
#'     host.}
#'   \item{gmpd_n_helminth, gmpd_n_virus, gmpd_n_bacteria, gmpd_n_protozoa,
#'     gmpd_n_arthropod, gmpd_n_fungus, gmpd_n_prion}{Distinct parasite species
#'     by parasite type.}
#'   \item{gmpd_mean_prevalence}{Mean reported prevalence across the host's
#'     records.}
#'   \item{gmpd_host_group}{Host group (carnivores, ungulates, primates).}
#' }
#'
#' @details
#' Covers wild carnivores, ungulates and primates (462 host species).
#'
#' Parasite richness is a sampling-sensitive count: a well-studied host
#' accumulates more recorded parasites than a rarely sampled one, so the values
#' reflect research effort as well as biology.
#'
#' This source states no licence. It is distributed under the journal's
#' version-of-record terms with a citation request, and taxify ships no
#' pre-built copy of it. The first call builds it from the original source on
#' the user's machine, which requires the taxifydb package
#' (`remotes::install_github("gcol33/taxifydb")`). taxify redistributes none of
#' the data. Cite Stephens et al. (2017) for the data.
#'
#' @references
#' Stephens PR, Pappalardo P, Huang S, et al. (2017) Global Mammal Parasite
#' Database version 2.0. Ecology 98:1476. \doi{10.1002/ecy.1799}
#'
#' @examples
#' \dontrun{
#' # Builds the enrichment on first use (needs taxifydb).
#' taxify("Panthera leo", backbone = "gbif") |>
#'   add_gmpd()
#' }
#'
#' @export
add_gmpd <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_gmpd, cols = cols, verbose = verbose)
}


.door_gmpd <- list(
  enrichment_name = "gmpd",
  col_map = c(
    gmpd_parasite_richness = "parasite_richness",
    gmpd_n_helminth = "n_helminth",
    gmpd_n_virus = "n_virus",
    gmpd_n_bacteria = "n_bacteria",
    gmpd_n_protozoa = "n_protozoa",
    gmpd_n_arthropod = "n_arthropod",
    gmpd_n_fungus = "n_fungus",
    gmpd_n_prion = "n_prion",
    gmpd_mean_prevalence = "mean_prevalence",
    gmpd_host_group = "host_group"
  ),
  source_label = "Global Mammal Parasite Database 2.0 (Stephens et al. 2017)"
)

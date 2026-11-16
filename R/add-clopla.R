#' Add clonal and bud-bank traits (CLO-PLA)
#'
#' Joins clonal growth, bud-bank and lifespan traits of the Central European
#' flora (Klimesova et al. 2017) to a [taxify()] result by looking up
#' `accepted_name`. Source records are collapsed to the binomial, so
#' infraspecific rows are aggregated to the species (numeric traits by median,
#' nominal traits by mode).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every trait the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{clopla_clonal}{Clonal growth present.}
#'   \item{clopla_clonalindex}{Clonal index.}
#'   \item{clopla_woody, clopla_annual, clopla_monocarpic,
#'     clopla_polycarpic}{Growth-form and life-cycle flags.}
#'   \item{clopla_persistence}{Persistence of the clonal connection.}
#'   \item{clopla_offspring}{Offspring produced per parent shoot per year.}
#'   \item{clopla_spread}{Lateral spread.}
#'   \item{clopla_BBsize, clopla_BBdepth}{Bud-bank size and depth.}
#'   \item{clopla_finalCGO}{Final clonal growth organ.}
#' }
#' `cols = "all"` attaches every trait the source carries (29 in total: the
#' remaining bud-bank counts by depth class, root-derived bud banks,
#' branching, cyclicity and dispersibility), with codes kept verbatim.
#'
#' @details
#' 2,909 species of the Central European flora.
#'
#' This source states no licence. It is an Ecological Society of America data
#' paper, free to use with citation, and taxify ships no pre-built copy of it.
#' The first call builds it from the original source on the user's machine, which
#' requires the taxifydb package (`remotes::install_github("gcol33/taxifydb")`).
#' taxify redistributes none of the data. Cite Klimesova et al. (2017) for
#' the data.
#'
#' @references
#' Klimesova J, Danihelka J, Chrtek J, de Bello F, Herben T (2017) CLO-PLA: a
#' database of clonal and bud-bank traits of the Central European flora. Ecology
#' 98:1179. \doi{10.1002/ecy.1745}
#'
#' @examples
#' \dontrun{
#' # Builds the enrichment on first use (needs taxifydb).
#' taxify("Trifolium repens", backbone = "gbif") |>
#'   add_clopla()
#' }
#'
#' @export
add_clopla <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_clopla, cols = cols, verbose = verbose)
}


# Trait codes are the source's own (see the CLO-PLA data paper); taxifydb
# keeps them verbatim rather than inventing labels for them.
.door_clopla <- list(
  enrichment_name = "clopla",
  col_map = c(
    clopla_woody = "woody",
    clopla_annual = "annual",
    clopla_perennialnonclonal = "perennialnonclonal",
    clopla_monocarpic = "monocarpic",
    clopla_polycarpic = "polycarpic",
    clopla_clonal = "clonal",
    clopla_Primaryroot = "Primaryroot",
    clopla_BB0 = "BB0",
    clopla_BB0_mn10 = "BB0_mn10",
    clopla_BB_gtmn10 = "BB_gtmn10",
    clopla_BB0R = "BB0R",
    clopla_BB0_mn10R = "BB0_mn10R",
    clopla_BB_gtmn10R = "BB_gtmn10R",
    clopla_BBsize = "BBsize",
    clopla_BBdepth = "BBdepth",
    clopla_BBRsize = "BBRsize",
    clopla_BBRdepth = "BBRdepth",
    clopla_persistence = "persistence",
    clopla_offspring = "offspring",
    clopla_offspring_wsmall = "offspring_wsmall",
    clopla_spread = "spread",
    clopla_clonalindex = "clonalindex",
    clopla_dispersibility = "dispersibility",
    clopla_Rsprouter = "Rsprouter",
    clopla_branching = "branching",
    clopla_cyclicity = "cyclicity",
    clopla_finalCGO = "finalCGO",
    clopla_PositionRB = "PositionRB",
    clopla_RoleRB = "RoleRB"
  ),
  source_label = "CLO-PLA (Klimesova et al. 2017)",
  default_cols = c(
    "clopla_clonal",
    "clopla_clonalindex",
    "clopla_woody",
    "clopla_annual",
    "clopla_monocarpic",
    "clopla_polycarpic",
    "clopla_persistence",
    "clopla_offspring",
    "clopla_spread",
    "clopla_BBsize",
    "clopla_BBdepth",
    "clopla_finalCGO"
  )
)

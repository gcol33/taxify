#' Add economic cost of biological invasions (InvaCost)
#'
#' Joins per-species economic-cost aggregates from InvaCost (Diagne et al. 2020)
#' to a [taxify()] result by looking up `accepted_name`. InvaCost's individual
#' cost estimates are reduced to three per-species indicators; the raw estimate
#' rows are not distributed.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{invacost_cost_total_usd}{Cumulative documented cost in 2017 USD: each
#'     estimate's standardised annual cost expanded across its documented impact
#'     period and summed over all of the species' estimates. Overlapping
#'     estimates are not de-duplicated, so this is a coarse economic-impact
#'     indicator, not an audited figure.}
#'   \item{invacost_cost_n}{Number of cost estimates recorded for the species.}
#'   \item{invacost_cost_type}{Cost type carrying the largest share of the
#'     species' cumulative cost: `damage`, `management`, `mixed`, or
#'     `unspecified`.}
#' }
#'
#' @details
#' Source: InvaCost (Diagne et al. 2020, Scientific Data; database version 4.1,
#' CC BY 4.0). Only the derived per-species aggregates are distributed here. For
#' a rigorous cost analysis (temporal expansion, overlap handling, reliability
#' filtering) use the `invacost` R package on the full database.
#'
#' @references
#' Diagne C et al. (2020) InvaCost, a public database of the economic costs of
#' biological invasions worldwide. Scientific Data 7:277. \doi{10.1038/s41597-020-00586-z}
#'
#' @examples
#' \dontrun{
#' taxify("Solenopsis invicta", backbone = "gbif") |>
#'   add_invacost()
#' }
#'
#' @export
add_invacost <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "invacost",
    col_map = c(
      invacost_cost_total_usd = "cost_total_usd",
      invacost_cost_n         = "cost_n",
      invacost_cost_type      = "cost_type"
    ),
    source_label = "InvaCost (Diagne et al. 2020)",
    cols    = cols,
    verbose = verbose
  )
}

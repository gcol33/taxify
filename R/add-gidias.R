#' Add invasive-species impact (EICAT / SEICAT, GIDIAS)
#'
#' Joins per-species environmental- and socio-economic-impact aggregates from
#' GIDIAS (Bacher et al. 2025), the IPBES invasive-species assessment's global
#' impact compilation, to a [taxify()] result by looking up `accepted_name`.
#' GIDIAS's individual impact records are reduced to per-species indicators; the
#' raw impact records are not distributed.
#'
#' A species' EICAT category is the most severe magnitude among its negative
#' (harmful) environmental-impact records, on the IUCN scale `"MC"` (Minimal
#' Concern), `"MN"` (Minor), `"MO"` (Moderate), `"MR"` (Major, local
#' extinction), `"MV"` (Massive, global extinction), or `"DD"` (Data Deficient);
#' `gidias_seicat_category` applies the same rule to socio-economic impact
#' (SEICAT, `"MC"` to `"MR"`). For impact reconciled across sources, use
#' [add_trait()] with `"environmental_impact"` or `"socioeconomic_impact"`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The default set:
#' \describe{
#'   \item{gidias_eicat_category}{EICAT environmental-impact category
#'     (`MC`/`MN`/`MO`/`MR`/`MV`/`DD`, or `NA` when no negative impact is
#'     recorded).}
#'   \item{gidias_eicat_mechanism}{IUCN EICAT impact mechanism(s) behind the
#'     species' negative environmental impacts.}
#'   \item{gidias_seicat_category}{SEICAT socio-economic-impact category
#'     (`MC`/`MN`/`MO`/`MR`/`DD`, or `NA`).}
#'   \item{gidias_ias_taxon}{Functional group: `Plant`, `Invertebrate`,
#'     `Vertebrate`, or `Microbe`.}
#'   \item{gidias_realms}{Realm(s) the impacts span: terrestrial, freshwater,
#'     and/or marine.}
#'   \item{gidias_n_records}{Number of impact records for the species.}
#'   \item{gidias_n_sources}{Number of distinct sources documenting the impacts.}
#' }
#' `cols = "all"` additionally attaches the numeric EICAT/SEICAT magnitudes
#' (0-3), the affected well-being constituents, kingdom, the negative-record
#' count, and a global-extinction flag.
#'
#' @details
#' Source: GIDIAS (Bacher et al. 2025, Scientific Data; CC BY 4.0), compiled for
#' the IPBES thematic assessment report on invasive alien species. Only the
#' derived per-species aggregates are distributed here, not the raw impact
#' records.
#'
#' @references
#' Bacher S et al. (2025) Global Impacts Dataset of Invasive Alien Species
#' (GIDIAS). Scientific Data 12:832. \doi{10.1038/s41597-025-05184-5}
#'
#' @examples
#' \dontrun{
#' # Downloads the GIDIAS enrichment on first use.
#' taxify("Felis catus", backend = "gbif") |>
#'   add_gidias()
#' }
#'
#' @export
add_gidias <- function(x, cols = NULL, verbose = TRUE) {
  base_cols <- c(
    "gidias_eicat_category", "gidias_eicat_mechanism",
    "gidias_seicat_category", "gidias_ias_taxon", "gidias_realms",
    "gidias_n_records", "gidias_n_sources"
  )
  col_map <- stats::setNames(base_cols, base_cols)
  enrich_simple(
    x,
    enrichment_name = "gidias",
    col_map         = col_map,
    source_label    = "GIDIAS (Bacher et al. 2025)",
    cols            = cols,
    col_prefix      = "gidias_",
    verbose         = verbose
  )
}

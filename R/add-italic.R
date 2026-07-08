#' Add Italian-lichen taxon-page traits (ITALIC)
#'
#' Joins per-species morphological and ecological descriptors from ITALIC, the
#' Information System on Italian Lichens, to a [taxify()] result by looking up
#' `accepted_name`. One row per species, scraped from the ITALIC 8.0 taxon
#' pages.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) or \code{"all"}
#'   attaches every column the source carries, or a character vector of names.
#'   See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{growth_form}{Thallus growth form (crustose, foliose, fruticose, ...).}
#'   \item{substrata}{Substrata the species grows on.}
#'   \item{photobiont}{Photosynthetic partner.}
#'   \item{reproductive_strategy}{Reproductive strategy.}
#' }
#'
#' @details
#' Source: ITALIC 8.0 (Nimis; Univ. of Trieste), taxon-page descriptors,
#' CC BY-SA 4.0. Lichens are otherwise almost absent from the bundled trait
#' databases.
#'
#' @references
#' Nimis PL. ITALIC - The Information System on Italian Lichens, Version 8.0.
#' University of Trieste, Dept. of Biology (https://italic.units.it), accessed
#' 2026-07. System paper: Martellos S, Conti M, Nimis PL (2023) Aggregation of
#' Italian Lichen Data in ITALIC 7.0. Journal of Fungi 9(5):556.
#' doi:10.3390/jof9050556
#'
#' @examples
#' \donttest{
#' taxify("Xanthoria parietina", backend = "gbif") |>
#'   add_italic()
#' }
#'
#' @export
add_italic <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "italic",
    col_map = c(
      growth_form           = "growth_form",
      substrata             = "substrata",
      photobiont            = "photobiont",
      reproductive_strategy = "reproductive_strategy"
    ),
    source_label = "ITALIC 8.0 (Italian lichens)",
    cols         = cols,
    verbose      = verbose
  )
}

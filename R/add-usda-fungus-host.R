#' Add fungal host breadth (USDA Fungus-Host Dataset)
#'
#' Joins per-fungus host breadth from the USDA National Fungus Collections
#' Fungus-Host Dataset to a [taxify()] result by looking up `accepted_name`.
#' Each fungus species is summarised by how many distinct host plants and host
#' plant genera it has been recorded on.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{fungus_host_count}{Number of distinct host plant species recorded.}
#'   \item{fungus_host_genus_count}{Number of distinct host plant genera
#'     recorded.}
#' }
#'
#' @details
#' Source: Farr, Rossman & Castlebury (2021) United States National Fungus
#' Collections Fungus-Host Dataset, Ag Data Commons (U.S. Public Domain).
#' Fungi only; ~99k species with at least one recorded host.
#'
#' @references
#' Farr DF, Rossman AY, Castlebury LA (2021) United States National Fungus
#' Collections Fungus-Host Dataset. Ag Data Commons. doi:10.15482/USDA.ADC/1524414
#'
#' @export
add_usda_fungus_host <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "usda_fungus_host",
    col_map         = c(fungus_host_count       = "fungus_host_count",
                        fungus_host_genus_count = "fungus_host_genus_count"),
    source_label    = "USDA Fungus-Host (Farr et al. 2021)",
    cols            = cols,
    verbose         = verbose
  )
}

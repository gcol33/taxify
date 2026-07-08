#' Add Lepidoptera hostplant breadth (NHM HOSTS)
#'
#' Joins per-insect hostplant breadth from the Natural History Museum HOSTS
#' database to a [taxify()] result by looking up `accepted_name`. Each moth or
#' butterfly species is summarised by how many distinct hostplants and
#' hostplant families it has been recorded feeding on.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{host_plant_count}{Number of distinct hostplant species recorded.}
#'   \item{host_family_count}{Number of distinct hostplant families recorded.}
#' }
#'
#' @details
#' Source: Robinson et al. (2010) HOSTS, Natural History Museum, London (CC0).
#' Lepidoptera only; ~24k species with at least one recorded hostplant.
#'
#' @references
#' Robinson GS, Ackery PR, Kitching IJ, Beccaloni GW, Hernandez LM (2010)
#' HOSTS - a Database of the World's Lepidopteran Hostplants. Natural History
#' Museum, London. doi:10.5519/havt50xw
#'
#' @examples
#' \donttest{
#' taxify("Papilio machaon", backend = "gbif") |>
#'   add_hosts()
#' }
#'
#' @export
add_hosts <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "hosts",
    col_map         = c(host_plant_count  = "host_plant_count",
                        host_family_count = "host_family_count"),
    source_label    = "NHM HOSTS (Robinson et al. 2010)",
    cols            = cols,
    verbose         = verbose
  )
}

#' Add biotic interaction degree (GloBI)
#'
#' Joins per-species biotic interaction breadth from GloBI (Global Biotic
#' Interactions) to a [taxify()] result by looking up `accepted_name`. GloBI's
#' aggregated interaction records are reduced to per-species counts: how many
#' distinct partner taxa a species interacts with (undirected), across how many
#' distinct interaction types, over how many interaction records.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{interaction_degree}{Number of distinct partner taxa recorded
#'     interacting with the species (both directions).}
#'   \item{n_interaction_types}{Number of distinct interaction types
#'     (eats, pollinates, parasitises, ...).}
#'   \item{n_interaction_records}{Total number of interaction records touching
#'     the species.}
#' }
#'
#' @details
#' Source: GloBI (Poelen et al. 2014), an open index of biotic interactions
#' aggregated from many contributed datasets. Only derived per-species counts
#' are distributed here; the underlying interaction records carry the licenses
#' of their original data contributors, who should be cited in derivative work.
#' Partner counts are resolved to accepted names before counting, so synonymous
#' partners are not double-counted.
#'
#' @references
#' Poelen JH, Simons JD, Mungall CJ (2014) Global Biotic Interactions: An open
#' infrastructure to share and analyze species-interaction datasets. Ecological
#' Informatics 24:148-159. doi:10.1016/j.ecoinf.2014.08.005
#'
#' @export
add_globi <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "globi",
    col_map = c(
      interaction_degree    = "interaction_degree",
      n_interaction_types   = "n_interaction_types",
      n_interaction_records = "n_interaction_records"
    ),
    source_label = "GloBI (Poelen et al. 2014)",
    cols         = cols,
    verbose      = verbose
  )
}

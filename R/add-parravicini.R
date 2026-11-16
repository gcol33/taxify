#' Add reef-fish trophic guild (Parravicini)
#'
#' Joins the consensus reef-fish trophic-guild assignment to a [taxify()] result
#' by `accepted_name`. The guild is the modal expert classification.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with categorical `parravicini_trophic_guild`.
#'
#' @details Source: Parravicini et al. (2020) reef-fish trophic guilds (PLoS
#'   Biology, CC-BY 4.0).
#'
#' @references
#' Parravicini V et al. (2020) Delineating reef fish trophic guilds with global
#' gut content data synthesis and phylogeny. PLoS Biology 18:e3000702.
#' \doi{10.1371/journal.pbio.3000702}
#'
#' @examples
#' \dontrun{
#' taxify("Zebrasoma scopas", backbone = "gbif") |>
#'   add_parravicini()
#' }
#'
#' @export
add_parravicini <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_parravicini, cols = cols, verbose = verbose)
}


.door_parravicini <- list(
  enrichment_name = "parravicini",
  col_map = c(parravicini_trophic_guild = "trophic_guild"),
  source_label = "Parravicini reef-fish trophic guilds"
)

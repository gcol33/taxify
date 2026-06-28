#' Add reef-fish trophic guild (Parravicini)
#'
#' Joins the consensus reef-fish trophic-guild assignment to a [taxify()] result
#' by `accepted_name`. The guild is the modal expert classification.
#'
#' @param x A data.frame returned by [taxify()].
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
#' \donttest{
#' taxify("Zebrasoma scopas", backend = "gbif") |>
#'   add_parravicini()
#' }
#'
#' @export
add_parravicini <- function(x, verbose = TRUE) {
  col_map <- c(parravicini_trophic_guild = "trophic_guild")
  na_types <- list(parravicini_trophic_guild = NA_character_)
  enrich_simple(
    x,
    enrichment_name = "parravicini",
    col_map         = col_map,
    source_label    = "Parravicini reef-fish trophic guilds",
    na_types        = na_types,
    verbose         = verbose
  )
}

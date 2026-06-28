#' Add sex-determination traits (Tree of Sex)
#'
#' Joins sexual-system and sex-determination traits to a [taxify()] result by
#' looking up `accepted_name`. Covers plants, vertebrates and invertebrates;
#' some traits are group-specific (selfing for plants, environmental sex
#' determination for vertebrates, haplodiploidy for invertebrates).
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{tos_taxon_group}{Source group (plants/vertebrates/invertebrates).}
#'   \item{tos_sexual_system}{Sexual system (vocabulary differs by group).}
#'   \item{tos_karyotype}{Sex-chromosome system (XY/ZW/XO/homomorphic/...).}
#'   \item{tos_genotypic}{Heterogamety (male/female heterogametic/GSD/...).}
#'   \item{tos_molecular_basis}{Molecular basis (Y dominant/W dominant/dosage).}
#'   \item{tos_selfing}{Selfing (plants; self compatible/incompatible).}
#'   \item{tos_environmental_sd}{Environmental sex determination (vertebrates;
#'     TSD/...).}
#'   \item{tos_haplodiploidy}{Haplodiploidy (invertebrates).}
#' }
#'
#' @details
#' Source: Tree of Sex (Tree of Sex Consortium 2014, Scientific Data, CC0).
#' Coverage: ~37.5k species across plants, vertebrates and invertebrates.
#'
#' @references
#' The Tree of Sex Consortium (2014) Tree of Sex: a database of sexual systems.
#' Scientific Data 1:140015. \doi{10.1038/sdata.2014.15}
#'
#' @examples
#' \donttest{
#' taxify("Silene latifolia", backend = "gbif") |>
#'   add_tree_of_sex()
#' }
#'
#' @export
add_tree_of_sex <- function(x, verbose = TRUE) {
  col_map <- c(
    tos_taxon_group     = "taxon_group",
    tos_sexual_system   = "sexual_system",
    tos_karyotype       = "karyotype",
    tos_genotypic       = "genotypic",
    tos_molecular_basis = "molecular_basis",
    tos_selfing         = "selfing",
    tos_environmental_sd = "environmental_sd",
    tos_haplodiploidy   = "haplodiploidy"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "tree_of_sex",
    col_map         = col_map,
    source_label    = "Tree of Sex",
    na_types        = na_types,
    verbose         = verbose
  )
}

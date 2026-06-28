#' Add mammal traits including extinct species (PHYLACINE)
#'
#' Joins PHYLACINE mammal traits to a [taxify()] result by looking up
#' `accepted_name`. PHYLACINE covers extant plus recently and prehistorically
#' extinct mammals; it is offered alongside [add_pantheria()] and
#' [add_combine()], not as a replacement.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{phylacine_mass_g}{Body mass (g).}
#'   \item{phylacine_diet_plant_pct}{Percent of diet that is plant.}
#'   \item{phylacine_diet_vertebrate_pct}{Percent of diet that is vertebrate.}
#'   \item{phylacine_diet_invertebrate_pct}{Percent of diet that is
#'     invertebrate.}
#'   \item{phylacine_terrestrial}{Terrestrial habit (0/1).}
#'   \item{phylacine_marine}{Marine habit (0/1).}
#'   \item{phylacine_freshwater}{Freshwater habit (0/1).}
#'   \item{phylacine_aerial}{Aerial habit (0/1).}
#'   \item{phylacine_island_endemicity}{Island endemicity class.}
#'   \item{phylacine_iucn_status}{IUCN status (includes EP = extinct in
#'     prehistory, EX, EW).}
#' }
#'
#' @details
#' Source: PHYLACINE v1.2 (Faurby et al. 2018, Ecology, CC0). Coverage: ~5.8k
#' mammal species including extinct taxa.
#'
#' @references
#' Faurby S et al. (2018) PHYLACINE 1.2: The Phylogenetic Atlas of Mammal
#' Macroecology. Ecology 99:2626. \doi{10.1002/ecy.2443}
#'
#' @examples
#' \donttest{
#' taxify("Mammuthus primigenius", backend = "gbif") |>
#'   add_phylacine()
#' }
#'
#' @export
add_phylacine <- function(x, verbose = TRUE) {
  col_map <- c(
    phylacine_mass_g                 = "mass_g",
    phylacine_diet_plant_pct         = "diet_plant_pct",
    phylacine_diet_vertebrate_pct    = "diet_vertebrate_pct",
    phylacine_diet_invertebrate_pct  = "diet_invertebrate_pct",
    phylacine_terrestrial            = "terrestrial",
    phylacine_marine                 = "marine",
    phylacine_freshwater             = "freshwater",
    phylacine_aerial                 = "aerial",
    phylacine_island_endemicity      = "island_endemicity",
    phylacine_iucn_status            = "iucn_status"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  na_types[c("phylacine_island_endemicity",
             "phylacine_iucn_status")] <- list(NA_character_)
  enrich_simple(
    x,
    enrichment_name = "phylacine",
    col_map         = col_map,
    source_label    = "PHYLACINE",
    na_types        = na_types,
    verbose         = verbose
  )
}

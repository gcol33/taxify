#' Add fungal lifestyle and trait data (FungalTraits)
#'
#' Joins FungalTraits (Polme et al. 2020) genus-level trait data to a
#' [taxify()] result by looking up `genus`. Unlike other enrichments that
#' join on species-level `accepted_name`, FungalTraits is a genus-level
#' database and joins on the `genus` column already present in taxify output.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{primary_lifestyle}{Primary ecological role (e.g., saprotroph,
#'     mycorrhizal, pathogen, endophyte, lichenized, parasite).}
#'   \item{secondary_lifestyle}{Secondary ecological role, if any.}
#'   \item{growth_form}{Morphological growth form (e.g., agaricoid,
#'     corticioid, polyporoid, yeast).}
#'   \item{fruitbody_type}{Fruiting body morphology (e.g., gasteroid,
#'     pileate, resupinate).}
#'   \item{decay_substrate}{Substrate type for saprotrophic genera
#'     (e.g., wood, litter, dung, soil).}
#'   \item{plant_pathogenic_capacity}{Capacity to cause plant disease
#'     (e.g., high, medium, low, none).}
#'   \item{animal_biotrophic_capacity}{Capacity for animal biotrophy.}
#'   \item{endophytic_interaction_capability}{Capacity for endophytic
#'     interactions with plants.}
#'   \item{ectomycorrhiza_exploration_type}{Exploration type for
#'     ectomycorrhizal genera (e.g., contact, short, medium, long).}
#' }
#'
#' @details
#' Source: FungalTraits (Polme et al. 2020, Fungal Diversity, CC BY 4.0).
#' Coverage: ~10k fungal genera. Genus-level only (not species-level).
#'
#' @references
#' Polme S et al. (2020) FungalTraits: a user-friendly traits database
#' of fungi and fungus-like stramenopiles. Fungal Diversity 105:1-16.
#' doi:10.1007/s13225-020-00466-2
#'
#' @examples
#' \dontrun{
#' taxify("Amanita muscaria") |>
#'   add_fungal_traits()
#' }
#'
#' @export
add_fungal_traits <- function(x, verbose = TRUE) {
  col_map <- c(
    primary_lifestyle                  = "primary_lifestyle",
    secondary_lifestyle                = "secondary_lifestyle",
    growth_form                        = "growth_form",
    fruitbody_type                     = "fruitbody_type",
    decay_substrate                    = "decay_substrate",
    plant_pathogenic_capacity          = "plant_pathogenic_capacity",
    animal_biotrophic_capacity         = "animal_biotrophic_capacity",
    endophytic_interaction_capability  = "endophytic_interaction_capability",
    ectomycorrhiza_exploration_type    = "ectomycorrhiza_exploration_type"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "fungal_traits",
    col_map         = col_map,
    source_label    = "FungalTraits",
    na_types        = na_types,
    join_col        = "genus",
    verbose         = verbose
  )
}

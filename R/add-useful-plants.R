#' Add human-use categories (World Checklist of Useful Plant Species)
#'
#' Joins plant human-use categories to a [taxify()] result by looking up
#' `accepted_name`. Each of the ten Level-1 use categories is a 0/1 flag, plus a
#' crop-wild-relative flag.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{useful_animal_food}{Animal food (0/1).}
#'   \item{useful_environmental_uses}{Environmental uses (0/1).}
#'   \item{useful_fuels}{Fuels (0/1).}
#'   \item{useful_gene_sources}{Gene sources (0/1).}
#'   \item{useful_human_food}{Human food (0/1).}
#'   \item{useful_invertebrate_food}{Invertebrate food (0/1).}
#'   \item{useful_materials}{Materials (0/1).}
#'   \item{useful_medicines}{Medicines (0/1).}
#'   \item{useful_poisons}{Poisons (0/1).}
#'   \item{useful_social_uses}{Social uses (0/1).}
#'   \item{useful_crop_wild_relative}{Crop wild relative (0/1).}
#' }
#'
#' @details
#' Source: World Checklist of Useful Plant Species (Diazgranados et al. 2020,
#' KNB, CC BY 4.0). Coverage: ~39k plant species.
#'
#' @references
#' Diazgranados M et al. (2020) World Checklist of Useful Plant Species.
#' Knowledge Network for Biocomplexity. \doi{10.5063/F1CV4G34}
#'
#' @examples
#' \donttest{
#' taxify("Acorus calamus", backend = "gbif") |>
#'   add_useful_plants()
#' }
#'
#' @export
add_useful_plants <- function(x, verbose = TRUE) {
  col_map <- c(
    useful_animal_food        = "animal_food",
    useful_environmental_uses = "environmental_uses",
    useful_fuels              = "fuels",
    useful_gene_sources       = "gene_sources",
    useful_human_food         = "human_food",
    useful_invertebrate_food  = "invertebrate_food",
    useful_materials          = "materials",
    useful_medicines          = "medicines",
    useful_poisons            = "poisons",
    useful_social_uses        = "social_uses",
    useful_crop_wild_relative = "crop_wild_relative"
  )
  na_types <- stats::setNames(
    rep(list(NA_real_), length(col_map)), names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "useful_plants",
    col_map         = col_map,
    source_label    = "World Checklist of Useful Plant Species",
    na_types        = na_types,
    verbose         = verbose
  )
}

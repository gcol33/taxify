#' Add fungal functional guild data (FUNGuild)
#'
#' Joins FUNGuild trophic mode, guild, growth morphology, and confidence
#' data to a [taxify()] result by looking up `accepted_name`. Species-level
#' matches take priority; genus-level guild assignments are used as fallback
#' for unmatched species.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{trophic_mode}{Trophic mode (e.g., Pathotroph, Saprotroph,
#'     Symbiotroph, or hyphenated combinations).}
#'   \item{guild}{Functional guild (e.g., "Ectomycorrhizal",
#'     "Plant Pathogen", "Wood Saprotroph").}
#'   \item{funguild_growth_form}{Growth morphology (e.g., "Agaricoid",
#'     "Microfungus"). Prefixed to avoid collision with FungalTraits.}
#'   \item{confidence_ranking}{Confidence of the guild assignment
#'     (Possible, Probable, Highly Probable).}
#' }
#'
#' @details
#' Source: FUNGuild (Nguyen et al. 2016, CC BY 4.0). Coverage: ~13k taxa.
#' Fungi only.
#'
#' The enrichment first attempts species-level matching. For species without
#' a direct match, it falls back to genus-level guild assignments from
#' FUNGuild's genus-rank entries.
#'
#' @references
#' Nguyen NH et al. (2016) FUNGuild: An open annotation tool for parsing
#' fungal community datasets by ecological guild. Fungal Ecology 20:241-248.
#'
#' @examples
#' \dontrun{
#' taxify("Amanita muscaria") |>
#'   add_funguild()
#' }
#'
#' @export
add_funguild <- function(x, verbose = TRUE) {
  col_map <- c(
    trophic_mode        = "trophic_mode",
    guild               = "guild",
    funguild_growth_form = "growth_morphology",
    confidence_ranking  = "confidence_ranking"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)),
    names(col_map)
  )
  enrich_simple(
    x,
    enrichment_name = "funguild",
    col_map         = col_map,
    source_label    = "FUNGuild",
    na_types        = na_types,
    verbose         = verbose
  )
}

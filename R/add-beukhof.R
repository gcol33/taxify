#' Add marine fish traits (Beukhof)
#'
#' Joins North Atlantic / NE Pacific shelf marine-fish life-history and ecology
#' traits to a [taxify()] result by `accepted_name` (species-level summaries).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `beukhof_` columns: numeric `beukhof_trophic_level`,
#'   `beukhof_aspect_ratio`, `beukhof_offspring_size`, `beukhof_age_maturity`, `beukhof_fecundity`,
#'   `beukhof_length_infinity_cm`, `beukhof_growth_coefficient`, `beukhof_length_max_cm`; categorical
#'   `beukhof_habitat`, `beukhof_feeding_mode`, `beukhof_body_shape`, `beukhof_fin_shape`, `beukhof_spawning_type`.
#'
#' @details Source: Beukhof et al. (2019) marine fish trait collection (PANGAEA,
#'   CC-BY 4.0).
#'
#' @references
#' Beukhof E et al. (2019) A trait collection of marine fish species from North
#' Atlantic and Northeast Pacific continental shelf seas. PANGAEA.
#' \doi{10.1594/PANGAEA.900866}
#'
#' @examples
#' \dontrun{
#' taxify("Gadus morhua", backbone = "gbif") |>
#'   add_beukhof()
#' }
#'
#' @export
add_beukhof <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_beukhof, cols = cols, verbose = verbose)
}


.door_beukhof <- list(
  enrichment_name = "beukhof",
  col_map = c(
    beukhof_trophic_level = "trophic_level",
    beukhof_aspect_ratio = "aspect_ratio",
    beukhof_offspring_size = "offspring_size",
    beukhof_age_maturity = "age_maturity",
    beukhof_fecundity = "fecundity",
    beukhof_length_infinity_cm = "length_infinity_cm",
    beukhof_growth_coefficient = "growth_coefficient",
    beukhof_length_max_cm = "length_max_cm",
    beukhof_habitat = "habitat",
    beukhof_feeding_mode = "feeding_mode",
    beukhof_body_shape = "body_shape",
    beukhof_fin_shape = "fin_shape",
    beukhof_spawning_type = "spawning_type"
  ),
  source_label = "Beukhof marine fish"
)

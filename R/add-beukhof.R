#' Add marine fish traits (Beukhof)
#'
#' Joins North Atlantic / NE Pacific shelf marine-fish life-history and ecology
#' traits to a [taxify()] result by `accepted_name` (species-level summaries).
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `beukhof_` columns: numeric `trophic_level`,
#'   `aspect_ratio`, `offspring_size`, `age_maturity`, `fecundity`,
#'   `length_infinity_cm`, `growth_coefficient`, `length_max_cm`; categorical
#'   `habitat`, `feeding_mode`, `body_shape`, `fin_shape`, `spawning_type`.
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
  num_cols <- c("trophic_level", "aspect_ratio", "offspring_size",
                "age_maturity", "fecundity", "length_infinity_cm",
                "growth_coefficient", "length_max_cm")
  cat_cols <- c("habitat", "feeding_mode", "body_shape", "fin_shape",
                "spawning_type")
  all_cols <- c(num_cols, cat_cols)
  col_map <- stats::setNames(all_cols, paste0("beukhof_", all_cols))
  enrich_simple(
    x,
    enrichment_name = "beukhof",
    col_map         = col_map,
    source_label    = "Beukhof marine fish",
    cols            = cols,
    verbose         = verbose
  )
}

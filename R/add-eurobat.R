#' Add European bat traits (EuroBaTrait)
#'
#' Joins species-level traits of European bats (morphology, life history, diet,
#' foraging habitat, roost type) to a [taxify()] result by looking up
#' `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The curated set:
#' \describe{
#'   \item{eurobat_forearm_length_mm}{Forearm length (mm).}
#'   \item{eurobat_body_mass_g}{Body mass (g).}
#'   \item{eurobat_max_longevity_yr}{Maximum recorded longevity (years).}
#'   \item{eurobat_litter_size}{Litter size.}
#'   \item{eurobat_diet_type}{Diet type (insectivorous, frugivorous, ...).}
#'   \item{eurobat_first_main_prey}{First main prey item.}
#' }
#' With `cols = "all"` the full trait set (digit lengths, wing indices, habitat
#' affinity scores, critical feeding areas, roost dependence, phenology, ...) is
#' attached under their source names.
#'
#' @details Source: Froidevaux et al. (2023, Scientific Data, CC BY 4.0),
#'   EuroBaTrait 1.0. Thematic measurement-or-fact tables are reduced to
#'   species-level values (numeric by median, categorical by mode).
#'
#' @references
#' Froidevaux JSP et al. (2023) EuroBaTrait 1.0: a species-level trait dataset
#' of bats in Europe and beyond. Scientific Data. figshare
#' \doi{10.6084/m9.figshare.21777161}
#'
#' @examples
#' \donttest{
#' taxify("Myotis myotis", backend = "gbif") |>
#'   add_eurobat()
#' }
#'
#' @export
add_eurobat <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c(
    eurobat_diet_type       = "diet_type",
    eurobat_first_main_prey = "first_main_prey"
  )
  num_cols <- c(
    eurobat_forearm_length_mm = "forearm_length_mm",
    eurobat_body_mass_g       = "body_mass_g",
    eurobat_max_longevity_yr  = "max_longevity_yr",
    eurobat_litter_size       = "litter_size"
  )
  col_map  <- c(cat_cols, num_cols)
  enrich_simple(
    x,
    enrichment_name = "eurobat",
    col_map         = col_map,
    source_label    = "EuroBaTrait European bat traits",
    cols            = cols,
    verbose         = verbose
  )
}

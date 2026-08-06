#' Add Collembola ecomorphosis (Bonfanti et al. 2022)
#'
#' Joins the ecomorphosis record of a springtail species to a [taxify()] result
#' by looking up `accepted_name`. Ecomorphosis is a seasonal, reversible change
#' of form some Collembola undergo; this marks the species known to display it.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{ecomorphosis}{Whether the species is known to display ecomorphosis.}
#'   \item{ecomorphosis_area}{The morphological area affected.}
#'   \item{ecomorphosis_reference}{The literature record establishing it.}
#' }
#'
#' @details
#' Source: extended species list of Collembola known to display ecomorphosis,
#' Bonfanti (2022), Zenodo, CC BY 4.0. Coverage: 43 species, each carrying the
#' literature record for its ecomorphic form. It is a presence list: a species
#' not listed is not evidence of absence.
#'
#' @references
#' Bonfanti J, Krogh PH, Hedde M, Cortet J (2022) Ecomorphosis in European
#' Collembola: a review in the context of trait-based ecology. Applied Soil
#' Ecology. \doi{10.1016/j.apsoil.2022.104692}
#'
#' @examples
#' \dontrun{
#' taxify("Hypogastrura vesiculosa", backbone = "gbif") |>
#'   add_ecomorphosis()
#' }
#'
#' @export
add_ecomorphosis <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("ecomorphosis", "ecomorphosis_area", "ecomorphosis_reference")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "ecomorphosis",
    col_map         = col_map,
    source_label    = "Collembola ecomorphosis (Bonfanti et al. 2022)",
    cols            = cols,
    verbose         = verbose
  )
}

#' Add marine protist functional traits (Ramond et al.)
#'
#' Joins genus-level morphological, behavioural and ecological traits of marine
#' protists to a [taxify()] result by looking up `genus`, so any species in a
#' covered genus is annotated.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The curated set:
#' \describe{
#'   \item{ramond_shape}{Cell shape (round, elongated, amoeboid, ...).}
#'   \item{ramond_motility}{Motility mode (swimmer, floater, gliding, ...).}
#'   \item{ramond_ingestion}{Ingestion / trophic mode (phagotrophic, ...).}
#'   \item{ramond_chloroplast}{Chloroplast presence (1 = present).}
#'   \item{ramond_symbiontic}{Symbiotic relationship (parasite, mutualist, ...).}
#'   \item{ramond_colony}{Colony form.}
#'   \item{ramond_salinity}{Salinity preference.}
#'   \item{ramond_size_min_um}{Minimum cell size (micrometres).}
#'   \item{ramond_size_max_um}{Maximum cell size (micrometres).}
#' }
#' With `cols = "all"` the full set of behavioural, ecological and symbiosis
#' descriptors is attached under their source names.
#'
#' @details Source: Ramond et al. (SEANOE, CC BY 4.0), functional traits of
#'   marine protists. Traits are genus-level; numeric cell size is aggregated by
#'   median, categorical traits by mode.
#'
#' @references
#' Ramond P, Siano R, Sourisseau M (2018) Functional traits of marine protists.
#' SEANOE. \doi{10.17882/51662}
#'
#' @examples
#' \dontrun{
#' taxify("Alexandrium", backbone = "gbif") |>
#'   add_ramond()
#' }
#'
#' @export
add_ramond <- function(x, cols = NULL, verbose = TRUE) {
  cat_cols <- c(
    ramond_shape      = "shape",
    ramond_motility   = "motility",
    ramond_ingestion  = "ingestion",
    ramond_symbiontic = "symbiontic",
    ramond_colony     = "colony",
    ramond_salinity   = "salinity"
  )
  num_cols <- c(
    ramond_chloroplast = "chloroplast",
    ramond_size_min_um = "size_min_um",
    ramond_size_max_um = "size_max_um"
  )
  col_map  <- c(cat_cols, num_cols)
  enrich_simple(
    x,
    enrichment_name = "ramond",
    col_map         = col_map,
    source_label    = "Ramond marine protist traits",
    join_col        = "genus",
    cols            = cols,
    verbose         = verbose
  )
}

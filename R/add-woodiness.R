#' Add woodiness classification
#'
#' Joins woodiness data from Zanne et al. (2014) to a [taxify()] result
#' by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with an additional column:
#' \describe{
#'   \item{woodiness}{One of `"woody"`, `"herbaceous"`, `"variable"`,
#'     or `NA` if not in the dataset.}
#' }
#'
#' @details
#' Source: Zanne et al. 2014, Nature (Dryad, CC0). Coverage: ~50k plant
#' species. Plants only.
#'
#' @references
#' Zanne AE et al. (2014) Three keys to the radiation of angiosperms into
#' freezing environments. Nature 506:89-92.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur") |>
#'   add_woodiness()
#'
#' options(old)
#'
#' @export
add_woodiness <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "woodiness",
    col_map         = c(woodiness = "woodiness"),
    source_label    = "Zanne et al. 2014",
    verbose         = verbose
  )
}

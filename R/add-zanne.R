#' Add woodiness (Zanne et al. 2014)
#'
#' Joins the woody / herbaceous classification of Zanne et al. (2014) to a
#' [taxify()] result by looking up `accepted_name`. This is the source-named
#' door for the Zanne Global Woodiness Database; for woodiness reconciled across
#' every source that carries it (Zanne, GIFT), use [add_trait()] with
#' `"woodiness"`.
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
#' @seealso [add_trait()] for woodiness harmonized across sources.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur") |>
#'   add_zanne()
#'
#' options(old)
#'
#' @export
add_zanne <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "woodiness",
    col_map         = c(woodiness = "woodiness"),
    source_label    = "Zanne et al. 2014",
    verbose         = verbose
  )
}

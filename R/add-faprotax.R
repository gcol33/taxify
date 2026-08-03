#' Add prokaryote metabolic and ecological functions (FAPROTAX)
#'
#' Joins the function groups a prokaryotic taxon is known to perform --
#' methanogenesis, denitrification, nitrogen fixation, chitinolysis, human gut
#' association and 87 others -- to a [taxify()] result.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) both, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `faprotax_functions` (a `|`-delimited set)
#'   and `faprotax_n_functions`.
#'
#' @details Source: Louca et al. (2016), 92 function groups over 4470 taxa
#'   compiled from IJSEM and Bergey's Manual. Redistributed under FAPROTAX's own
#'   BSD-style terms; see \code{\link{cite}} for the notice that must travel
#'   with it.
#'
#'   FAPROTAX annotates a taxon at whatever rank the evidence supports, so its
#'   entries are a mix of species and genera. The join follows: a species-level
#'   entry matches the accepted name, and a taxon with no entry of its own
#'   inherits its genus's. Group memberships are the source's; taxifydb reshapes
#'   the grouped list into one row per taxon and reduces each entry to the
#'   species or genus it names, which the licence requires be stated as a
#'   modification.
#'
#'   Functions stay a set rather than one label because a prokaryote genuinely
#'   performs several: *Escherichia coli* carries 17 of them.
#'
#' @references
#' Louca S, Parfrey LW, Doebeli M (2016) Decoupling function and taxonomy in the
#' global ocean microbiome. Science 353:1272-1277. \doi{10.1126/science.aaf4507}
#'
#' @examples
#' \dontrun{
#' taxify(c("Escherichia coli", "Nitrosomonas europaea")) |>
#'   add_faprotax()
#' }
#'
#' @export
add_faprotax <- function(x, cols = NULL, verbose = TRUE) {
  all_cols <- c("faprotax_functions", "faprotax_n_functions")
  col_map <- stats::setNames(all_cols, all_cols)
  enrich_simple(
    x,
    enrichment_name = "faprotax",
    col_map         = col_map,
    source_label    = "FAPROTAX prokaryote functions (Louca et al.)",
    cols            = cols,
    genus_fallback  = TRUE,
    verbose         = verbose
  )
}

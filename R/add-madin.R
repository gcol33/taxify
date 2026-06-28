#' Add bacterial and archaeal traits (Madin et al.)
#'
#' Joins species-level bacterial and archaeal phenotypic and genome traits to a
#' [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{madin_gram_stain}{Gram stain (positive/negative).}
#'   \item{madin_metabolism}{Metabolism (aerobic/anaerobic/facultative/...).}
#'   \item{madin_cell_shape}{Cell shape (bacillus/coccus/spiral/...).}
#'   \item{madin_motility}{Motility (yes/no/flagella/gliding/...).}
#'   \item{madin_sporulation}{Sporulation (yes/no).}
#'   \item{madin_isolation_source}{Isolation source category.}
#'   \item{madin_growth_temp_c}{Recorded growth temperature (degrees Celsius).}
#'   \item{madin_optimum_temp_c}{Optimum growth temperature (degrees Celsius).}
#'   \item{madin_optimum_ph}{Optimum growth pH.}
#'   \item{madin_genome_size_bp}{Genome size (base pairs).}
#'   \item{madin_gc_content_pct}{Genomic G+C content (percent).}
#' }
#'
#' @details
#' Source: Madin et al. (2020, Scientific Data, CC BY 4.0).
#' Coverage: ~14.9k bacterial and archaeal species.
#'
#' @references
#' Madin JS et al. (2020) A synthesis of bacterial and archaeal phenotypic
#' trait data. Scientific Data 7:170. \doi{10.1038/s41597-020-0497-4}
#'
#' @examples
#' \donttest{
#' taxify("Escherichia coli", backend = "gbif") |>
#'   add_madin()
#' }
#'
#' @export
add_madin <- function(x, verbose = TRUE) {
  col_map <- c(
    madin_gram_stain       = "gram_stain",
    madin_metabolism       = "metabolism",
    madin_cell_shape       = "cell_shape",
    madin_motility         = "motility",
    madin_sporulation      = "sporulation",
    madin_isolation_source = "isolation_source",
    madin_growth_temp_c    = "growth_temp_c",
    madin_optimum_temp_c   = "optimum_temp_c",
    madin_optimum_ph       = "optimum_ph",
    madin_genome_size_bp   = "genome_size_bp",
    madin_gc_content_pct   = "gc_content_pct"
  )
  na_types <- stats::setNames(
    rep(list(NA_character_), length(col_map)), names(col_map)
  )
  na_types[c("madin_growth_temp_c", "madin_optimum_temp_c", "madin_optimum_ph",
             "madin_genome_size_bp", "madin_gc_content_pct")] <-
    list(NA_real_)
  enrich_simple(
    x,
    enrichment_name = "madin",
    col_map         = col_map,
    source_label    = "Madin bacteria/archaea traits",
    na_types        = na_types,
    verbose         = verbose
  )
}

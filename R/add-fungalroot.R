# Trait columns served by the fungalroot enrichment .vtr. The .vtr column names
# are identical to the output column names, so the enrich_simple() col_map is
# the identity map over this vector (single source of truth).
.fungalroot_cols <- c(
  "mycorrhizal_type", "mycorrhizal_status", "mycorrhizal_records"
)


#' Add mycorrhizal type from FungalRoot
#'
#' Joins genus-level mycorrhizal type from the FungalRoot database
#' (Soudzilovskaia et al. 2020) to a [taxify()] result by looking up `genus`.
#' Mycorrhizal type is phylogenetically conserved at the genus level, which is
#' the resolution FungalRoot recommends for inference, so this enrichment joins
#' on `genus` rather than `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with three additional columns:
#' \describe{
#'   \item{mycorrhizal_type}{Genus-level majority-consensus type, one of `AM`
#'     (arbuscular), `EcM` (ecto), `ErM` (ericoid), `OM` (orchid), `NM`
#'     (non-mycorrhizal), the dual types `EcM-AM` / `ErM-EcM` / `ErM-AM`,
#'     `Other`, or `uncertain`. `NA` if the genus is not in FungalRoot.}
#'   \item{mycorrhizal_status}{Coarse status derived from the type:
#'     `"mycorrhizal"`, `"non-mycorrhizal"`, or `"uncertain"`.}
#'   \item{mycorrhizal_records}{Number of FungalRoot observations supporting the
#'     genus-level consensus.}
#' }
#'
#' @details
#' Source: FungalRoot, published on GBIF as a Darwin Core Archive
#' (\doi{10.15468/a7ujmj}), CC BY-NC 4.0. The per-genus value is a majority
#' consensus computed from the per-observation mycorrhiza type labels, not
#' FungalRoot's own published per-genus assignment. Plant genera only. The
#' `.vtr` is downloaded from the taxify release on first use and cached.
#'
#' @references
#' Soudzilovskaia NA et al. (2020) FungalRoot: global online database of plant
#' mycorrhizal associations. New Phytologist 227:955-966.
#'
#' @examples
#' \donttest{
#' # Joins on genus, so any species in a covered genus is annotated.
#' taxify(c("Quercus robur", "Trifolium pratense")) |>
#'   add_fungalroot()
#' }
#'
#' @export
add_fungalroot <- function(x, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "fungalroot",
    col_map         = stats::setNames(.fungalroot_cols, .fungalroot_cols),
    source_label    = "FungalRoot (Soudzilovskaia et al. 2020)",
    na_types        = list(mycorrhizal_records = NA_integer_),
    join_col        = "genus",
    verbose         = verbose
  )
}

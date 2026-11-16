#' Add root-nodule nitrogen fixation (NodDB)
#'
#' Joins the nodulation status of a plant genus to a [taxify()] result. NodDB
#' records nodulation per genus, so the join is on `genus`, the same grain as
#' [add_fungalroot()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) all, or a
#'   character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `noddb_` columns: `noddb_nodulation_consensus`,
#'   `noddb_nodulation_type`, `noddb_nodulation_clade`, `noddb_nodulation_family`,
#'   `noddb_spp_recognized`, `noddb_spp_studied`, `noddb_positive_reports`, `noddb_negative_reports`.
#'
#' @details Source: Tedersoo et al. (2018), 824 plant genera. CC BY-SA 4.0.
#'
#'   `nodulation_consensus` is the authors' verdict verbatim, which distinguishes
#'   a confirmed record from a phylogenetic inference (`Rhizobia` against
#'   `likely_Rhizobia`) and carries their negative calls as `unlikely_Rhizobia`
#'   and `unlikely_Frankia`. `nodulation_type` collapses that to the symbiont
#'   involved (`rhizobia`, `frankia`, `nostocaceae`, `present`, `none`)
#'   reading both `unlikely_` verdicts as `none`.
#'
#'   `positive_reports` and `negative_reports` are the counts of published
#'   observations behind the verdict, so a thinly evidenced call is visible.
#'
#' @references
#' Tedersoo L, Laanisto L, Rahimlou S, Toussaint A, Hallikma T, Partel M (2018)
#' Global database of plants with root-symbiotic nitrogen fixation: NodDB.
#' Journal of Vegetation Science 29:560-568. \doi{10.1111/jvs.12627}
#'
#' Data: \doi{10.15156/BIO/587469}
#'
#' @examples
#' \dontrun{
#' taxify(c("Pisum sativum", "Alnus glutinosa", "Quercus robur")) |>
#'   add_noddb()
#' }
#'
#' @export
add_noddb <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_noddb, cols = cols, verbose = verbose)
}


.door_noddb <- list(
  enrichment_name = "noddb",
  col_map = c(
    noddb_nodulation_consensus = "nodulation_consensus",
    noddb_nodulation_type = "nodulation_type",
    noddb_nodulation_clade = "nodulation_clade",
    noddb_nodulation_family = "nodulation_family",
    noddb_spp_recognized = "spp_recognized",
    noddb_spp_studied = "spp_studied",
    noddb_positive_reports = "positive_reports",
    noddb_negative_reports = "negative_reports"
  ),
  source_label = "NodDB root-nodule nitrogen fixation (Tedersoo et al.)",
  join_col = "genus"
)

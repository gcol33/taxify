#' Add seed traits from the Kew Seed Information Database (SER-SID)
#'
#' Joins species-level seed traits from the Kew Seed Information Database
#' (SER-SID) to a [taxify()] result by looking up `accepted_name`.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set, \code{"all"} every column the source carries, or a character vector of names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns. The curated set:
#' \describe{
#'   \item{kew_sid_sid_thousand_seed_weight}{Thousand-seed weight (grams per 1000 seeds,
#'     median of all records).}
#'   \item{kew_sid_sid_storage_behaviour}{Seed storage behaviour
#'     (Orthodox/Recalcitrant/Intermediate/Uncertain).}
#'   \item{kew_sid_sid_oil_content_pct}{Seed oil content (percent, median).}
#'   \item{kew_sid_sid_protein_content_pct}{Seed protein content (percent, median).}
#'   \item{kew_sid_sid_lifeform}{Raunkiaer life-form code as recorded by SID.}
#' }
#' With `cols = "all"` the seed-weight record count (`n_seed_weight_records`)
#' and modal `fruit_type` are also attached under their source names. Joined on
#' `accepted_name`.
#'
#' @details Source: Royal Botanic Gardens Kew, Seed Information Database, served
#'   as SER-SID (\url{https://ser-sid.org/}), CC BY 2.0. Per-record measurements
#'   are reduced to per-species medians (numeric) and modes (categorical); a
#'   thousand-seed weight in grams equals the per-seed mass in milligrams.
#'
#' @references
#' Royal Botanic Gardens Kew. Seed Information Database (SID).
#' \url{https://ser-sid.org/}
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur", backbone = "gbif") |>
#'   add_kew_sid()
#'
#' options(old)
#'
#' @export
add_kew_sid <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_kew_sid, cols = cols, verbose = verbose)
}


.door_kew_sid <- list(
  enrichment_name = "kew_sid",
  col_map = c(
    sid_thousand_seed_weight = "thousand_seed_weight",
    sid_oil_content_pct = "oil_content_pct",
    sid_protein_content_pct = "protein_content_pct",
    sid_storage_behaviour = "storage_behaviour",
    sid_lifeform = "lifeform"
  ),
  source_label = "Kew Seed Information Database (SID)"
)

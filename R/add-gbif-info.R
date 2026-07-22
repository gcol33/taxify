#' Add GBIF-specific columns
#'
#' Joins extra GBIF backbone columns to a [taxify()] result by
#' looking up `taxon_id` in the GBIF backbone. Only enriches rows where
#' `backend == "gbif"`.
#'
#' @param x A data.frame returned by [taxify()] with `backend == "gbif"`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{notho_type}{Hybrid type: `"GENERIC"`, `"SPECIFIC"`, or
#'     `"INFRASPECIFIC"`.}
#'   \item{nom_status}{Nomenclatural status (may contain multiple values).}
#'   \item{bracket_authorship}{Basionym author in parentheses.}
#'   \item{bracket_year}{Basionym author year.}
#'   \item{gbif_year}{Combining author year.}
#'   \item{name_published_in}{Publication citation.}
#'   \item{origin}{How the name entered the backbone.}
#'   \item{infra_specific_epithet}{Infraspecific epithet.}
#' }
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur", backend = "gbif") |>
#'   add_gbif_info()
#'
#' options(old)
#'
#' @export
add_gbif_info <- function(x) {
  # Output column (user-facing) -> source column in the .vtr. taxon_id is the
  # unified-schema join key; infra_specific_epithet (the user-facing name, with
  # separator) comes from infraspecific_epithet (the unified main-schema name,
  # without separator).
  col_map <- c(
    notho_type             = "notho_type",
    nom_status             = "nom_status",
    bracket_authorship     = "bracket_authorship",
    bracket_year           = "bracket_year",
    gbif_year              = "year",
    name_published_in      = "name_published_in",
    origin                 = "origin",
    infra_specific_epithet = "infraspecific_epithet"
  )
  enrich_from_backbone(
    x, gbif_backend(), col_map,
    enrichment_name = "gbif_info", label = "GBIF",
    probe_cols = c("notho_type", "nom_status", "origin", "name_published_in")
  )
}

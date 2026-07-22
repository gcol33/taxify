#' Add COL-specific columns
#'
#' Joins extra Catalogue of Life columns to a [taxify()] result by
#' looking up `taxon_id` in the COL backbone. Only enriches rows where
#' `backbone == "col"`.
#'
#' @param x A data.frame returned by [taxify()] with `backbone == "col"`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{notho}{Hybrid type from COL: `"generic"`, `"specific"`,
#'     `"infrageneric"`, or `"infraspecific"`.}
#'   \item{nomenclaturalCode}{Nomenclatural code (`"ICN"`, `"ICZN"`, etc.).}
#'   \item{nomenclaturalStatus}{Nomenclatural status.}
#'   \item{namePublishedIn}{Original publication reference.}
#'   \item{kingdom}{Kingdom classification.}
#'   \item{phylum}{Phylum classification.}
#'   \item{col_class}{Class classification (renamed to avoid conflict with
#'     R's `class` function).}
#'   \item{order}{Order classification.}
#'   \item{infraspecificEpithet}{Infraspecific epithet.}
#'   \item{is_extinct}{Logical. Whether the species is extinct (from
#'     SpeciesProfile, if available).}
#'   \item{is_marine}{Logical. Whether the species is marine.}
#'   \item{is_freshwater}{Logical. Whether the species is freshwater.}
#'   \item{is_terrestrial}{Logical. Whether the species is terrestrial.}
#' }
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Quercus robur", backbone = "col") |>
#'   add_col_info()
#'
#' options(old)
#'
#' @export
add_col_info <- function(x) {
  # Output column (user-facing) -> source column in the .vtr. taxon_id is the
  # unified-schema join key; infraspecific_epithet is the unified main-schema
  # name renamed to infraspecificEpithet for stable output.
  col_map <- c(
    notho                = "notho",
    nomenclaturalCode    = "nomenclaturalCode",
    nomenclaturalStatus  = "nomenclaturalStatus",
    namePublishedIn      = "namePublishedIn",
    kingdom              = "kingdom",
    phylum               = "phylum",
    col_class            = "class",
    order                = "order",
    infraspecificEpithet = "infraspecific_epithet"
  )

  # SpeciesProfile sidecar: extinct/marine/freshwater/terrestrial flags, stored
  # as "true"/"false" strings, joined on taxonID and read as logicals.
  extra_vtr <- list(
    suffix  = "_species_profile.vtr",
    key     = "taxonID",
    col_map = c(
      is_extinct     = "isExtinct",
      is_marine      = "isMarine",
      is_freshwater  = "isFreshwater",
      is_terrestrial = "isTerrestrial"
    ),
    na        = NA,
    transform = function(v) tolower(v) == "true"
  )

  enrich_from_backbone(
    x, col_backend(), col_map,
    enrichment_name = "col_info", label = "COL",
    probe_cols = c("notho", "nomenclaturalCode", "kingdom", "is_extinct"),
    extra_vtr = extra_vtr
  )
}

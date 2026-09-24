#' Euro+Med areas and their country codes
#'
#' Lists the areas Euro+Med PlantBase states a taxon's status for, with the
#' ISO 3166-1 alpha-2 country code of the areas that are one country. Areas are
#' not countries: some combine several ("Italy, with San Marino and Vatican
#' City"), some are part of one (a region of European Russia, an island group),
#' and the level-2 areas split a combined area into its countries (`Au(A)`
#' Austria and `Au(L)` Liechtenstein under `Au`). Only an area that is exactly
#' one country carries an `iso2`.
#'
#' @return A data.frame with `area_code`, `area_name`, `area_level` and `iso2`.
#' @seealso [add_euromed_distribution()]
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#' euromed_areas()
#' options(old)
#' @export
euromed_areas <- function() {
  vtr_path <- ensure_enrichment("euromed_distribution", verbose = FALSE)
  if (is.null(vtr_path)) {
    stop(paste0("euromed_areas(): the 'euromed_distribution' enrichment is not ",
                "available. It downloads on first use; check your connection."),
         call. = FALSE)
  }
  areas <- vectra::tbl(vtr_path) |>
    vectra::select(area_code, area_name, area_level, iso2) |>
    vectra::distinct() |>
    vectra::collect()
  areas <- areas[order(areas$area_code), , drop = FALSE]
  rownames(areas) <- NULL
  areas
}


#' Add Euro+Med PlantBase distribution status
#'
#' Joins the per-area status Euro+Med PlantBase states for a taxon (native,
#' naturalised, introduced, casual, ...) to a [taxify()] result, for the areas
#' or countries asked for. The names and the ids of the `euromed` backbone are
#' the same taxa the status is recorded on, so a result matched against any
#' backbone joins through its accepted name.
#'
#' @param x A data.frame returned by [taxify()].
#' @param region Character. ISO 3166-1 alpha-2 country code(s), Euro+Med area
#'   code(s), or `"all"`. A code that is an ISO code of a Euro+Med area is read
#'   as the country; anything else must be an area code, as listed by
#'   [euromed_areas()].
#'   \itemize{
#'     \item Single region: adds `euromed_status` (no suffix).
#'     \item Several regions: adds `euromed_status_<code>` per region.
#'     \item `"all"`: one column per area.
#'   }
#' @param cols Which columns to attach. `NULL` (the default) attaches
#'   `euromed_status`; a character vector attaches just those, and `"all"`
#'   attaches every column the source carries (see [enrichment_cols()]), among
#'   them `euromed_status_detail`, `euromed_status_source`, `area_name`,
#'   `iso2` and the taxon's Euro+Med UUID, `taxon_id`.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with `euromed_status`, one of `"native"`,
#'   `"naturalised"`, `"introduced"`, `"casual"`, `"cultivated"`,
#'   `"doubtful"` or `"extinct"`, and `NA` where Euro+Med states nothing for the
#'   region. `euromed_status_detail` carries the term as Euro+Med words it
#'   (`"endemic"`, `"introduced: uncertain degree of naturalisation"`).
#'   `euromed_status_source` holds the ids of the citing references; resolve
#'   them with `cite(x$euromed_status_source, source = "euromed_distribution")`.
#'
#' @details
#' Source: Euro+Med PlantBase (CC BY-SA), European and Mediterranean vascular
#' plants, bryophytes and some fungi and algae. A report Euro+Med marks as made
#' in error is not carried; a former presence is `"extinct"`. Where the records
#' of one taxon and area disagree, the stronger claim wins in the order given
#' above (a taxon is native wherever a record says so), and the references are
#' those of the records stating it. The country of an area comes from its own
#' name, so a combined area has none and its countries are read from the
#' level-2 areas.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Solidago canadensis") |>
#'   add_euromed_distribution(region = "DE")
#'
#' options(old)
#'
#' @seealso [euromed_areas()], [add_wcvp()]
#' @export
add_euromed_distribution <- function(x, region, cols = NULL, verbose = TRUE) {
  if (missing(region)) {
    stop("'region' is required. Use an ISO 3166-1 alpha-2 code (e.g., \"DE\"), ",
         "a Euro+Med area code (see euromed_areas()) or \"all\".", call. = FALSE)
  }
  enrich_by_group(
    x,
    enrichment_name = "euromed_distribution",
    group_col       = "area_code",
    groups          = .euromed_resolve_regions(region),
    value_cols      = c(euromed_status = "euromed_status"),
    source_label    = "Euro+Med PlantBase",
    cols            = cols,
    prefer          = list(
      col   = "euromed_status",
      order = c("native", "naturalised", "introduced", "casual", "cultivated",
                "doubtful", "extinct")),
    verbose         = verbose
  )
}


# Region arguments to Euro+Med area codes: an ISO code of an area is read as
# that country's area(s), anything else must be an area code itself.
.euromed_resolve_regions <- function(region) {
  if (length(region) == 1L && !anyNA(region) && region == "all") return(region)
  areas <- euromed_areas()
  out <- character(0L)
  for (r in region) {
    codes <- areas$area_code[!is.na(areas$iso2) & areas$iso2 == r]
    if (!length(codes)) {
      if (!r %in% areas$area_code) {
        stop(sprintf(paste0(
          "'%s' is neither an ISO code of a Euro+Med area nor an area code. ",
          "See euromed_areas()."), r), call. = FALSE)
      }
      codes <- r
    }
    out <- c(out, codes)
  }
  unique(out)
}

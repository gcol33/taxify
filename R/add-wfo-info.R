#' Add WFO-specific columns
#'
#' Joins extra World Flora Online columns to a [taxify()] result by
#' looking up `taxon_id` in the WFO backbone.
#'
#' @param x A data.frame returned by [taxify()] with `backend == "wfo"`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{scientificNameID}{WFO scientificNameID.}
#'   \item{parentNameUsageID}{WFO parentNameUsageID.}
#'   \item{namePublishedIn}{Publication reference.}
#'   \item{higherClassification}{Higher classification string.}
#'   \item{taxonRemarks}{Taxonomic remarks.}
#'   \item{infraspecificEpithet}{Infraspecific epithet (for subspecies,
#'     varieties, forms).}
#' }
#'
#' @examples
#' \dontrun{
#' taxify("Quercus robur") |>
#'   add_wfo_info()
#' }
#'
#' @export
add_wfo_info <- function(x) {
  if (!"taxon_id" %in% names(x)) {
    stop("x must be a data.frame with a 'taxon_id' column (from taxify())",
         call. = FALSE)
  }

  # Get WFO backbone path
  be <- wfo_backend()
  bb_path <- get_backbone_path(be$name)
  if (is.null(bb_path)) {
    bb_path <- tryCatch(taxify_load(be), error = function(e) NULL)
  }
  if (is.null(bb_path) || !file.exists(bb_path)) {
    stop("WFO backbone not found. Run taxify_download('wfo') first.",
         call. = FALSE)
  }

  # Get IDs that need enrichment (WFO rows only)
  wfo_rows <- which(!is.na(x$taxon_id) &
                    (!is.na(x$backend) & x$backend == "wfo"))
  if (length(wfo_rows) == 0L) {
    x$scientificNameID <- NA_character_
    x$parentNameUsageID <- NA_character_
    x$namePublishedIn <- NA_character_
    x$higherClassification <- NA_character_
    x$taxonRemarks <- NA_character_
    x$infraspecificEpithet <- NA_character_
    bb_meta <- read_backbone_meta(bb_path)
    ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
    return(register_enrichment(x, "wfo_info", "WFO", ver, 0L))
  }

  ids <- unique(x$taxon_id[wfo_rows])
  id_df <- data.frame(lookup_id = ids, stringsAsFactors = FALSE)
  tmp_ids <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_ids), add = TRUE)
  vectra::write_vtr(id_df, tmp_ids)

  # Join against the full backbone for extra columns
  extra_cols <- c("taxonID", "scientificNameID", "parentNameUsageID",
                  "namePublishedIn", "higherClassification", "taxonRemarks",
                  "infraspecificEpithet")

  # Get available columns from backbone
  bb_schema <- vectra::tbl(bb_path) |> utils::head(1L) |> vectra::collect()
  available <- intersect(extra_cols, names(bb_schema))

  if (length(available) <= 1L) {
    x$scientificNameID <- NA_character_
    x$parentNameUsageID <- NA_character_
    x$namePublishedIn <- NA_character_
    x$higherClassification <- NA_character_
    x$taxonRemarks <- NA_character_
    x$infraspecificEpithet <- NA_character_
    bb_meta <- read_backbone_meta(bb_path)
    ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
    return(register_enrichment(x, "wfo_info", "WFO", ver, 0L))
  }

  # Build select expression dynamically
  extra_info <- vectra::inner_join(
    vectra::tbl(tmp_ids),
    vectra::tbl(bb_path) |>
      vectra::select(!!!lapply(available, as.name)),
    by = c("lookup_id" = "taxonID")
  ) |> vectra::collect()

  # Build lookup
  extra_lookup <- split(extra_info, extra_info$lookup_id)

  # Initialize new columns
  new_cols <- setdiff(extra_cols, "taxonID")
  for (col in new_cols) {
    x[[col]] <- NA_character_
  }

  # Fill in
  for (i in wfo_rows) {
    info <- extra_lookup[[x$taxon_id[i]]]
    if (!is.null(info) && nrow(info) > 0L) {
      for (col in new_cols) {
        if (col %in% names(info)) {
          x[[col]][i] <- info[[col]][1L]
        }
      }
    }
  }

  bb_meta <- read_backbone_meta(bb_path)
  ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
  n_enriched <- sum(!is.na(x$scientificNameID) | !is.na(x$namePublishedIn) |
                    !is.na(x$higherClassification))
  register_enrichment(x, "wfo_info", "WFO", ver, n_enriched)
}

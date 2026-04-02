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
#' \dontrun{
#' taxify("Quercus robur", backend = "gbif") |>
#'   add_gbif_info()
#' }
#'
#' @export
add_gbif_info <- function(x) {
  if (!"taxon_id" %in% names(x)) {
    stop("x must be a data.frame with a 'taxon_id' column (from taxify())",
         call. = FALSE)
  }

  be <- gbif_backend()
  bb_path <- get_backbone_path(be$name)
  if (is.null(bb_path)) {
    bb_path <- tryCatch(taxify_load(be), error = function(e) NULL)
  }
  if (is.null(bb_path) || !file.exists(bb_path)) {
    stop("GBIF backbone not found. Run taxify_download('gbif') first.",
         call. = FALSE)
  }

  # Only enrich GBIF rows
  gbif_rows <- which(!is.na(x$taxon_id) &
                     (!is.na(x$backend) & x$backend == "gbif"))

  # Initialize new columns
  x$notho_type <- NA_character_
  x$nom_status <- NA_character_
  x$bracket_authorship <- NA_character_
  x$bracket_year <- NA_character_
  x$gbif_year <- NA_character_
  x$name_published_in <- NA_character_
  x$origin <- NA_character_
  x$infra_specific_epithet <- NA_character_

  if (length(gbif_rows) == 0L) return(x)

  ids <- unique(x$taxon_id[gbif_rows])
  id_df <- data.frame(lookup_id = ids, stringsAsFactors = FALSE)
  tmp_ids <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_ids), add = TRUE)
  vectra::write_vtr(id_df, tmp_ids)

  # Check which extra columns are available
  bb_schema <- vectra::tbl(bb_path) |> utils::head(1L) |> vectra::collect()
  want_cols <- c("id", "notho_type", "nom_status", "bracket_authorship",
                 "bracket_year", "year", "name_published_in", "origin",
                 "infra_specific_epithet")
  available <- intersect(want_cols, names(bb_schema))

  if (length(available) <= 1L) return(x)

  extra_info <- vectra::inner_join(
    vectra::tbl(tmp_ids),
    vectra::tbl(bb_path) |>
      vectra::select(!!!lapply(available, as.name)),
    by = c("lookup_id" = "id")
  ) |> vectra::collect()

  if (nrow(extra_info) == 0L) return(x)

  extra_lookup <- split(extra_info, extra_info$lookup_id)

  # Map output column -> source column
  col_map <- c(
    notho_type = "notho_type",
    nom_status = "nom_status",
    bracket_authorship = "bracket_authorship",
    bracket_year = "bracket_year",
    gbif_year = "year",
    name_published_in = "name_published_in",
    origin = "origin",
    infra_specific_epithet = "infra_specific_epithet"
  )

  for (i in gbif_rows) {
    info <- extra_lookup[[x$taxon_id[i]]]
    if (!is.null(info) && nrow(info) > 0L) {
      for (out_col in names(col_map)) {
        src_col <- col_map[[out_col]]
        if (src_col %in% names(info)) {
          x[[out_col]][i] <- info[[src_col]][1L]
        }
      }
    }
  }

  x
}

#' Add COL-specific columns
#'
#' Joins extra Catalogue of Life columns to a [taxify()] result by
#' looking up `taxon_id` in the COL backbone. Only enriches rows where
#' `backend == "col"`.
#'
#' @param x A data.frame returned by [taxify()] with `backend == "col"`.
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
#' \dontrun{
#' taxify("Quercus robur", backend = "col") |>
#'   add_col_info()
#' }
#'
#' @export
add_col_info <- function(x) {
  if (!"taxon_id" %in% names(x)) {
    stop("x must be a data.frame with a 'taxon_id' column (from taxify())",
         call. = FALSE)
  }

  be <- col_backend()
  bb_path <- get_backbone_path(be$name)
  if (is.null(bb_path)) {
    bb_path <- tryCatch(taxify_load(be), error = function(e) NULL)
  }
  if (is.null(bb_path) || !file.exists(bb_path)) {
    stop("COL backbone not found. Run taxify_download('col') first.",
         call. = FALSE)
  }

  # Only enrich COL rows
  col_rows <- which(!is.na(x$taxon_id) &
                    (!is.na(x$backend) & x$backend == "col"))

  # Initialize new columns
  x$notho <- NA_character_
  x$nomenclaturalCode <- NA_character_
  x$nomenclaturalStatus <- NA_character_
  x$namePublishedIn <- NA_character_
  x$kingdom <- NA_character_
  x$phylum <- NA_character_
  x$col_class <- NA_character_
  x$order <- NA_character_
  x$infraspecificEpithet <- NA_character_
  x$is_extinct <- NA
  x$is_marine <- NA
  x$is_freshwater <- NA
  x$is_terrestrial <- NA

  if (length(col_rows) == 0L) {
    bb_meta <- read_backbone_meta(bb_path)
    ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
    return(register_enrichment(x, "col_info", "COL", ver, 0L))
  }

  # Join extra columns from main backbone
  ids <- unique(x$taxon_id[col_rows])
  id_df <- data.frame(lookup_id = ids, stringsAsFactors = FALSE)
  tmp_ids <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp_ids), add = TRUE)
  vectra::write_vtr(id_df, tmp_ids)

  # Check which extra columns are available
  bb_schema <- vectra::tbl(bb_path) |> utils::head(1L) |> vectra::collect()
  want_cols <- c("taxonID", "notho", "nomenclaturalCode", "nomenclaturalStatus",
                 "namePublishedIn", "kingdom", "phylum", "class", "order",
                 "infraspecificEpithet")
  available <- intersect(want_cols, names(bb_schema))

  if (length(available) > 1L) {
    extra_info <- vectra::inner_join(
      vectra::tbl(tmp_ids),
      vectra::tbl(bb_path) |>
        vectra::select(!!!lapply(available, as.name)),
      by = c("lookup_id" = "taxonID")
    ) |> vectra::collect()

    extra_lookup <- split(extra_info, extra_info$lookup_id)

    col_map <- c(
      notho = "notho",
      nomenclaturalCode = "nomenclaturalCode",
      nomenclaturalStatus = "nomenclaturalStatus",
      namePublishedIn = "namePublishedIn",
      kingdom = "kingdom",
      phylum = "phylum",
      col_class = "class",
      order = "order",
      infraspecificEpithet = "infraspecificEpithet"
    )

    for (i in col_rows) {
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
  }

  # Join SpeciesProfile for extinct/marine/freshwater/terrestrial
  sp_vtr <- sub("\\.vtr$", "_species_profile.vtr", bb_path)
  if (file.exists(sp_vtr)) {
    sp_info <- tryCatch({
      vectra::inner_join(
        vectra::tbl(tmp_ids),
        vectra::tbl(sp_vtr),
        by = c("lookup_id" = "taxonID")
      ) |> vectra::collect()
    }, error = function(e) data.frame())

    if (nrow(sp_info) > 0L) {
      sp_lookup <- split(sp_info, sp_info$lookup_id)
      bool_map <- c(
        is_extinct = "isExtinct",
        is_marine = "isMarine",
        is_freshwater = "isFreshwater",
        is_terrestrial = "isTerrestrial"
      )

      for (i in col_rows) {
        info <- sp_lookup[[x$taxon_id[i]]]
        if (!is.null(info) && nrow(info) > 0L) {
          for (out_col in names(bool_map)) {
            src_col <- bool_map[[out_col]]
            if (src_col %in% names(info)) {
              val <- info[[src_col]][1L]
              x[[out_col]][i] <- if (!is.na(val)) tolower(val) == "true" else NA
            }
          }
        }
      }
    }
  }

  bb_meta <- read_backbone_meta(bb_path)
  ver <- if (!is.null(bb_meta)) bb_meta$version else be$version
  n_enriched <- sum(!is.na(x$notho) | !is.na(x$nomenclaturalCode) |
                    !is.na(x$kingdom) | !is.na(x$is_extinct))
  register_enrichment(x, "col_info", "COL", ver, n_enriched)
}

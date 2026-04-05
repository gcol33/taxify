# ---- Local enrichment .vtr builder ----
#
# Port of build_enrichment_vtr() from taxify-backbones into taxify itself,
# so users can build enrichment .vtr files locally from their own data.


#' Build an enrichment .vtr file from a data.frame
#'
#' Sorts by `canonical_name`, drops NA names, writes a `.vtr` file with
#' hash indexes, and creates a `meta.json` sidecar with provenance info.
#'
#' @param df A data.frame with at least a `canonical_name` column plus
#'   one or more trait/status columns.
#' @param vtr_path Character. Output path for the `.vtr` file.
#' @param name Character. Enrichment identifier (e.g., `"woodiness"`).
#' @param version Character. Version string (e.g., `"2026.04"`).
#' @param source_url Character. URL the source data was downloaded from.
#' @param source_doi Character or `NULL`. DOI of the source dataset.
#' @param license Character. License string (e.g., `"CC0"`, `"CC BY 4.0"`).
#' @param attribution Character or `NULL`. Human-readable attribution string.
#' @param group_col Character or `NULL`. Optional column to index for
#'   group-based enrichments (e.g., `"country_code"`, `"lang"`).
#' @param name_col Character. The primary name column used for sorting,
#'   deduplication, and indexing. Default `"canonical_name"` for species-level
#'   enrichments. Use `"genus"` for genus-level enrichments.
#' @return The `vtr_path` (invisibly).
#' @noRd
build_local_enrichment_vtr <- function(df, vtr_path, name, version,
                                       source_url, source_doi = NULL,
                                       license = "unknown",
                                       attribution = NULL,
                                       group_col = NULL,
                                       name_col = "canonical_name") {
  # -- Validate --
  if (!is.data.frame(df)) {
    stop(sprintf("df must be a data.frame, got %s", class(df)[1]))
  }
  if (!name_col %in% names(df)) {
    stop(sprintf("df must have a '%s' column.", name_col))
  }

  # -- Sort and clean --
  df <- df[!is.na(df[[name_col]]), ]
  df <- df[order(df[[name_col]]), ]
  rownames(df) <- NULL

  if (nrow(df) == 0L) {
    stop(sprintf("No rows remaining after dropping NA %s values.", name_col))
  }


  # -- Write .vtr --
  dir.create(dirname(vtr_path), recursive = TRUE, showWarnings = FALSE)
  vectra::write_vtr(df, vtr_path, batch_size = 50000L)

  # -- Create hash indexes --
  vectra::create_index(vtr_path, name_col)
  if (!is.null(group_col) && group_col %in% names(df)) {
    vectra::create_index(vtr_path, group_col)
  }

  # -- Extract available groups --
  available_groups <- NULL
  if (!is.null(group_col) && group_col %in% names(df)) {
    available_groups <- sort(unique(df[[group_col]]))
    available_groups <- available_groups[!is.na(available_groups)]
  }

  # -- Write meta.json sidecar --
  meta <- list(
    type             = "enrichment",
    name             = name,
    version          = version,
    source_version   = version,
    source_url       = source_url,
    source_doi       = source_doi,
    license          = license,
    attribution      = attribution,
    group_col        = group_col,
    available_groups = available_groups,
    built_at         = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    built_locally    = TRUE,
    vtr_current      = TRUE,
    nrow             = nrow(df)
  )

  meta_path <- file.path(dirname(vtr_path), "meta.json")
  jsonlite::write_json(meta, meta_path, pretty = TRUE, auto_unbox = TRUE,
                       null = "null")

  message(sprintf(
    "[enrichment/%s] Built %s: %s rows, %.1f MB",
    name, basename(vtr_path), format(nrow(df), big.mark = ","),
    file.size(vtr_path) / 1048576
  ))

  invisible(vtr_path)
}

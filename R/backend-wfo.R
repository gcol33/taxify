# ---- WFO (World Flora Online) backend ----
#
# Runtime matching against pre-built WFO `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_wfo()` (sibling package).

# WFO version pin (referenced by the constructor; updated with package releases)
.wfo_version <- "2024-12"

# Column map for shared matching engine. Main matching columns come from the
# unified snake_case schema produced by taxifydb::normalize_backbone(); WFO-
# specific extras (scientificNameID, parentNameUsageID, ...) are preserved
# verbatim by .wfo_extra_cols in the build and consumed by add_wfo_info().
.wfo_col_map <- list(
  name       = "canonical_name",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus",
  id         = "taxon_id",
  rank       = "taxon_rank",
  status     = "taxonomic_status",
  acc_id     = "accepted_name_usage_id",
  family     = "family",
  genus_out  = "genus",
  epithet    = "specific_epithet",
  authorship = "authorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a WFO backend object
#'
#' @return A taxify_backend object of class `"taxify_wfo"`.
#' @noRd
wfo_backend <- function() {
  new_backend(
    name = "wfo",
    version = .wfo_version,
    genus_col = "genus",
    col_map = .wfo_col_map,
    prefix_fallback = TRUE,
    class = "taxify_wfo"
  )
}


#' @export
taxify_download.taxify_wfo <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  require_taxifydb("Building the WFO backbone from source")
  output_dir <- dest %||% versioned_dir("wfo", "latest")
  taxifydb::build_wfo(output_dir = output_dir,
                      version = backend$version,
                      verbose = verbose)
}

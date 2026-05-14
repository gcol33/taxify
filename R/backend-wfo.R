# ---- WFO (World Flora Online) backend ----
#
# Runtime matching against pre-built WFO `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_wfo()` (sibling package).

# WFO version pin (referenced by the constructor; updated with package releases)
.wfo_version <- "2024-12"

# Column map for shared matching engine
.wfo_col_map <- list(
  name       = "scientificName",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus",
  id         = "taxonID",
  rank       = "taxonRank",
  status     = "taxonomicStatus",
  acc_id     = "acceptedNameUsageID",
  family     = "family",
  genus_out  = "genus",
  epithet    = "specificEpithet",
  authorship = "scientificNameAuthorship",
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
    unblocked_fallback = TRUE,
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

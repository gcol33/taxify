# ---- COL (Catalogue of Life) backend ----
#
# Runtime matching against pre-built COL `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_col()` (sibling package).

# COL version pin (referenced by the constructor; updated with package releases)
.col_version <- "2025"

# Column map for shared matching engine
.col_col_map <- list(
  name       = "canonicalName",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genericName",
  id         = "taxonID",
  rank       = "taxonRank",
  status     = "taxonomicStatus",
  acc_id     = "acceptedNameUsageID",
  family     = "family",
  genus_out  = "genericName",
  epithet    = "specificEpithet",
  authorship = "scientificNameAuthorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a COL backend object
#'
#' @return A taxify_backend object of class `"taxify_col"`.
#' @noRd
col_backend <- function() {
  new_backend(
    name = "col",
    version = .col_version,
    genus_col = "genericName",
    col_map = .col_col_map,
    unblocked_fallback = TRUE,
    class = "taxify_col"
  )
}


#' @export
taxify_download.taxify_col <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  require_taxifydb("Building the COL backbone from source")
  output_dir <- dest %||% versioned_dir("col", "latest")
  taxifydb::build_col(output_dir = output_dir,
                      version = backend$version,
                      verbose = verbose)
}

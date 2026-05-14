# ---- ITIS (Integrated Taxonomic Information System) backend ----
#
# Runtime matching against pre-built ITIS `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_itis()` (sibling package), which handles the
# SQLite parse + hierarchy walk.

# ITIS version pin (referenced by the constructor; updated with package releases)
.itis_version <- "2025.04"

# Column map for shared matching engine
# These map to the unified backbone schema produced by taxifydb
.itis_col_map <- list(
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


#' Create an ITIS backend object
#'
#' @return A taxify_backend object of class `"taxify_itis"`.
#' @noRd
itis_backend <- function() {
  new_backend(
    name = "itis",
    version = .itis_version,
    genus_col = "genus",
    col_map = .itis_col_map,
    class = "taxify_itis"
  )
}


#' @export
taxify_download.taxify_itis <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  require_taxifydb("Building the ITIS backbone from source")
  output_dir <- dest %||% versioned_dir("itis", "latest")
  taxifydb::build_itis(output_dir = output_dir,
                       version = backend$version,
                       verbose = verbose)
}

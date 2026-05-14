# ---- AlgaeBase backend ----
#
# Runtime matching against pre-built AlgaeBase `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_algaebase()` (sibling package).
#
# AlgaeBase: curated algal taxonomy (~172k names). Authoritative for
# micro/macroalgae, cyanobacteria, and some protists.
#
# NOTE: AlgaeBase is licensed CC BY-NC. This means the backbone data may
# only be used for non-commercial purposes. Academic and research use is fine.

# AlgaeBase version pin (referenced by the constructor; updated with package releases)
.algaebase_version <- "2025.04"

# Column map for shared matching engine
.algaebase_col_map <- list(
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


#' Create an AlgaeBase backend object
#'
#' @return A taxify_backend object of class `"taxify_algaebase"`.
#' @noRd
algaebase_backend <- function() {
  new_backend(
    name = "algaebase",
    version = .algaebase_version,
    genus_col = "genus",
    col_map = .algaebase_col_map,
    class = "taxify_algaebase"
  )
}


#' @export
taxify_download.taxify_algaebase <- function(backend, dest = NULL,
                                             verbose = TRUE, ...) {
  require_taxifydb("Building the AlgaeBase backbone from source")
  output_dir <- dest %||% versioned_dir("algaebase", "latest")
  taxifydb::build_algaebase(output_dir = output_dir,
                            version = backend$version,
                            verbose = verbose)
}

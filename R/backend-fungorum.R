# ---- Species Fungorum Plus backend ----
#
# Runtime matching against pre-built Species Fungorum `.vtr` snapshots.
# Build-from-source delegates to `taxifydb::build_fungorum()` (sibling package).
#
# Species Fungorum Plus: curated checklist with 95% completeness, CC BY license,
# denormalized classification (kingdom through genus), ~329k names.

# Fungorum version pin (referenced by the constructor; updated with package releases)
.fungorum_version <- "2025.04"

# Column map for shared matching engine
.fungorum_col_map <- list(
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


#' Create a Species Fungorum Plus backend object
#'
#' @return A taxify_backend object of class `"taxify_fungorum"`.
#' @noRd
fungorum_backend <- function() {
  new_backend(
    name = "fungorum",
    version = .fungorum_version,
    genus_col = "genus",
    col_map = .fungorum_col_map,
    class = "taxify_fungorum"
  )
}


#' @export
taxify_download.taxify_fungorum <- function(backend, dest = NULL,
                                            verbose = TRUE, ...) {
  require_taxifydb("Building the Species Fungorum backbone from source")
  output_dir <- dest %||% versioned_dir("fungorum", "latest")
  taxifydb::build_fungorum(output_dir = output_dir,
                           version = backend$version,
                           verbose = verbose)
}

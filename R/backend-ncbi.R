# ---- NCBI Taxonomy backend ----
#
# Runtime matching against pre-built NCBI `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_ncbi()` (sibling package).

# NCBI version pin (referenced by the constructor; updated with package releases)
.ncbi_version <- "2025.04"

# Column map for shared matching engine
.ncbi_col_map <- list(
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


#' Create an NCBI Taxonomy backend object
#'
#' @return A taxify_backend object of class `"taxify_ncbi"`.
#' @noRd
ncbi_backend <- function() {
  new_backend(
    name = "ncbi",
    version = .ncbi_version,
    genus_col = "genus",
    col_map = .ncbi_col_map,
    class = "taxify_ncbi"
  )
}


#' @export
taxify_download.taxify_ncbi <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  require_taxifydb("Building the NCBI backbone from source")
  output_dir <- dest %||% versioned_dir("ncbi", "latest")
  taxifydb::build_ncbi(output_dir = output_dir,
                       version = backend$version,
                       verbose = verbose)
}

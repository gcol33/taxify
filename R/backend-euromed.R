# ---- Euro+Med PlantBase backend ----
#
# Runtime matching against pre-built Euro+Med `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_euromed()` (sibling package).
#
# Euro+Med strengths: authoritative for European/Mediterranean flora,
# fine-grained infraspecific taxonomy (subspecies, varieties, forms).
# License: CC-BY-SA-3.0 (applies to derived .vtr data file).

# Euro+Med version pin (referenced by the constructor; updated with package releases)
.euromed_version <- "2020.1"

# Column map for shared matching engine
# These map to the unified backbone schema produced by taxifydb
.euromed_col_map <- list(
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


#' Create a Euro+Med backend object
#'
#' @return A taxify_backend object of class `"taxify_euromed"`.
#' @noRd
euromed_backend <- function() {
  new_backend(
    name = "euromed",
    version = .euromed_version,
    genus_col = "genus",
    col_map = .euromed_col_map,
    class = "taxify_euromed"
  )
}


#' @export
taxify_download.taxify_euromed <- function(backend, dest = NULL,
                                           verbose = TRUE, ...) {
  require_taxifydb("Building the Euro+Med backbone from source")
  output_dir <- dest %||% versioned_dir("euromed", "latest")
  taxifydb::build_euromed(output_dir = output_dir,
                          version = backend$version,
                          verbose = verbose)
}

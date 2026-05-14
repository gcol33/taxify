# ---- WoRMS (World Register of Marine Species) backend ----
#
# Runtime matching against pre-built WoRMS `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_worms()` (sibling package).

# WoRMS version pin (referenced by the constructor; updated with package releases)
.worms_version <- "2025.04"

# Column map for shared matching engine
.worms_col_map <- list(
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


#' Create a WoRMS backend object
#'
#' @return A taxify_backend object of class `"taxify_worms"`.
#' @noRd
worms_backend <- function() {
  new_backend(
    name = "worms",
    version = .worms_version,
    genus_col = "genus",
    col_map = .worms_col_map,
    class = "taxify_worms"
  )
}


#' @export
taxify_download.taxify_worms <- function(backend, dest = NULL,
                                         verbose = TRUE, ...) {
  require_taxifydb("Building the WoRMS backbone from source")
  output_dir <- dest %||% versioned_dir("worms", "latest")
  taxifydb::build_worms(output_dir = output_dir,
                        version = backend$version,
                        verbose = verbose)
}

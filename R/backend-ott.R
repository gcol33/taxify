# ---- Open Tree of Life (OTT) backend ----
#
# Runtime matching against pre-built OTT `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_ott()` (sibling package).

# OTT version pin (referenced by the constructor; updated with package releases)
.ott_version <- "3.7.3"

# Column map for shared matching engine
.ott_col_map <- list(
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


#' Create an OTT backend object
#'
#' @return A taxify_backend object of class `"taxify_ott"`.
#' @noRd
ott_backend <- function() {
  new_backend(
    name = "ott",
    version = .ott_version,
    genus_col = "genus",
    col_map = .ott_col_map,
    class = "taxify_ott"
  )
}


#' @export
taxify_download.taxify_ott <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  require_taxifydb("Building the OTT backbone from source")
  output_dir <- dest %||% versioned_dir("ott", "latest")
  taxifydb::build_ott(output_dir = output_dir,
                      version = backend$version,
                      verbose = verbose)
}

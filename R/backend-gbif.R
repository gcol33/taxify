# ---- GBIF (Global Biodiversity Information Facility) backbone backend ----
#
# Runtime matching against pre-built GBIF `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_gbif()` (sibling package).

# GBIF version pin (referenced by the constructor; updated with package releases)
.gbif_version <- "current"

# Column map for shared matching engine
.gbif_col_map <- list(
  name       = "canonical_name",
  name_ci    = "key_ci",
  name_norm  = "key_normalized",
  name_sp    = "key_species",
  genus      = "genus_or_above",
  id         = "id",
  rank       = "rank",
  status     = "status",
  acc_id     = "accepted_id",
  family     = "family",
  genus_out  = "genus_or_above",
  epithet    = "specific_epithet",
  authorship = "authorship",
  acc_name   = "accepted_name",
  acc_family = "accepted_family",
  acc_genus  = "accepted_genus",
  is_synonym = "is_synonym"
)


#' Create a GBIF backend object
#'
#' @return A taxify_backend object of class `"taxify_gbif"`.
#' @noRd
gbif_backend <- function() {
  new_backend(
    name = "gbif",
    version = .gbif_version,
    genus_col = "genus_or_above",
    col_map = .gbif_col_map,
    unblocked_fallback = TRUE,
    class = "taxify_gbif"
  )
}


#' @export
taxify_download.taxify_gbif <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  require_taxifydb("Building the GBIF backbone from source")
  output_dir <- dest %||% versioned_dir("gbif", "latest")
  taxifydb::build_gbif(output_dir = output_dir,
                       version = backend$version,
                       verbose = verbose)
}

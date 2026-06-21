# ---- GBIF (Global Biodiversity Information Facility) backbone backend ----
#
# Runtime matching against pre-built GBIF `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_gbif()` (sibling package).

# GBIF version pin (referenced by the constructor; updated with package releases)
.gbif_version <- "current"

# Column map for shared matching engine. Main matching columns come from the
# unified snake_case schema produced by taxifydb::normalize_backbone(); GBIF-
# specific extras (notho_type, nom_status, bracket_authorship, ...) are
# preserved verbatim by .gbif_extra_cols in the build and consumed by
# add_gbif_info().
.gbif_col_map <- list(
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
    prefix_fallback = TRUE,
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

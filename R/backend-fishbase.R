# ---- FishBase backbone backend ----
#
# Runtime matching against pre-built FishBase `.vtr` snapshots. Build-from-
# source delegates to `taxifydb::build_fishbase()` (sibling package). FishBase
# and SeaLifeBase share the unified backbone schema, so they share a col_map.

.fishbase_version <- "2026.06"

.rfishbase_col_map <- list(
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


#' Create a FishBase backend object
#'
#' @return A taxify_backend object of class `"taxify_fishbase"`.
#' @noRd
fishbase_backend <- function() {
  new_backend(
    name = "fishbase",
    version = .fishbase_version,
    genus_col = "genus",
    col_map = .rfishbase_col_map,
    class = "taxify_fishbase"
  )
}


#' @export
taxify_download.taxify_fishbase <- function(backend, dest = NULL,
                                            verbose = TRUE, ...) {
  require_taxifydb("Building the FishBase backbone from source")
  output_dir <- dest %||% versioned_dir("fishbase", "latest")
  taxifydb::build_fishbase(output_dir = output_dir,
                           version = backend$version,
                           verbose = verbose)
}

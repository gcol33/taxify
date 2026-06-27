# ---- Reptile Database backend ----
#
# Runtime matching against pre-built Reptile Database `.vtr` snapshots.
# Build-from-source delegates to `taxifydb::build_reptiledb()` (sibling
# package). The Reptile Database is the global taxonomic reference for reptiles
# (snakes, lizards, amphisbaenians, turtles, crocodiles, tuatara): ~12.6k
# accepted species plus ~34k synonyms, with full genus/family classification.
# License: CC-BY 4.0.

.reptiledb_version <- "2026.06"

# Unified backbone schema produced by taxifydb (shared with the other backends).
.reptiledb_col_map <- list(
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


#' Create a Reptile Database backend object
#'
#' @return A taxify_backend object of class `"taxify_reptiledb"`.
#' @noRd
reptiledb_backend <- function() {
  new_backend(
    name = "reptiledb",
    version = .reptiledb_version,
    genus_col = "genus",
    col_map = .reptiledb_col_map,
    class = "taxify_reptiledb"
  )
}


#' @export
taxify_download.taxify_reptiledb <- function(backend, dest = NULL,
                                             verbose = TRUE, ...) {
  require_taxifydb("Building the Reptile Database backbone from source")
  output_dir <- dest %||% versioned_dir("reptiledb", "latest")
  taxifydb::build_reptiledb(output_dir = output_dir,
                            version = backend$version,
                            verbose = verbose)
}

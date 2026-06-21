# ---- COL (Catalogue of Life) backend ----
#
# Runtime matching against pre-built COL `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_col()` (sibling package).

# COL version pin (referenced by the constructor; updated with package releases)
.col_version <- "2025"

# Column map for shared matching engine. Main matching columns come from the
# unified snake_case schema produced by taxifydb::normalize_backbone(); COL-
# specific extras (notho, nomenclaturalCode, kingdom, phylum, ...) are
# preserved verbatim by .col_extra_cols in the build and consumed by
# add_col_info(). The original COL `scientificName` (with authorship) is
# preserved as an extra alongside the authorship-free `canonical_name`.
.col_col_map <- list(
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


#' Create a COL backend object
#'
#' @return A taxify_backend object of class `"taxify_col"`.
#' @noRd
col_backend <- function() {
  new_backend(
    name = "col",
    version = .col_version,
    genus_col = "genericName",
    col_map = .col_col_map,
    prefix_fallback = TRUE,
    class = "taxify_col"
  )
}


#' @export
taxify_download.taxify_col <- function(backend, dest = NULL,
                                       verbose = TRUE, ...) {
  require_taxifydb("Building the COL backbone from source")
  output_dir <- dest %||% versioned_dir("col", "latest")
  taxifydb::build_col(output_dir = output_dir,
                      version = backend$version,
                      verbose = verbose)
}

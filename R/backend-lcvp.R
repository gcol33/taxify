# ---- LCVP (Leipzig Catalogue of Vascular Plants) backend ----
#
# Runtime matching against pre-built LCVP `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_lcvp()` (sibling package). The LCVP (Freiberg
# et al. 2020) is a global taxonomic reference for vascular plants derived from
# a reconciliation of major name sources; it carries species and infraspecific
# names with genus/family/order classification, but no genus-rank rows.
# License: MIT (idiv-biodiversity/LCVP data package).

# LCVP version pin (matches taxifydb's bundled LCVP data version)
.lcvp_version <- "3.0.1"

# Column map for the shared matching engine (unified backbone schema).
.lcvp_col_map <- list(
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


#' Create an LCVP backend object
#'
#' @return A taxify_backend object of class `"taxify_lcvp"`.
#' @noRd
lcvp_backend <- function() {
  new_backend(
    name = "lcvp",
    version = .lcvp_version,
    genus_col = "genus",
    col_map = .lcvp_col_map,
    class = "taxify_lcvp"
  )
}


#' @export
taxify_download.taxify_lcvp <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  require_taxifydb("Building the LCVP backbone from source")
  output_dir <- dest %||% versioned_dir("lcvp", "latest")
  taxifydb::build_lcvp(output_dir = output_dir,
                       version = backend$version,
                       verbose = verbose)
}

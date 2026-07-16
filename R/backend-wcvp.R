# ---- WCVP (World Checklist of Vascular Plants) backend ----
#
# Runtime matching against pre-built WCVP `.vtr` snapshots. Build-from-source
# delegates to `taxifydb::build_wcvp()` (sibling package). The WCVP (Govaerts
# et al. 2021) is Kew's global taxonomic backbone for vascular plants (~1.4M
# names, ~350k accepted species), carrying genus-rank rows plus full
# genus/family classification and authorship. License: CC BY 4.0.
#
# Distinct from the WCVP native-range enrichment (`add_wcvp()`), which joins
# per-region distribution from the same source's `wcvp_distribution.csv`; this
# backend is the name backbone from `wcvp_names.csv`.

# WCVP version pin (matches taxifydb's bundled WCVP snapshot tag)
.wcvp_version <- "2026.06"

# Column map for the shared matching engine (unified backbone schema).
.wcvp_col_map <- list(
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


#' Create a WCVP backend object
#'
#' @return A taxify_backend object of class `"taxify_wcvp"`.
#' @noRd
wcvp_backend <- function() {
  new_backend(
    name = "wcvp",
    version = .wcvp_version,
    genus_col = "genus",
    col_map = .wcvp_col_map,
    class = "taxify_wcvp"
  )
}


#' @export
taxify_build.taxify_wcvp <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  require_taxifydb("Building the WCVP backbone from source")
  output_dir <- dest %||% versioned_dir("wcvp", "latest")
  taxifydb::build_wcvp(output_dir = output_dir,
                       verbose = verbose)
}

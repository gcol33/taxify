# ---- Backend construction from the canonical registry ----
#
# taxifydb normalizes every backbone to one Darwin Core schema at build time, so
# every backbone matches against the same columns and builds through the same
# delegation. The per-backbone handle therefore differs only in its name, class,
# static version default, and whether the prefix-blocked fuzzy pass runs -- all
# of which come from a row of .backbone_registry() (R/backbones.R). One factory
# builds the object from that row; the thin named wrappers below are the entry
# points other modules and tests call.

# Shared column map for the matching engine: the unified snake_case schema
# produced by taxifydb::normalize_backbone(). Backbone-specific extras (the
# WFO/COL/GBIF columns consumed by add_wfo_info()/add_col_info()/add_gbif_info())
# are preserved verbatim in the .vtr at build time and read directly by those
# doors, not through this map.
.backbone_col_map <- list(
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


#' Construct a backend handle from its backbone's registry row
#'
#' @param name Backbone name (a row of `.backbone_registry()`).
#' @return A taxify_backend object of class `c("taxify_<name>", "taxify_backend")`.
#' @noRd
make_backend <- function(name) {
  reg <- .backbone_registry()
  i <- match(name, reg$name)
  if (is.na(i)) {
    stop(sprintf(
      "Unknown backbone '%s'. Available: %s",
      name, paste(reg$name, collapse = ", ")), call. = FALSE)
  }
  be <- new_backend(
    name    = name,
    version = reg$version[i],
    col_map = .backbone_col_map,
    class   = paste0("taxify_", name)
  )
  if (isTRUE(reg$prefix_fallback[i])) be$prefix_fallback <- TRUE
  be
}


# Thin per-backbone constructors: the named entry points other modules and tests
# call. Each fixes its registry name; make_backend() supplies the object.
wfo_backend         <- function() make_backend("wfo")
col_backend         <- function() make_backend("col")
colxr_backend       <- function() make_backend("colxr")
gbif_backend        <- function() make_backend("gbif")
itis_backend        <- function() make_backend("itis")
ncbi_backend        <- function() make_backend("ncbi")
ott_backend         <- function() make_backend("ott")
worms_backend       <- function() make_backend("worms")
euromed_backend     <- function() make_backend("euromed")
fungorum_backend    <- function() make_backend("fungorum")
algaebase_backend   <- function() make_backend("algaebase")
fishbase_backend    <- function() make_backend("fishbase")
sealifebase_backend <- function() make_backend("sealifebase")
reptiledb_backend   <- function() make_backend("reptiledb")
lcvp_backend        <- function() make_backend("lcvp")
wcvp_backend        <- function() make_backend("wcvp")
mdd_backend         <- function() make_backend("mdd")
avilist_backend     <- function() make_backend("avilist")
lpsn_backend        <- function() make_backend("lpsn")


# Default build method for every backbone: delegates to taxifydb::build_<name>(),
# mirroring the single-default-method shape of taxify_load.taxify_backend(). The
# slug is always the backbone name, so one method covers all backbones.
#' @exportS3Method
taxify_build.taxify_backend <- function(backend, dest = NULL,
                                        verbose = TRUE, ...) {
  name <- backend$name
  require_taxifydb(sprintf("Building %s from source", backbone_label(name)))
  output_dir <- dest %||% versioned_dir(name, "latest")
  builder <- getExportedValue("taxifydb", paste0("build_", name))
  builder(output_dir = output_dir, verbose = verbose)
}

# ---- SeaLifeBase backbone backend ----
#
# Runtime matching against pre-built SeaLifeBase `.vtr` snapshots. Build-from-
# source delegates to `taxifydb::build_sealifebase()`. Shares the unified
# rfishbase col_map defined in backend-fishbase.R.

.sealifebase_version <- "2026.06"


#' Create a SeaLifeBase backend object
#'
#' @return A taxify_backend object of class `"taxify_sealifebase"`.
#' @noRd
sealifebase_backend <- function() {
  new_backend(
    name = "sealifebase",
    version = .sealifebase_version,
    genus_col = "genus",
    col_map = .rfishbase_col_map,
    class = "taxify_sealifebase"
  )
}


#' @export
taxify_download.taxify_sealifebase <- function(backend, dest = NULL,
                                               verbose = TRUE, ...) {
  require_taxifydb("Building the SeaLifeBase backbone from source")
  output_dir <- dest %||% versioned_dir("sealifebase", "latest")
  taxifydb::build_sealifebase(output_dir = output_dir,
                              version = backend$version,
                              verbose = verbose)
}

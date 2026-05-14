#' Require taxifydb for build-from-source operations
#'
#' Many taxify functions can fall back to building data from source when
#' pre-built `.vtr` files are not available. That build code lives in the
#' sibling package `taxifydb`. This helper checks for it and errors with
#' an install instruction if missing.
#'
#' @noRd
require_taxifydb <- function(operation = "this operation") {
  if (!requireNamespace("taxifydb", quietly = TRUE)) {
    stop(
      sprintf(
        "%s requires the 'taxifydb' package.\n  Install with: remotes::install_github(\"gcol33/taxify-backbones\")",
        operation
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

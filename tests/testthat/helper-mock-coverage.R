# Mock backend-coverage for out-of-scope tests.
#
# prefilter_out_of_scope() and enrich_with_register() read the backend-coverage
# .vtr (genus x backend) to decide which genera a backend covers; a register
# genus that is NOT covered by the queried backend is flagged "out_of_scope".
# On a clean machine that file does not exist, so these helpers let a test
# supply its own coverage and read it deterministically.

#' Write a mock coverage .vtr and return its path
#'
#' @param genus Character vector of covered genera.
#' @param backend Character scalar (recycled) naming the covering backend.
#' @return Path to a temporary .vtr file.
mock_coverage_vtr <- function(genus, backend = "wfo") {
  df <- data.frame(genus = genus,
                   backend = rep(backend, length.out = length(genus)),
                   stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

#' Clear the per-backend covered-genera cache
#'
#' The out-of-scope pre-filter caches covered genera in `.taxify_env` keyed by
#' backend. Clear it so a freshly mocked coverage file is read instead of a
#' value left over from another test (or the real install).
#' @param backends Character vector of backend names to clear.
clear_coverage_cache <- function(backends = c("wfo", "col", "gbif", "itis",
                                              "ncbi", "ott", "worms")) {
  for (be in backends) .taxify_env[[paste0("coverage_", be)]] <- NULL
}

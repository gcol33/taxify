# Mock backbone-coverage for out-of-scope tests.
#
# prefilter_out_of_scope() and enrich_with_register() read the backbone-coverage
# .vtr (genus x backbone) to decide which genera a backbone covers; a register
# genus that is NOT covered by the queried backbone is flagged "out_of_scope".
# On a clean machine that file does not exist, so these helpers let a test
# supply its own coverage and read it deterministically.

#' Write a mock coverage .vtr and return its path
#'
#' @param genus Character vector of covered genera.
#' @param backbone Character scalar (recycled) naming the covering backbone.
#' @return Path to a temporary .vtr file.
mock_coverage_vtr <- function(genus, backbone = "wfo") {
  # `backend` is the column name inside the published backend_coverage.vtr,
  # which taxifydb writes; the mock has to match it.
  df <- data.frame(genus = genus,
                   backend = rep(backbone, length.out = length(genus)),
                   stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, tmp, batch_size = 50000L)
  tmp
}

#' Clear the covered-genera caches
#'
#' The out-of-scope pre-filter caches covered genera in `.taxify_env`, both per
#' backbone (`coverage_<name>`) and per backbone set (`coverage_union_<set>`).
#' Clear every one so a freshly mocked coverage file is read instead of a value
#' left over from another test (or the real install). The union keys are named
#' after arbitrary backbone sets, so this drops by prefix rather than by list.
#'
#' The once-per-session flags behind the uncovered-backbone warning
#' (`.uncovered_warned_<name>`) are cleared too: they are part of the same
#' cached state, and a test expecting the warning would otherwise see nothing
#' because an earlier test already spent it.
#' @param backbones Ignored. Every coverage key is cleared.
clear_coverage_cache <- function(backbones = NULL) {
  keys <- ls(.taxify_env, all.names = TRUE)
  drop <- startsWith(keys, "coverage_") |
          startsWith(keys, ".uncovered_warned_")
  for (k in keys[drop]) .taxify_env[[k]] <- NULL
}

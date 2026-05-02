setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)
devtools::load_all(quiet = TRUE)

# Try the previously-failing items including the harder ones.
# - common_names: now skips OTT gracefully (was the only reason it failed)
# - diaz_traits, alien_first_records: known publisher/network blocks; will
#   attempt and report.
to_try <- c("common_names", "diaz_traits", "alien_first_records")

for (name in to_try) {
  vtr <- enrichment_vtr_path(name)
  if (file.exists(vtr)) {
    file.remove(vtr)
    cat(sprintf("  removed stale %s\n", vtr))
  }
  meta <- file.path(dirname(vtr), "meta.json")
  if (file.exists(meta)) file.remove(meta)
}

dl_root <- file.path(tempdir(), "taxify_enrichment_build")
for (name in to_try) {
  sub <- file.path(dl_root, name)
  if (dir.exists(sub)) {
    unlink(sub, recursive = TRUE)
  }
}

results <- data.frame(
  enrichment = character(0), status = character(0),
  size_mb = numeric(0), elapsed_s = numeric(0),
  error = character(0), stringsAsFactors = FALSE
)

for (name in to_try) {
  cat(sprintf("\n=== %s ===\n", name))
  t0 <- Sys.time()
  ok <- tryCatch({
    build_enrichment_from_source(name, verbose = TRUE)
    TRUE
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", conditionMessage(e)))
    conditionMessage(e)
  })
  dt <- as.numeric(Sys.time() - t0, units = "secs")

  vtr <- enrichment_vtr_path(name)
  if (isTRUE(ok) && file.exists(vtr)) {
    sz <- file.size(vtr) / 1048576
    cat(sprintf("  OK  %.2f MB  in %.1f s\n", sz, dt))
    results <- rbind(results, data.frame(
      enrichment = name, status = "OK",
      size_mb = round(sz, 2), elapsed_s = round(dt, 1),
      error = "", stringsAsFactors = FALSE
    ))
  } else {
    err <- if (isTRUE(ok)) "vtr not produced" else as.character(ok)
    results <- rbind(results, data.frame(
      enrichment = name, status = "FAIL",
      size_mb = NA_real_, elapsed_s = round(dt, 1),
      error = err, stringsAsFactors = FALSE
    ))
  }
}

cat("\n\n=== SUMMARY ===\n")
print(results, row.names = FALSE)

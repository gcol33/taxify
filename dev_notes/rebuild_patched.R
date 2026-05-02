setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)
devtools::load_all(quiet = TRUE)

cat(sprintf("vectra: %s\n", as.character(packageVersion("vectra"))))

for (name in c("fish_traits", "conservation_status")) {
  cat(sprintf("\n=== [%s] %s ===\n", format(Sys.time()), name))
  vtr_path <- enrichment_vtr_path(name)
  if (file.exists(vtr_path)) {
    cat("  removing stale .vtr (none expected, but safe)\n")
    unlink(vtr_path)
  }
  t0 <- Sys.time()
  ok <- tryCatch({
    build_enrichment_from_source(name, verbose = TRUE)
    TRUE
  }, error = function(e) {
    cat("  ERROR:", conditionMessage(e), "\n")
    FALSE
  })
  dt <- as.numeric(Sys.time() - t0, units = "mins")
  if (ok && file.exists(vtr_path)) {
    sz <- file.size(vtr_path) / 1048576
    cat(sprintf("  [OK] %.1f MB in %.1f min\n", sz, dt))
  } else {
    cat(sprintf("  [FAIL] after %.1f min\n", dt))
  }
}

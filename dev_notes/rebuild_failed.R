setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)
devtools::load_all(quiet = TRUE)

# Failed enrichments that had URL drift / format changes (now patched).
failed <- c(
  "woodiness",       # Dryad direct file
  "fungal_traits",   # MOESM2 -> MOESM5 + Springer Referer
  "leda",            # new uol.de/f/5/inst/... path + 2016 filename suffixes
  "lizard_traits",   # switched figshare -> Dryad CSV
  "funguild",        # mycoportal -> stbates.org HTML+JSON
  "glonaf"           # zip -> individual XLSX files from Zenodo
)

# Force fresh build: delete any existing partial files
for (name in failed) {
  vtr <- enrichment_vtr_path(name)
  if (file.exists(vtr)) {
    file.remove(vtr)
    cat(sprintf("  removed stale %s\n", vtr))
  }
  meta <- file.path(dirname(vtr), "meta.json")
  if (file.exists(meta)) file.remove(meta)
}

# Also clear download cache so we re-fetch with new URLs
dl_root <- file.path(tempdir(), "taxify_enrichment_build")
if (dir.exists(dl_root)) {
  for (name in failed) {
    sub <- file.path(dl_root, name)
    if (dir.exists(sub)) {
      unlink(sub, recursive = TRUE)
      cat(sprintf("  cleared download cache for %s\n", name))
    }
  }
}

results <- data.frame(
  enrichment = character(0), status = character(0),
  size_mb = numeric(0), elapsed_s = numeric(0),
  error = character(0), stringsAsFactors = FALSE
)

for (name in failed) {
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

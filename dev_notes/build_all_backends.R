setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)

devtools::load_all(quiet = TRUE)

LOG <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/build_all_backends.log"

log_msg <- function(...) {
  msg <- sprintf("[%s] %s", format(Sys.time()), paste0(..., collapse = ""))
  cat(msg, "\n", sep = "")
  cat(msg, "\n", sep = "", file = LOG, append = TRUE)
  flush.console()
}

backends <- list(
  list(name = "wfo",       ctor = wfo_backend,       file = "wfo.vtr"),
  list(name = "col",       ctor = col_backend,       file = "col.vtr"),
  list(name = "gbif",      ctor = gbif_backend,      file = "gbif.vtr"),
  list(name = "itis",      ctor = itis_backend,      file = "itis.vtr"),
  list(name = "ncbi",      ctor = ncbi_backend,      file = "ncbi.vtr"),
  list(name = "ott",       ctor = ott_backend,       file = "ott.vtr"),
  list(name = "worms",     ctor = worms_backend,     file = "worms.vtr"),
  list(name = "euromed",   ctor = euromed_backend,   file = "euromed.vtr"),
  list(name = "fungorum",  ctor = fungorum_backend,  file = "fungorum.vtr"),
  list(name = "algaebase", ctor = algaebase_backend, file = "algaebase.vtr")
)

unlink(LOG)
log_msg("=== BACKEND BUILD START ===")
log_msg("data dir: ", taxify_data_dir())
log_msg("vectra:   ", as.character(packageVersion("vectra")))

results <- list()
for (b in backends) {
  vtr_path <- file.path(taxify_data_dir(), b$name, "latest", b$file)
  if (file.exists(vtr_path)) {
    sz <- file.size(vtr_path) / 1048576
    log_msg(sprintf("[SKIP] %s: already exists (%.1f MB)", b$name, sz))
    results[[b$name]] <- list(status = "skipped", size_mb = sz, time = NA)
    next
  }

  log_msg(sprintf("[START] %s", b$name))
  t0 <- Sys.time()
  ok <- tryCatch({
    taxify_download(b$ctor(), verbose = TRUE)
    TRUE
  }, error = function(e) {
    log_msg(sprintf("[ERROR] %s: %s", b$name, conditionMessage(e)))
    FALSE
  })
  dt <- as.numeric(Sys.time() - t0, units = "mins")

  if (ok && file.exists(vtr_path)) {
    sz <- file.size(vtr_path) / 1048576
    log_msg(sprintf("[OK]    %s: %.1f MB in %.1f min", b$name, sz, dt))
    results[[b$name]] <- list(status = "ok", size_mb = sz, time = dt)
  } else {
    log_msg(sprintf("[FAIL]  %s: after %.1f min", b$name, dt))
    results[[b$name]] <- list(status = "fail", size_mb = NA, time = dt)
  }
}

log_msg("=== BACKEND BUILD COMPLETE ===")
log_msg(sprintf("Summary: %d ok, %d skipped, %d fail",
                sum(vapply(results, function(r) r$status == "ok",       logical(1))),
                sum(vapply(results, function(r) r$status == "skipped",  logical(1))),
                sum(vapply(results, function(r) r$status == "fail",     logical(1)))))

for (n in names(results)) {
  r <- results[[n]]
  log_msg(sprintf("  %-10s %-8s %s",
                  n, r$status,
                  if (!is.na(r$size_mb)) sprintf("%.1f MB", r$size_mb) else ""))
}

saveRDS(results, "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/build_all_backends.rds")

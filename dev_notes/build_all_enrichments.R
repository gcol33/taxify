setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)

devtools::load_all(quiet = TRUE)

LOG <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/build_all_enrichments.log"

log_msg <- function(...) {
  msg <- sprintf("[%s] %s", format(Sys.time()), paste0(..., collapse = ""))
  cat(msg, "\n", sep = "")
  cat(msg, "\n", sep = "", file = LOG, append = TRUE)
  flush.console()
}

# Build order: small/fast/well-tested first, big ones last.
# common_names is huge (downloads GBIF + NCBI + OTT); put it near the end.
order <- c(
  "woodiness", "diaz_traits", "eive", "amphibio", "pantheria",
  "elton_traits", "avonet", "leda", "anage", "leptraits",
  "animaltraits", "arthropod_traits", "conservation_status",
  "griis", "wcvp", "glonaf",
  "fungal_traits", "algae_traits", "fish_traits", "lizard_traits",
  "funguild", "fishbase", "alien_first_records",
  "common_names"
)

unlink(LOG)
log_msg("=== ENRICHMENT BUILD START ===")
log_msg("Total: ", length(order), " enrichments")

results <- list()
for (name in order) {
  vtr_path <- tryCatch(enrichment_vtr_path(name), error = function(e) NULL)
  if (!is.null(vtr_path) && file.exists(vtr_path)) {
    sz <- file.size(vtr_path) / 1048576
    log_msg(sprintf("[SKIP] %s: already exists (%.1f MB)", name, sz))
    results[[name]] <- list(status = "skipped", size_mb = sz, time = NA)
    next
  }

  log_msg(sprintf("[START] %s", name))
  t0 <- Sys.time()
  ok <- tryCatch({
    build_enrichment_from_source(name, verbose = TRUE)
    TRUE
  }, error = function(e) {
    log_msg(sprintf("[ERROR] %s: %s", name, conditionMessage(e)))
    FALSE
  })
  dt <- as.numeric(Sys.time() - t0, units = "mins")

  vtr_path <- tryCatch(enrichment_vtr_path(name), error = function(e) NULL)
  if (ok && !is.null(vtr_path) && file.exists(vtr_path)) {
    sz <- file.size(vtr_path) / 1048576
    log_msg(sprintf("[OK]    %s: %.1f MB in %.1f min", name, sz, dt))
    results[[name]] <- list(status = "ok", size_mb = sz, time = dt)
  } else {
    log_msg(sprintf("[FAIL]  %s: after %.1f min", name, dt))
    results[[name]] <- list(status = "fail", size_mb = NA, time = dt)
  }
}

log_msg("=== ENRICHMENT BUILD COMPLETE ===")
log_msg(sprintf("Summary: %d ok, %d skipped, %d fail",
                sum(vapply(results, function(r) r$status == "ok",       logical(1))),
                sum(vapply(results, function(r) r$status == "skipped",  logical(1))),
                sum(vapply(results, function(r) r$status == "fail",     logical(1)))))

for (n in names(results)) {
  r <- results[[n]]
  log_msg(sprintf("  %-22s %-8s %s",
                  n, r$status,
                  if (!is.na(r$size_mb)) sprintf("%.1f MB", r$size_mb) else ""))
}

saveRDS(results, "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/build_all_enrichments.rds")

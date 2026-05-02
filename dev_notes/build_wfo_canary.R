setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 3600)

devtools::load_all(quiet = TRUE)

cat(sprintf("[%s] Starting WFO canary build\n", format(Sys.time())))
cat(sprintf("data dir: %s\n", taxify_data_dir()))
cat(sprintf("vectra:   %s\n\n", as.character(packageVersion("vectra"))))

t0 <- Sys.time()
result <- tryCatch(
  taxify_download(wfo_backend(), verbose = TRUE),
  error = function(e) {
    cat("\n[ERROR]", conditionMessage(e), "\n")
    NULL
  }
)
dt <- Sys.time() - t0

cat(sprintf("\n[%s] Done. Elapsed: %s\n",
            format(Sys.time()),
            format(dt, digits = 3)))

if (is.null(result)) {
  quit(status = 1)
}

# Verify the .vtr opens and a query works
vtr_path <- file.path(taxify_data_dir(), "wfo", "latest", "wfo.vtr")
cat(sprintf("vtr path: %s\n", vtr_path))
cat(sprintf("vtr size: %.1f MB\n", file.size(vtr_path) / 1048576))

cat("\nSmoke test taxify():\n")
res <- taxify(c("Quercus robur", "Fagus sylvatica", "NotARealName xyz"),
              backend = "wfo", verbose = FALSE)
print(res[, c("input_name", "accepted_name", "match_type", "status")])

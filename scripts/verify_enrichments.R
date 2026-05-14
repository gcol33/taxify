suppressPackageStartupMessages({
  library(vectra)
})
cat("vectra version:", as.character(packageVersion("vectra")), "\n\n")

root <- file.path(Sys.getenv("APPDATA"), "R", "data", "R", "taxify", "enrichment")
dirs <- list.dirs(root, recursive = FALSE)

results <- data.frame(
  enrichment = character(),
  rows       = integer(),
  status     = character(),
  detail     = character(),
  stringsAsFactors = FALSE
)

for (d in dirs) {
  name <- basename(d)
  vtrs <- list.files(file.path(d, "latest"), pattern = "\\.vtr$",
                     full.names = TRUE)
  if (!length(vtrs)) {
    results <- rbind(results, data.frame(
      enrichment = name, rows = NA_integer_, status = "MISSING",
      detail = "no .vtr in latest/", stringsAsFactors = FALSE))
    next
  }
  vtr <- vtrs[1]
  res <- tryCatch({
    n <- vectra::tbl(vtr) |> vectra::collect() |> nrow()
    list(rows = n, status = "OK", detail = "")
  }, error = function(e) {
    list(rows = NA_integer_, status = "FAIL",
         detail = conditionMessage(e))
  })
  results <- rbind(results, data.frame(
    enrichment = name, rows = res$rows, status = res$status,
    detail = res$detail, stringsAsFactors = FALSE))
}

print(results, row.names = FALSE)

cat("\n=== Summary ===\n")
cat("OK:     ", sum(results$status == "OK"), "\n")
cat("FAIL:   ", sum(results$status == "FAIL"), "\n")
cat("MISSING:", sum(results$status == "MISSING"), "\n")

failed <- results[results$status == "FAIL", ]
if (nrow(failed)) {
  cat("\n=== Failures ===\n")
  for (i in seq_len(nrow(failed))) {
    cat(sprintf("  %s: %s\n", failed$enrichment[i], failed$detail[i]))
  }
}

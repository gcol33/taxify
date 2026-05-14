setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressMessages({
  library(vectra)
  devtools::load_all(quiet = TRUE)
})

cat("vectra version:", as.character(packageVersion("vectra")), "\n")
cat("taxify version:", as.character(packageVersion("taxify")), "\n")
cat("start:", format(Sys.time()), "\n")

dst <- file.path(taxify_data_dir(), "algaebase", "latest")
unlink(file.path(dst, "algaebase.vtr"), force = TRUE)
unlink(list.files(dst, pattern = "^algaebase\\.vtr\\..*\\.vtri$",
                  full.names = TRUE),
       force = TRUE)

t0 <- proc.time()
taxify_download(algaebase_backend(), dest = dst, verbose = TRUE)
elapsed <- (proc.time() - t0)["elapsed"]

cat("\n=== finished in", round(elapsed), "seconds ===\n")
cat("end:", format(Sys.time()), "\n")

vtr_path <- file.path(dst, "algaebase.vtr")
if (file.exists(vtr_path)) {
  size_mb <- file.info(vtr_path)$size / 1024^2
  n <- collect(summarise(tbl(vtr_path), n = n()))[[1]]
  cat(sprintf("vtr: %.1f MB, %d rows\n", size_mb, n))

  meta <- list(
    version = "2025.04",
    pinned = FALSE,
    downloaded_at = format(Sys.Date())
  )
  jsonlite::write_json(meta, file.path(dst, "meta.json"),
                       auto_unbox = TRUE, pretty = TRUE)
  cat("wrote meta.json\n")
} else {
  cat("ERROR: vtr not produced\n")
  quit(status = 1)
}

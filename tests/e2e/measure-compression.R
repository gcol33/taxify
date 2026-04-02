setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")

dest <- tools::R_user_dir("taxify", "data")
fmt <- function(bytes) sprintf("%.0f MB", bytes / 1024^2)

cat("=== Compression test: re-write existing backbones with v4 encoding ===\n\n")

for (backend in c("wfo", "col", "gbif")) {
  vtr_path <- file.path(dest, paste0(backend, ".vtr"))
  if (!file.exists(vtr_path)) {
    cat(backend, ": not found, skipping\n")
    next
  }

  old_size <- file.size(vtr_path)
  cat(sprintf("%s: current size = %s\n", toupper(backend), fmt(old_size)))

  # Read and re-write with new vectra (v4 compression)
  new_path <- file.path(dest, paste0(backend, "_v4.vtr"))
  t0 <- Sys.time()
  df <- tbl(vtr_path) |> collect()
  cat(sprintf("  Read: %.1f sec, %d rows x %d cols\n",
              difftime(Sys.time(), t0, units = "secs"), nrow(df), ncol(df)))

  t1 <- Sys.time()
  write_vtr(df, new_path)
  cat(sprintf("  Write v4: %.1f sec\n", difftime(Sys.time(), t1, units = "secs")))

  new_size <- file.size(new_path)
  ratio <- old_size / new_size
  savings <- 100 * (1 - new_size / old_size)
  cat(sprintf("  New size: %s (%.1fx compression, %.0f%% smaller)\n\n",
              fmt(new_size), ratio, savings))

  # Clean up (don't keep the v4 file)
  unlink(new_path)
  rm(df)
  gc(verbose = FALSE)
}

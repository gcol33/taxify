setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")

dest <- tools::R_user_dir("taxify", "data")
fmt_mb <- function(bytes) sprintf("%.0f MB", bytes / 1024^2)

# Test on WFO (smallest, fastest iteration)
wfo_path <- file.path(dest, "wfo.vtr")
cat("Reading WFO backbone...\n")
t0 <- Sys.time()
wfo_df <- tbl(wfo_path) |> collect()
cat(sprintf("  Read: %.1f sec, %d rows x %d cols\n",
            difftime(Sys.time(), t0, units = "secs"), nrow(wfo_df), ncol(wfo_df)))

new_path <- tempfile(fileext = ".vtr")
cat("Writing WFO with optimized v4...\n")
t1 <- Sys.time()
write_vtr(wfo_df, new_path)
dt <- difftime(Sys.time(), t1, units = "secs")
cat(sprintf("  Write: %.1f sec\n", dt))
cat(sprintf("  Size: %s (was %s)\n", fmt_mb(file.size(new_path)), fmt_mb(file.size(wfo_path))))

# Verify round-trip
cat("Verifying round-trip...\n")
rt <- tbl(new_path) |> collect()
stopifnot(nrow(rt) == nrow(wfo_df))
stopifnot(ncol(rt) == ncol(wfo_df))
# Spot-check a column
stopifnot(identical(rt$scientificName[1:100], wfo_df$scientificName[1:100]))
cat("  Round-trip OK\n")

unlink(new_path)
rm(wfo_df, rt)
gc(verbose = FALSE)

# Now test COL
col_path <- file.path(dest, "col.vtr")
if (file.exists(col_path)) {
  cat("\nReading COL backbone...\n")
  t0 <- Sys.time()
  col_df <- tbl(col_path) |> collect()
  cat(sprintf("  Read: %.1f sec, %d rows x %d cols\n",
              difftime(Sys.time(), t0, units = "secs"), nrow(col_df), ncol(col_df)))

  new_path2 <- tempfile(fileext = ".vtr")
  cat("Writing COL with optimized v4...\n")
  t1 <- Sys.time()
  write_vtr(col_df, new_path2)
  dt <- difftime(Sys.time(), t1, units = "secs")
  cat(sprintf("  Write: %.1f sec (was 764.7 sec)\n", dt))
  cat(sprintf("  Size: %s (was %s)\n", fmt_mb(file.size(new_path2)), fmt_mb(file.size(col_path))))
  unlink(new_path2)
  rm(col_df)
  gc(verbose = FALSE)
}

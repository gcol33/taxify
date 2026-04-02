setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

cat("Re-downloading COL backbone with family denormalization...\n")
t0 <- Sys.time()
path <- taxify_download("col")
dt <- difftime(Sys.time(), t0, units = "mins")
cat(sprintf("Done in %.1f minutes\n", dt))
cat(sprintf("Path: %s\n", path))
cat(sprintf("Size: %.0f MB\n", file.size(path) / 1024^2))

# Quick verification
cat("\nQuick family check:\n")
bb_path <- path
sample <- vectra::tbl(bb_path) |>
  vectra::filter(canonicalName == "Quercus robur") |>
  utils::head(1L) |>
  vectra::collect()
cat(sprintf("  Quercus robur -> family=%s\n", sample$family[1]))

sample2 <- vectra::tbl(bb_path) |>
  vectra::filter(canonicalName == "Panthera leo") |>
  utils::head(1L) |>
  vectra::collect()
cat(sprintf("  Panthera leo -> family=%s\n", sample2$family[1]))

# Quick match test
res <- taxify(c("Quercus robur", "Panthera leo"), backend = "col", verbose = FALSE)
cat("\nMatch test:\n")
print(res[, c("input_name", "matched_name", "family", "match_type")])

setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

cat("Re-downloading COL backbone with vectorized family denormalization...\n")
t0 <- Sys.time()
path <- taxify_download("col")
dt <- difftime(Sys.time(), t0, units = "mins")
cat(sprintf("Done in %.1f minutes\n", dt))
cat(sprintf("Path: %s\n", path))
cat(sprintf("Size: %.0f MB\n", file.size(path) / 1024^2))

# Quick verification
cat("\nFamily check:\n")
bb_path <- path

check_names <- c("Quercus robur", "Panthera leo", "Agaricus bisporus",
                 "Salmo trutta", "Pinus sylvestris")
for (nm in check_names) {
  sample <- vectra::tbl(bb_path) |>
    vectra::filter(canonicalName == .env$nm) |>
    utils::head(1L) |>
    vectra::collect()
  fam <- if (nrow(sample) > 0 && !is.na(sample$family[1])) sample$family[1] else "NA"
  cat(sprintf("  %s -> family=%s\n", nm, fam))
}

# Quick match test
cat("\nMatch test:\n")
res <- taxify(c("Quercus robur", "Panthera leo", "Salmo trutta"),
              backend = "col", verbose = FALSE)
print(res[, c("input_name", "matched_name", "family", "match_type")])

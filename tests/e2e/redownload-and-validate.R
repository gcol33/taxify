# Re-download WFO backbone (now with UTF-8 encoding) then run ASAAS validation
setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

cat("=== Re-downloading WFO backbone with UTF-8 encoding ===\n")
taxify_clear_cache()
t0 <- Sys.time()
path <- taxify_download("wfo")
cat(sprintf("  Done in %.1f min\n\n", difftime(Sys.time(), t0, units = "mins")))

# Quick sanity check: × should be proper now
bb <- vectra::tbl(path) |>
  vectra::filter(startsWith(scientificName, "Quercus")) |>
  vectra::filter(grepl("\u00d7", scientificName)) |>
  vectra::select(scientificName) |>
  utils::head(5) |>
  vectra::collect()
cat("Sample hybrid names in backbone:\n")
print(bb)

# Check for mojibake
bb_moji <- vectra::tbl(path) |>
  vectra::filter(grepl("\u00c3", scientificName)) |>
  vectra::select(scientificName) |>
  utils::head(5) |>
  vectra::collect()
cat("\nMojibake check (should be 0 rows):\n")
print(bb_moji)

# Now run validation
cat("\n")
source("tests/e2e/test-asaas-validation.R")

setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

cat("Downloading WFO backbone...\n")
t0 <- Sys.time()
path <- taxify_download("wfo")
cat(sprintf("Done in %.1f minutes\n", difftime(Sys.time(), t0, units = "mins")))
cat(sprintf("Path: %s\n", path))
cat(sprintf("Size: %.0f MB\n", file.size(path) / 1024^2))

# Quick test
cat("\nQuick match test:\n")
res <- taxify(c("Quercus robur", "Pinus sylvestris"), backend = "wfo", verbose = TRUE)
print(res[, c("input_name", "matched_name", "family", "match_type")])

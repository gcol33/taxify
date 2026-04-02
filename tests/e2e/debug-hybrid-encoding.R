# Debug: what does × look like in the WFO backbone?
setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

taxify_clear_cache()
path <- taxify_download("wfo")

# Find hybrid names in backbone
bb <- vectra::tbl(path) |>
  vectra::filter(startsWith(scientificName, "Quercus")) |>
  vectra::select(taxonID, scientificName) |>
  vectra::collect()

# Search for any × (proper Unicode)
has_times <- grepl("\u00d7", bb$scientificName)
cat(sprintf("Names with proper × (U+00D7): %d\n", sum(has_times)))
if (sum(has_times) > 0) {
  print(head(bb$scientificName[has_times], 5))
}

# Search for Ã (mojibake marker)
has_atilde <- grepl("\u00c3", bb$scientificName)
cat(sprintf("Names with Ã (U+00C3, mojibake): %d\n", sum(has_atilde)))
if (sum(has_atilde) > 0) {
  print(head(bb$scientificName[has_atilde], 5))
}

# Check raw bytes of a known hybrid
target <- bb$scientificName[grepl("rosacea", bb$scientificName, ignore.case = TRUE)]
cat("\nAll Quercus *rosacea* entries:\n")
for (t in target) {
  cat(sprintf("  '%s' -> bytes: %s\n", t,
              paste(chartr("0123456789abcdef", "0123456789ABCDEF",
                    format(as.hexmode(utf8ToInt(t)))), collapse = " ")))
}

# Check across all genera
bb_all <- vectra::tbl(path) |>
  vectra::select(scientificName) |>
  vectra::collect()

has_times_all <- grepl("\u00d7", bb_all$scientificName)
has_atilde_all <- grepl("\u00c3", bb_all$scientificName)
cat(sprintf("\nFull backbone: %d names with ×, %d with Ã\n",
            sum(has_times_all), sum(has_atilde_all)))

# Show some Ã examples
if (sum(has_atilde_all) > 0) {
  examples <- head(bb_all$scientificName[has_atilde_all], 10)
  cat("Ã examples:\n")
  for (e in examples) {
    cat(sprintf("  '%s' -> bytes: %s\n", e,
                paste(chartr("0123456789abcdef", "0123456789ABCDEF",
                      format(as.hexmode(utf8ToInt(e)))), collapse = " ")))
  }
}

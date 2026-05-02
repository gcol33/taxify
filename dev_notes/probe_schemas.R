setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all(quiet = TRUE)

paths <- list(
  wfo     = file.path(taxify_data_dir(), "wfo",     "latest", "wfo.vtr"),
  col     = file.path(taxify_data_dir(), "col",     "latest", "col.vtr"),
  gbif    = file.path(taxify_data_dir(), "gbif",    "latest", "gbif.vtr"),
  itis    = file.path(taxify_data_dir(), "itis",    "latest", "itis.vtr"),
  ncbi    = file.path(taxify_data_dir(), "ncbi",    "latest", "ncbi.vtr"),
  worms   = file.path(taxify_data_dir(), "worms",   "latest", "worms.vtr"),
  euromed = file.path(taxify_data_dir(), "euromed", "latest", "euromed.vtr")
)

want <- c("canonical_name", "scientificName", "family", "genus",
          "genus_or_above", "genericName", "kingdom", "phylum", "class", "order")

for (n in names(paths)) {
  if (!file.exists(paths[[n]])) { cat(sprintf("[%s] MISSING\n", n)); next }
  cols <- names(vectra::tbl(paths[[n]]) |> head(1) |> vectra::collect())
  cat(sprintf("[%s] %d cols\n", n, length(cols)))
  has <- intersect(want, cols)
  miss <- setdiff(want, cols)
  cat(sprintf("  has   : %s\n", paste(has, collapse = ", ")))
  cat(sprintf("  miss  : %s\n", paste(miss, collapse = ", ")))
}

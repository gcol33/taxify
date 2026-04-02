setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

bb_path <- file.path(taxify_data_dir(), "col.vtr")

# Check how many rows have non-NA family
cat("Checking family population in COL backbone...\n")
n_with_family <- vectra::tbl(bb_path) |>
  vectra::filter(!is.na(family)) |>
  vectra::summarise(n = n()) |>
  vectra::collect()
cat("Rows with family:", n_with_family$n, "\n")

n_total <- vectra::tbl(bb_path) |>
  vectra::summarise(n = n()) |>
  vectra::collect()
cat("Total rows:", n_total$n, "\n")

# Check kingdom/phylum/class/order — are these also empty?
sample <- vectra::tbl(bb_path) |>
  vectra::filter(canonicalName == "Quercus robur") |>
  utils::head(1L) |>
  vectra::collect()

cat("\nQuercus robur hierarchy fields:\n")
for (col in c("kingdom", "phylum", "class", "order", "superfamily", "family",
              "subfamily", "tribe")) {
  val <- sample[[col]]
  cat(sprintf("  %s: %s\n", col, ifelse(is.na(val), "NA", val)))
}

# Check if family-rank entries exist and have the column populated
fam_entries <- vectra::tbl(bb_path) |>
  vectra::filter(taxonRank == "FAMILY" & canonicalName == "Fagaceae") |>
  utils::head(3L) |>
  vectra::collect()
cat("\nFagaceae (family-rank entries):\n")
if (nrow(fam_entries) > 0) {
  print(fam_entries[, c("taxonID", "canonicalName", "taxonRank", "family",
                         "kingdom", "parentNameUsageID")])
}

# Check parentNameUsageID chain for Quercus robur
cat("\nParent chain for Quercus robur:\n")
parent_id <- sample$parentNameUsageID[1]
cat("  parent_id:", parent_id, "\n")
for (step in 1:5) {
  if (is.na(parent_id)) break
  parent <- vectra::tbl(bb_path) |>
    vectra::filter(taxonID == .env$parent_id) |>
    utils::head(1L) |>
    vectra::collect()
  if (nrow(parent) == 0) {
    cat(sprintf("  [%d] ID %s: NOT FOUND\n", step, parent_id))
    break
  }
  cat(sprintf("  [%d] %s (%s) rank=%s\n", step, parent$canonicalName[1],
              parent$taxonID[1], parent$taxonRank[1]))
  parent_id <- parent$parentNameUsageID[1]
}

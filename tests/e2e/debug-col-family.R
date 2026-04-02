setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

bb_path <- file.path(taxify_data_dir(), "col.vtr")

# Check what columns exist in the backbone
sample <- vectra::tbl(bb_path) |>
  vectra::filter(canonicalName == "Quercus robur") |>
  utils::head(3L) |>
  vectra::collect()

cat("Columns in COL backbone:\n")
print(names(sample))
cat("\nSample row:\n")
print(sample[1, ])

# Check if family column exists
cat("\n'family' in columns:", "family" %in% names(sample), "\n")
if ("family" %in% names(sample)) {
  cat("family value:", sample$family[1], "\n")
}

# Look for family-like columns
family_cols <- grep("family|Family", names(sample), value = TRUE)
cat("Family-like columns:", paste(family_cols, collapse = ", "), "\n")

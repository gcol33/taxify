setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

# Trace the full pipeline for the 3 synonym test names
names <- c("Pinus abies", "Quercus pedunculata", "Centaurea jacea")
bb_path <- file.path(taxify_data_dir(), "wfo.vtr")
be <- resolve_backend("wfo")

# Step 1: clean
names_df <- clean_names(names)
cat("Cleaned names:\n")
print(names_df)

# Step 2: exact match
result <- taxify:::match_exact(be, names_df, bb_path)
cat("\nAfter exact match:\n")
print(result[, c("input_name", "matched_name", "taxon_id", "taxonomicStatus",
                  "accepted_id_raw")])

# Step 3: resolve synonyms
result2 <- taxify:::resolve_synonyms(be, result, bb_path)
cat("\nAfter synonym resolution:\n")
print(result2[, c("input_name", "matched_name", "accepted_name", "accepted_id",
                   "is_synonym")])

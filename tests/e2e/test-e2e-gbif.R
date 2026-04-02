# End-to-end test: GBIF backend with real backbone

cat("=== taxify end-to-end test: GBIF backend ===\n\n")

# --- 1. Download backbone ---
cat("--- Step 1: Download GBIF backbone ---\n")
t0 <- Sys.time()
path <- taxify_download("gbif")
cat(sprintf("  Downloaded in %.1f minutes\n", difftime(Sys.time(), t0, units = "mins")))
cat(sprintf("  Path: %s\n", path))
cat(sprintf("  Size: %.0f MB\n\n", file.size(path) / 1024^2))


# --- 2. Basic exact matching ---
cat("--- Step 2: Basic exact matching ---\n")
basic_names <- c(
  "Quercus robur",
  "Panthera leo",
  "Salmo trutta",
  "Agaricus bisporus",    # fungus
  "Escherichia coli"      # bacterium
)

res <- taxify(basic_names, backend = "gbif", verbose = FALSE)
cat(sprintf("  Matched: %d / %d\n", sum(res$match_type != "none"), length(basic_names)))
for (i in seq_len(nrow(res))) {
  cat(sprintf("    %s -> %s (%s, %s)\n",
              res$input_name[i],
              ifelse(is.na(res$matched_name[i]), "NA", res$matched_name[i]),
              ifelse(is.na(res$family[i]), "NA", res$family[i]),
              res$match_type[i]))
}
cat("\n")


# --- 3. Synonym resolution ---
cat("--- Step 3: Synonym resolution ---\n")
synonym_names <- c(
  "Quercus pedunculata",   # synonym of Q. robur
  "Panthera leo"           # accepted (control)
)

res_syn <- taxify(synonym_names, backend = "gbif", verbose = FALSE)
for (i in seq_len(nrow(res_syn))) {
  cat(sprintf("  %s -> %s (synonym=%s)\n",
              res_syn$input_name[i], res_syn$accepted_name[i],
              res_syn$is_synonym[i]))
}
cat("\n")


# --- 4. Fuzzy matching ---
cat("--- Step 4: Fuzzy matching ---\n")
fuzzy_names <- c(
  "Quercus robor",    # typo
  "Panthera leo",     # exact
  "Salmo truta"       # typo
)

res_fuzzy <- taxify(fuzzy_names, backend = "gbif", verbose = FALSE)
for (i in seq_len(nrow(res_fuzzy))) {
  cat(sprintf("  %s -> %s (%s, dist=%.3f)\n",
              res_fuzzy$input_name[i],
              ifelse(is.na(res_fuzzy$matched_name[i]), "NA",
                     res_fuzzy$matched_name[i]),
              res_fuzzy$match_type[i],
              ifelse(is.na(res_fuzzy$fuzzy_dist[i]), 0,
                     res_fuzzy$fuzzy_dist[i])))
}
cat("\n")


# --- 5. Scale benchmark ---
cat("--- Step 5: Scale benchmark ---\n")
species_pool <- c(
  "Quercus robur", "Pinus sylvestris", "Fagus sylvatica",
  "Panthera leo", "Ursus arctos", "Canis lupus",
  "Aquila chrysaetos", "Salmo trutta", "Rosa canina",
  "Abies alba", "Picea abies", "Betula pendula"
)

set.seed(42)
bench_1k <- sample(species_pool, 1000, replace = TRUE)
t1 <- Sys.time()
res_1k <- taxify(bench_1k, backend = "gbif", fuzzy = FALSE, verbose = FALSE)
dt_1k <- difftime(Sys.time(), t1, units = "secs")
cat(sprintf("  1,000 names (exact only): %.1f sec (%.0f names/sec)\n",
            dt_1k, 1000 / as.numeric(dt_1k)))
cat(sprintf("    Matched: %d / %d\n",
            sum(res_1k$match_type != "none"), 1000))
cat("\n")


# --- 6. Output schema check ---
cat("--- Step 6: Output schema validation ---\n")
expected_cols <- c(
  "input_name", "matched_name", "accepted_name", "taxon_id",
  "accepted_id", "rank", "family", "genus", "epithet",
  "authorship", "is_synonym", "is_hybrid", "match_type",
  "fuzzy_dist", "backend", "backbone_version"
)
actual_cols <- names(res)
missing <- setdiff(expected_cols, actual_cols)
extra <- setdiff(actual_cols, expected_cols)
if (length(missing) == 0 && length(extra) == 0) {
  cat("  PASS: Schema matches expected 16 columns\n")
} else {
  if (length(missing) > 0) cat(sprintf("  MISSING: %s\n", paste(missing, collapse = ", ")))
  if (length(extra) > 0) cat(sprintf("  EXTRA: %s\n", paste(extra, collapse = ", ")))
}
cat(sprintf("  backbone_version: %s\n", res$backbone_version[1]))
cat("\n")


# --- 7. add_gbif_info() extension ---
cat("--- Step 7: add_gbif_info() ---\n")
res_ext <- taxify(c("Quercus robur", "Panthera leo"), backend = "gbif",
                  verbose = FALSE) |>
  add_gbif_info()
extra_cols <- setdiff(names(res_ext), expected_cols)
cat(sprintf("  Extra columns added: %s\n", paste(extra_cols, collapse = ", ")))
cat("\n")


cat("=== GBIF end-to-end test COMPLETE ===\n")

# End-to-end test: COL backend with real backbone

cat("=== taxify end-to-end test: COL backend ===\n\n")

# --- 1. Download backbone ---
cat("--- Step 1: Check COL backbone ---\n")
path <- file.path(taxify_data_dir(), "col.vtr")
if (!file.exists(path)) {
  t0 <- Sys.time()
  path <- taxify_download("col")
  cat(sprintf("  Downloaded in %.1f minutes\n", difftime(Sys.time(), t0, units = "mins")))
} else {
  cat("  Using existing backbone\n")
}
cat(sprintf("  Path: %s\n", path))
cat(sprintf("  Size: %.0f MB\n\n", file.size(path) / 1024^2))


# --- 2. Basic exact matching (plants) ---
cat("--- Step 2: Basic exact matching (plants) ---\n")
plant_names <- c(
  "Quercus robur",
  "Pinus sylvestris",
  "Fagus sylvatica",
  "Abies alba",
  "Rosa canina"
)

res_plants <- taxify(plant_names, backend = "col", verbose = FALSE)
cat(sprintf("  Matched: %d / %d\n", sum(res_plants$match_type != "none"),
            length(plant_names)))
for (i in seq_len(nrow(res_plants))) {
  cat(sprintf("    %s -> %s (%s, %s)\n",
              res_plants$input_name[i], res_plants$matched_name[i],
              res_plants$family[i], res_plants$match_type[i]))
}
cat("\n")


# --- 3. Animals (COL covers all kingdoms, unlike WFO) ---
cat("--- Step 3: Animal matching (COL multi-kingdom) ---\n")
animal_names <- c(
  "Panthera leo",          # lion
  "Ursus arctos",          # brown bear
  "Canis lupus",           # wolf
  "Aquila chrysaetos",     # golden eagle
  "Salmo trutta"           # brown trout
)

res_animals <- taxify(animal_names, backend = "col", verbose = FALSE)
cat(sprintf("  Matched: %d / %d\n", sum(res_animals$match_type != "none"),
            length(animal_names)))
for (i in seq_len(nrow(res_animals))) {
  cat(sprintf("    %s -> %s (%s, %s)\n",
              res_animals$input_name[i],
              ifelse(is.na(res_animals$matched_name[i]), "NA",
                     res_animals$matched_name[i]),
              ifelse(is.na(res_animals$family[i]), "NA", res_animals$family[i]),
              res_animals$match_type[i]))
}
cat("\n")


# --- 4. Synonym resolution ---
cat("--- Step 4: Synonym resolution ---\n")
synonym_names <- c(
  "Quercus pedunculata",   # synonym of Q. robur
  "Panthera leo"           # accepted (control)
)

res_syn <- taxify(synonym_names, backend = "col", verbose = FALSE)
for (i in seq_len(nrow(res_syn))) {
  cat(sprintf("  %s -> %s (synonym=%s)\n",
              res_syn$input_name[i], res_syn$accepted_name[i],
              res_syn$is_synonym[i]))
}
cat("\n")


# --- 5. Fuzzy matching ---
cat("--- Step 5: Fuzzy matching ---\n")
fuzzy_names <- c(
  "Quercus robor",    # typo
  "Panthera leo",     # exact (control)
  "Ursus arktos"      # typo
)

res_fuzzy <- taxify(fuzzy_names, backend = "col", verbose = FALSE)
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


# --- 6. add_col_info() extension ---
cat("--- Step 6: add_col_info() ---\n")
res_ext <- taxify(c("Quercus robur", "Panthera leo"), backend = "col",
                  verbose = FALSE) |>
  add_col_info()
expected_core <- c("input_name", "matched_name", "accepted_name", "taxon_id",
                   "accepted_id", "rank", "family", "genus", "epithet",
                   "authorship", "is_synonym", "is_hybrid", "match_type",
                   "fuzzy_dist", "backend", "backbone_version")
extra_cols <- setdiff(names(res_ext), expected_core)
cat(sprintf("  Extra columns added: %s\n", paste(extra_cols, collapse = ", ")))
cat("\n")


# --- 7. Scale benchmark ---
cat("--- Step 7: Scale benchmark ---\n")
species_pool <- c(
  "Quercus robur", "Pinus sylvestris", "Fagus sylvatica",
  "Panthera leo", "Ursus arctos", "Canis lupus",
  "Aquila chrysaetos", "Salmo trutta", "Rosa canina",
  "Abies alba", "Picea abies", "Betula pendula"
)

set.seed(42)
bench_1k <- sample(species_pool, 1000, replace = TRUE)
t1 <- Sys.time()
res_1k <- taxify(bench_1k, backend = "col", fuzzy = FALSE, verbose = FALSE)
dt_1k <- difftime(Sys.time(), t1, units = "secs")
cat(sprintf("  1,000 names (exact only): %.1f sec (%.0f names/sec)\n",
            dt_1k, 1000 / as.numeric(dt_1k)))
cat(sprintf("    Matched: %d / %d\n",
            sum(res_1k$match_type != "none"), 1000))
cat("\n")


# --- 8. Output schema check ---
cat("--- Step 8: Output schema validation ---\n")
actual_cols <- names(res_plants)
missing <- setdiff(expected_core, actual_cols)
extra <- setdiff(actual_cols, expected_core)
if (length(missing) == 0 && length(extra) == 0) {
  cat("  PASS: Schema matches expected 16 columns\n")
} else {
  if (length(missing) > 0) cat(sprintf("  MISSING: %s\n", paste(missing, collapse = ", ")))
  if (length(extra) > 0) cat(sprintf("  EXTRA: %s\n", paste(extra, collapse = ", ")))
}
cat(sprintf("  backbone_version: %s\n", res_plants$backbone_version[1]))
cat("\n")


cat("=== COL end-to-end test COMPLETE ===\n")

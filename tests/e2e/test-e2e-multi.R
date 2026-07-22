# End-to-end test: Multi-backbone fallback chain

cat("=== taxify end-to-end test: Multi-backbone fallback ===\n\n")

# --- 1. WFO → COL fallback ---
cat("--- Step 1: WFO -> COL fallback ---\n")
mixed_names <- c(
  "Quercus robur",         # plant — should match WFO
  "Pinus sylvestris",      # plant — should match WFO
  "Panthera leo",          # animal — WFO miss, COL should catch
  "Canis lupus",           # animal — WFO miss, COL should catch
  "Agaricus bisporus",     # fungus — WFO miss, COL should catch
  "xyzzy foobar"           # garbage — should be "none"
)

res <- taxify(mixed_names, backbone = c("wfo", "col"), verbose = TRUE)
cat("\nResults:\n")
for (i in seq_len(nrow(res))) {
  cat(sprintf("  %s -> %s (backbone=%s, match=%s)\n",
              res$input_name[i],
              ifelse(is.na(res$accepted_name[i]), "NA", res$accepted_name[i]),
              ifelse(is.na(res$backbone[i]), "NA", res$backbone[i]),
              res$match_type[i]))
}

# Check that plants went to WFO and animals to COL
stopifnot(res$backbone[1] == "wfo")  # Quercus
stopifnot(res$backbone[2] == "wfo")  # Pinus
stopifnot(res$backbone[3] == "col")  # Panthera
stopifnot(res$backbone[4] == "col")  # Canis
stopifnot(res$match_type[6] == "none")  # garbage
cat("PASS: Correct backbone assignment\n\n")


# --- 2. WFO → COL → GBIF triple fallback ---
cat("--- Step 2: WFO -> COL -> GBIF triple fallback ---\n")
res3 <- taxify(mixed_names, backbone = c("wfo", "col", "gbif"), verbose = TRUE)
cat("\nResults:\n")
for (i in seq_len(nrow(res3))) {
  cat(sprintf("  %s -> %s (backbone=%s)\n",
              res3$input_name[i],
              ifelse(is.na(res3$accepted_name[i]), "NA", res3$accepted_name[i]),
              ifelse(is.na(res3$backbone[i]), "NA", res3$backbone[i])))
}
cat("\n")


# --- 3. Schema consistency across backbones ---
cat("--- Step 3: Schema consistency ---\n")
expected_cols <- c(
  "input_name", "matched_name", "accepted_name", "taxon_id",
  "accepted_id", "rank", "family", "genus", "epithet",
  "authorship", "is_synonym", "is_hybrid", "match_type",
  "fuzzy_dist", "backbone", "backbone_version"
)
actual_cols <- names(res)
stopifnot(identical(sort(actual_cols), sort(expected_cols)))
cat("PASS: Multi-backbone output has correct 16-column schema\n\n")


# --- 4. backbone_version per-backbone ---
cat("--- Step 4: backbone_version column ---\n")
for (i in seq_len(nrow(res))) {
  cat(sprintf("  %s: backbone_version=%s\n",
              res$input_name[i],
              ifelse(is.na(res$backbone_version[i]), "NA",
                     res$backbone_version[i])))
}
cat("\n")


# --- 5. Scale benchmark (multi-backbone) ---
cat("--- Step 5: Scale benchmark (2-backbone) ---\n")
species_pool <- c(
  "Quercus robur", "Pinus sylvestris", "Fagus sylvatica",
  "Panthera leo", "Ursus arctos", "Canis lupus",
  "Aquila chrysaetos", "Salmo trutta", "Rosa canina"
)

set.seed(42)
bench_1k <- sample(species_pool, 1000, replace = TRUE)
t1 <- Sys.time()
res_bench <- taxify(bench_1k, backbone = c("wfo", "col"), fuzzy = FALSE,
                    verbose = FALSE)
dt <- difftime(Sys.time(), t1, units = "secs")
cat(sprintf("  1,000 names (wfo+col, exact only): %.1f sec\n", dt))
cat(sprintf("    Matched: %d / %d\n",
            sum(res_bench$match_type != "none"), 1000))

# Count per backbone
cat(sprintf("    WFO: %d, COL: %d, None: %d\n",
            sum(res_bench$backbone == "wfo", na.rm = TRUE),
            sum(res_bench$backbone == "col", na.rm = TRUE),
            sum(res_bench$match_type == "none")))
cat("\n")


cat("=== Multi-backbone end-to-end test COMPLETE ===\n")

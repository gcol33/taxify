# ASAAS validation: compare taxify results against known WFO matches
#
# Uses the curated ASAAS species-to-WFO mapping as ground truth.
# This dataset was hand-cleaned and verified during the ASAAS data prep.
#
# Run with:
#   setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
#   devtools::load_all()
#   source("tests/e2e/test-asaas-validation.R")

asaas_path <- "J:/Phd Local/Gilles_paper2/Data/ASAAS/Data prep/05_Taxa_WFO/02_eva_one_to_one_wfo_clean.csv"
if (!file.exists(asaas_path)) {
  stop("ASAAS data not found at: ", asaas_path,
       "\nThis test requires access to the J: drive (Phd Local).")
}

cat("=== ASAAS Validation Test ===\n\n")

# --- 1. Load ground truth ---
cat("--- Loading ASAAS ground truth ---\n")
truth <- utils::read.csv(asaas_path, stringsAsFactors = FALSE)
cat(sprintf("  %d unique species in ASAAS\n", nrow(truth)))
cat(sprintf("  Columns: %s\n\n", paste(names(truth), collapse = ", ")))

# --- 2. Subset selection ---
# Take a stratified sample: some exact, some synonyms (EVA != WFO), some hybrids,
# some infraspecific, plus a random sample for breadth.

is_synonym    <- truth$EVA_TAXON != truth$WFO_TAXON & !is.na(truth$WFO_TAXON)
is_hybrid     <- grepl("\u00d7| x |^x ", truth$EVA_TAXON, ignore.case = FALSE)
is_infraspec  <- grepl("subsp\\.|var\\.|f\\.", truth$EVA_TAXON)
has_na_wfo    <- is.na(truth$WFO_TAXON) | truth$WFO_TAXON == ""

set.seed(42)
n_per_group <- 200

idx_synonym   <- sample(which(is_synonym & !is_hybrid), min(n_per_group, sum(is_synonym & !is_hybrid)))
idx_hybrid    <- sample(which(is_hybrid), min(n_per_group, sum(is_hybrid)))
idx_infraspec <- sample(which(is_infraspec & !is_synonym), min(n_per_group, sum(is_infraspec & !is_synonym)))
idx_exact     <- sample(which(!is_synonym & !is_hybrid & !is_infraspec & !has_na_wfo),
                        min(n_per_group, sum(!is_synonym & !is_hybrid & !is_infraspec & !has_na_wfo)))
idx_random    <- sample(nrow(truth), min(500, nrow(truth)))

all_idx <- sort(unique(c(idx_synonym, idx_hybrid, idx_infraspec, idx_exact, idx_random)))
subset <- truth[all_idx, ]

cat(sprintf("--- Subset: %d names ---\n", nrow(subset)))
cat(sprintf("  Synonyms (EVA != WFO):  %d\n", sum(is_synonym[all_idx], na.rm = TRUE))  )
cat(sprintf("  Hybrids:                %d\n", sum(is_hybrid[all_idx], na.rm = TRUE)))
cat(sprintf("  Infraspecific:          %d\n", sum(is_infraspec[all_idx], na.rm = TRUE)))
cat(sprintf("  Exact (same name):      %d\n\n",
            sum(!is_synonym[all_idx] & !is_hybrid[all_idx] & !is_infraspec[all_idx] & !has_na_wfo[all_idx], na.rm = TRUE)))

# --- 3. Run taxify ---
cat("--- Running taxify (exact + fuzzy) ---\n")
t0 <- Sys.time()
res <- taxify(subset$EVA_TAXON, backend = "wfo", fuzzy = TRUE, verbose = FALSE)
dt <- difftime(Sys.time(), t0, units = "secs")
cat(sprintf("  %d names matched in %.1f sec (%.0f names/sec)\n\n",
            nrow(res), dt, nrow(res) / as.numeric(dt)))

# --- 4. Compare against ground truth ---
cat("--- Comparing against ground truth ---\n")

# Merge results with truth
comp <- data.frame(
  eva_taxon     = subset$EVA_TAXON,
  wfo_expected  = subset$WFO_TAXON,
  wfo_family    = subset$WFO_FAMILY,
  wfo_genus     = subset$WFO_GENUS,
  wfo_rank      = subset$WFO_TAXON_RANK,
  wfo_id        = subset$WFO_ID,
  # taxify results
  tx_accepted   = res$accepted_name,
  tx_matched    = res$matched_name,
  tx_family     = res$family,
  tx_genus      = res$genus,
  tx_match_type = res$match_type,
  tx_is_synonym = res$is_synonym,
  tx_fuzzy_dist = res$fuzzy_dist,
  tx_taxon_id   = res$taxon_id,
  stringsAsFactors = FALSE
)

# Classification: how well did taxify agree with ASAAS ground truth?

# 4a. Match rate
matched <- comp$tx_match_type != "none" & !is.na(comp$tx_match_type)
cat(sprintf("  Match rate:         %d / %d (%.1f%%)\n",
            sum(matched), nrow(comp), 100 * mean(matched)))

# 4b. Accepted name agreement (where both have a result)
has_both <- matched & !is.na(comp$wfo_expected) & comp$wfo_expected != ""
name_agree <- comp$tx_accepted == comp$wfo_expected
cat(sprintf("  Accepted name match: %d / %d (%.1f%%)\n",
            sum(name_agree[has_both], na.rm = TRUE), sum(has_both),
            100 * mean(name_agree[has_both], na.rm = TRUE)))

# 4c. Family agreement
fam_agree <- comp$tx_family == comp$wfo_family
cat(sprintf("  Family match:       %d / %d (%.1f%%)\n",
            sum(fam_agree[has_both], na.rm = TRUE), sum(has_both),
            100 * mean(fam_agree[has_both], na.rm = TRUE)))

# 4d. Genus agreement
gen_agree <- comp$tx_genus == comp$wfo_genus
cat(sprintf("  Genus match:        %d / %d (%.1f%%)\n",
            sum(gen_agree[has_both], na.rm = TRUE), sum(has_both),
            100 * mean(gen_agree[has_both], na.rm = TRUE)))

# 4e. WFO ID agreement
id_agree <- comp$tx_taxon_id == comp$wfo_id
cat(sprintf("  WFO ID match:       %d / %d (%.1f%%)\n\n",
            sum(id_agree[has_both], na.rm = TRUE), sum(has_both),
            100 * mean(id_agree[has_both], na.rm = TRUE)))

# --- 5. Disagreement analysis ---
cat("--- Disagreements (accepted name differs) ---\n")

disagree_idx <- which(has_both & !name_agree & matched)
if (length(disagree_idx) > 0) {
  cat(sprintf("  %d disagreements found. Showing first 30:\n\n", length(disagree_idx)))
  show_n <- min(30, length(disagree_idx))
  for (j in disagree_idx[seq_len(show_n)]) {
    cat(sprintf("  INPUT:    %s\n", comp$eva_taxon[j]))
    cat(sprintf("  EXPECTED: %s (family=%s, id=%s)\n",
                comp$wfo_expected[j], comp$wfo_family[j], comp$wfo_id[j]))
    cat(sprintf("  GOT:      %s (family=%s, id=%s, match=%s, dist=%.3f)\n\n",
                comp$tx_accepted[j], comp$tx_family[j], comp$tx_taxon_id[j],
                comp$tx_match_type[j],
                ifelse(is.na(comp$tx_fuzzy_dist[j]), 0, comp$tx_fuzzy_dist[j])))
  }
} else {
  cat("  None! Perfect agreement.\n\n")
}

# --- 6. Unmatched analysis ---
cat("--- Unmatched names ---\n")
unmatched_idx <- which(!matched & !is.na(comp$wfo_expected) & comp$wfo_expected != "")
if (length(unmatched_idx) > 0) {
  cat(sprintf("  %d names unmatched by taxify but have ASAAS WFO match. Showing first 20:\n\n",
              length(unmatched_idx)))
  show_n <- min(20, length(unmatched_idx))
  for (j in unmatched_idx[seq_len(show_n)]) {
    cat(sprintf("  %s -> expected: %s\n", comp$eva_taxon[j], comp$wfo_expected[j]))
  }
} else {
  cat("  All names with ASAAS ground truth were matched by taxify.\n")
}

# --- 7. Match type breakdown ---
cat("\n--- Match type breakdown ---\n")
type_tbl <- table(comp$tx_match_type, useNA = "ifany")
for (nm in names(type_tbl)) {
  cat(sprintf("  %-10s %d (%.1f%%)\n", nm, type_tbl[nm], 100 * type_tbl[nm] / nrow(comp)))
}

# --- 8. Full-dataset run (optional, all 34k names) ---
cat("\n--- Full ASAAS validation (all 34k names, exact only) ---\n")
t1 <- Sys.time()
res_full <- taxify(truth$EVA_TAXON, backend = "wfo", fuzzy = FALSE, verbose = FALSE)
dt_full <- difftime(Sys.time(), t1, units = "secs")
matched_full <- res_full$match_type != "none" & !is.na(res_full$match_type)
has_truth <- !is.na(truth$WFO_TAXON) & truth$WFO_TAXON != ""
agree_full <- res_full$accepted_name == truth$WFO_TAXON

cat(sprintf("  %d names in %.1f sec (%.0f names/sec)\n", nrow(truth), dt_full,
            nrow(truth) / as.numeric(dt_full)))
cat(sprintf("  Match rate:          %d / %d (%.1f%%)\n",
            sum(matched_full), nrow(truth), 100 * mean(matched_full)))
cat(sprintf("  Accepted name agree: %d / %d (%.1f%%)\n",
            sum(agree_full[has_truth & matched_full], na.rm = TRUE),
            sum(has_truth & matched_full),
            100 * mean(agree_full[has_truth & matched_full], na.rm = TRUE)))

cat("\n=== ASAAS Validation COMPLETE ===\n")

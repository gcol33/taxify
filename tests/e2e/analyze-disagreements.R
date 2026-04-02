# Detailed disagreement analysis from ASAAS validation
setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

truth <- utils::read.csv(
  "J:/Phd Local/Gilles_paper2/Data/ASAAS/Data prep/05_Taxa_WFO/02_eva_one_to_one_wfo_clean.csv",
  stringsAsFactors = FALSE
)

# Same subset as validation
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

res <- taxify(subset$EVA_TAXON, backend = "wfo", fuzzy = TRUE, verbose = FALSE)

comp <- data.frame(
  eva = subset$EVA_TAXON,
  wfo_expected = subset$WFO_TAXON,
  wfo_id = subset$WFO_ID,
  tx_accepted = res$accepted_name,
  tx_matched = res$matched_name,
  tx_id = res$taxon_id,
  tx_type = res$match_type,
  tx_dist = res$fuzzy_dist,
  tx_synonym = res$is_synonym,
  stringsAsFactors = FALSE
)

matched <- comp$tx_type != "none" & !is.na(comp$tx_type)
has_both <- matched & !is.na(comp$wfo_expected) & comp$wfo_expected != ""
disagree <- has_both & comp$tx_accepted != comp$wfo_expected

cat(sprintf("\n=== %d DISAGREEMENTS ===\n\n", sum(disagree)))

d <- comp[disagree, ]

# Classify each disagreement
d$category <- NA_character_

# 1. Hybrid × encoding (Ã in result)
d$category[grepl("\u00c3", d$tx_accepted) | grepl("\u00c3", d$tx_matched)] <- "hybrid_encoding"

# 2. Same WFO ID but different name (synonym resolution path differs)
d$category[is.na(d$category) & d$tx_id == d$wfo_id] <- "same_id_diff_name"

# 3. Hybrid names where × was stripped (input has ×, result doesn't)
d$category[is.na(d$category) & grepl("\u00d7| x |^x ", d$eva)] <- "hybrid_mismatch"

# 4. Expected is genus-only (single word)
d$category[is.na(d$category) & !grepl(" ", d$wfo_expected)] <- "expected_genus"

# 5. Fuzzy matched wrong species
d$category[is.na(d$category) & d$tx_type == "fuzzy"] <- "wrong_fuzzy"

# 6. Exact matched different synonym path
d$category[is.na(d$category) & d$tx_type == "exact"] <- "diff_synonym_path"

# Remaining
d$category[is.na(d$category)] <- "other"

cat("--- Category counts ---\n")
print(table(d$category))

for (cat_name in sort(unique(d$category))) {
  cat(sprintf("\n\n=== %s (%d) ===\n", toupper(cat_name), sum(d$category == cat_name)))
  sub <- d[d$category == cat_name, ]
  for (i in seq_len(nrow(sub))) {
    cat(sprintf("\n  IN:  %s\n  EXP: %s (id=%s)\n  GOT: %s (id=%s, match=%s, dist=%s, syn=%s)\n",
                sub$eva[i], sub$wfo_expected[i], sub$wfo_id[i],
                sub$tx_accepted[i], sub$tx_id[i], sub$tx_type[i],
                ifelse(is.na(sub$tx_dist[i]), "NA", sprintf("%.3f", sub$tx_dist[i])),
                sub$tx_synonym[i]))
  }
}

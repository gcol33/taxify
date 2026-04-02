# End-to-end test: WFO backend with real backbone
#
# Run with:
#   Rscript tests/e2e/test-e2e-wfo.R
#
# Requires internet connection for first download.

cat("=== taxify end-to-end test: WFO backend ===\n\n")

# --- 1. Download backbone ---
cat("--- Step 1: Download WFO backbone ---\n")
t0 <- Sys.time()
path <- taxify_download("wfo")
cat(sprintf("  Downloaded in %.1f minutes\n", difftime(Sys.time(), t0, units = "mins")))
cat(sprintf("  Path: %s\n", path))
cat(sprintf("  Size: %.0f MB\n\n", file.size(path) / 1024^2))


# --- 2. Basic exact matching ---
cat("--- Step 2: Basic exact matching ---\n")
basic_names <- c(
  "Quercus robur",        # common tree, accepted
  "Pinus sylvestris",     # common tree, accepted
  "Fagus sylvatica",      # common tree, accepted
  "Abies alba",           # common tree, accepted
  "Picea abies",          # common tree, accepted
  "Betula pendula",       # common tree, accepted
  "Rosa canina",          # shrub, accepted
  "Taraxacum officinale", # herb, accepted
  "Plantago major",       # herb, accepted
  "Achillea millefolium"  # herb, accepted
)

res <- taxify(basic_names, backend = "wfo", verbose = FALSE)
cat(sprintf("  Matched: %d / %d\n", sum(res$match_type != "none"), length(basic_names)))

# All should be exact matches
stopifnot(all(res$match_type == "exact"))
# All should have family, genus, epithet filled
stopifnot(all(!is.na(res$family)))
stopifnot(all(!is.na(res$genus)))
stopifnot(all(!is.na(res$epithet)))
cat("  PASS: All 10 common species matched exactly\n\n")


# --- 3. Synonym resolution ---
cat("--- Step 3: Synonym resolution ---\n")
synonym_names <- c(
  "Quercus pedunculata",   # synonym of Quercus robur
  "Senecio vulgaris",      # accepted (control)
  "Centaurea jacea"        # accepted (control)
)

res_syn <- taxify(synonym_names, backend = "wfo", verbose = FALSE)
cat(sprintf("  Matched: %d / %d\n", sum(res_syn$match_type != "none"), length(synonym_names)))

# Check synonym resolution
for (i in seq_len(nrow(res_syn))) {
  cat(sprintf("  %s -> %s (synonym=%s, match=%s)\n",
              res_syn$input_name[i], res_syn$accepted_name[i],
              res_syn$is_synonym[i], res_syn$match_type[i]))
}
cat("\n")


# --- 4. Fuzzy matching (typos) ---
cat("--- Step 4: Fuzzy matching ---\n")
fuzzy_names <- c(
  "Quercus robor",       # typo: robor -> robur
  "Pinus sylvestrus",    # typo: sylvestrus -> sylvestris
  "Fagus silvatica",     # old spelling: silvatica -> sylvatica
  "Betula pubescens",    # valid, should be exact
  "Querkus robur"        # typo in genus: Querkus -> Quercus
)

res_fuzzy <- taxify(fuzzy_names, backend = "wfo", verbose = FALSE)
for (i in seq_len(nrow(res_fuzzy))) {
  cat(sprintf("  %s -> %s (match=%s, dist=%.3f)\n",
              res_fuzzy$input_name[i],
              ifelse(is.na(res_fuzzy$matched_name[i]), "NA", res_fuzzy$matched_name[i]),
              res_fuzzy$match_type[i],
              ifelse(is.na(res_fuzzy$fuzzy_dist[i]), 0, res_fuzzy$fuzzy_dist[i])))
}
cat("\n")


# --- 5. ASAAS edge cases ---
cat("--- Step 5: ASAAS edge cases ---\n")

# 5a. Hybrid notation
hybrid_names <- c(
  "\u00d7 Festulolium",           # Unicode × nothogenus
  "x Festulolium",                # ASCII x nothogenus
  "Quercus \u00d7 hispanica",     # Unicode × nothospecies
  "Salix x fragilis",             # ASCII x nothospecies
  "Mentha aquatica x M. spicata"  # hybrid formula (may not be in WFO)
)

res_hybrid <- taxify(hybrid_names, backend = "wfo", verbose = FALSE)
for (i in seq_len(nrow(res_hybrid))) {
  cat(sprintf("  %s -> %s (hybrid=%s, match=%s)\n",
              res_hybrid$input_name[i],
              ifelse(is.na(res_hybrid$matched_name[i]), "NA", res_hybrid$matched_name[i]),
              res_hybrid$is_hybrid[i],
              res_hybrid$match_type[i]))
}
# All should be detected as hybrids
stopifnot(all(res_hybrid$is_hybrid))
cat("  PASS: All hybrids detected\n\n")

# 5b. Names with authorship (should be stripped)
author_names <- c(
  "Quercus robur L.",
  "Pinus sylvestris L.",
  "Fagus sylvatica L.",
  "Betula pendula Roth",
  "Rosa canina L. ex Sm."
)

res_auth <- taxify(author_names, backend = "wfo", verbose = FALSE)
cat("  Names with authorship:\n")
for (i in seq_len(nrow(res_auth))) {
  cat(sprintf("    %s -> %s (match=%s)\n",
              res_auth$input_name[i], res_auth$matched_name[i],
              res_auth$match_type[i]))
}
# All should match (authorship stripped during cleaning)
stopifnot(all(res_auth$match_type %in% c("exact", "exact_ci")))
cat("  PASS: All names with authorship matched\n\n")

# 5c. Names with qualifiers
qualifier_names <- c(
  "Quercus cf. robur",
  "Pinus aff. sylvestris",
  "Taraxacum sp.",
  "Rosa spp.",
  "Betula pendula subsp. pendula"
)

res_qual <- taxify(qualifier_names, backend = "wfo", verbose = FALSE)
cat("  Names with qualifiers:\n")
for (i in seq_len(nrow(res_qual))) {
  cat(sprintf("    %s -> %s (match=%s)\n",
              res_qual$input_name[i],
              ifelse(is.na(res_qual$matched_name[i]), "NA", res_qual$matched_name[i]),
              res_qual$match_type[i]))
}
cat("\n")

# 5d. Encoding edge cases
encoding_names <- c(
  "Picea abies",          # ASCII only (control)
  "Acer pseudoplatanus",  # ASCII only
  "Sorbus aucuparia"      # ASCII only
)
# Note: actual mojibake testing requires bad-encoded input files.
# For now, test that Latin-1 author names in the backbone don't cause issues.

res_enc <- taxify(encoding_names, backend = "wfo", verbose = FALSE)
stopifnot(all(res_enc$match_type == "exact"))
cat("  PASS: Encoding test (ASCII names matched)\n\n")

# 5e. Edge cases: empty, NA, garbage
edge_names <- c(
  NA,                   # NA input

  "",                   # empty string
  "   ",               # whitespace only
  "Quercus robur",     # valid (control)
  "xyzzy foobar",      # garbage
  "42"                  # number only
)

res_edge <- taxify(edge_names, backend = "wfo", verbose = FALSE)
cat("  Edge cases:\n")
for (i in seq_len(nrow(res_edge))) {
  cat(sprintf("    '%s' -> match=%s\n",
              ifelse(is.na(res_edge$input_name[i]), "NA", res_edge$input_name[i]),
              res_edge$match_type[i]))
}
# Quercus robur should match, rest should be "none" or have NA input
stopifnot(res_edge$match_type[4] == "exact")
cat("  PASS: Edge cases handled\n\n")


# --- 6. Scale benchmark ---
cat("--- Step 6: Scale benchmark ---\n")

# Generate realistic name list by repeating known names + adding noise
set.seed(42)
species_pool <- c(
  "Quercus robur", "Pinus sylvestris", "Fagus sylvatica",
  "Abies alba", "Picea abies", "Betula pendula",
  "Rosa canina", "Taraxacum officinale", "Plantago major",
  "Achillea millefolium", "Acer pseudoplatanus", "Sorbus aucuparia",
  "Fraxinus excelsior", "Tilia cordata", "Ulmus glabra",
  "Carpinus betulus", "Populus tremula", "Salix caprea",
  "Alnus glutinosa", "Corylus avellana", "Quercus petraea",
  "Acer campestre", "Prunus avium", "Malus sylvestris",
  "Pyrus pyraster", "Crataegus monogyna", "Sambucus nigra",
  "Viburnum opulus", "Cornus sanguinea", "Ligustrum vulgare",
  "Hedera helix", "Clematis vitalba", "Rubus fruticosus",
  "Vaccinium myrtillus", "Calluna vulgaris", "Erica tetralix",
  "Deschampsia flexuosa", "Festuca ovina", "Agrostis capillaris",
  "Luzula campestris", "Carex sylvatica", "Juncus effusus",
  "Galium odoratum", "Oxalis acetosella", "Anemone nemorosa",
  "Primula vulgaris", "Digitalis purpurea", "Geranium robertianum",
  "Stellaria holostea", "Veronica chamaedrys"
)

# 1000 names
bench_1k <- sample(species_pool, 1000, replace = TRUE)
t1 <- Sys.time()
res_1k <- taxify(bench_1k, backend = "wfo", fuzzy = FALSE, verbose = FALSE)
dt_1k <- difftime(Sys.time(), t1, units = "secs")
cat(sprintf("  1,000 names (exact only): %.1f sec (%.0f names/sec)\n",
            dt_1k, 1000 / as.numeric(dt_1k)))
cat(sprintf("    Matched: %d / %d\n",
            sum(res_1k$match_type != "none"), 1000))

# 1000 names with fuzzy
t2 <- Sys.time()
res_1kf <- taxify(bench_1k, backend = "wfo", fuzzy = TRUE, verbose = FALSE)
dt_1kf <- difftime(Sys.time(), t2, units = "secs")
cat(sprintf("  1,000 names (with fuzzy): %.1f sec\n", dt_1kf))

# 10000 names
bench_10k <- sample(species_pool, 10000, replace = TRUE)
t3 <- Sys.time()
res_10k <- taxify(bench_10k, backend = "wfo", fuzzy = FALSE, verbose = FALSE)
dt_10k <- difftime(Sys.time(), t3, units = "secs")
cat(sprintf("  10,000 names (exact only): %.1f sec (%.0f names/sec)\n",
            dt_10k, 10000 / as.numeric(dt_10k)))
cat(sprintf("    Matched: %d / %d\n",
            sum(res_10k$match_type != "none"), 10000))

cat("\n")


# --- 7. Output schema check ---
cat("--- Step 7: Output schema validation ---\n")
expected_cols <- c(
  "input_name", "matched_name", "accepted_name", "taxon_id",
  "accepted_id", "rank", "family", "genus", "epithet",
  "authorship", "is_synonym", "is_hybrid", "match_type",
  "fuzzy_dist", "backend", "backbone_version"
)
actual_cols <- names(res)
missing <- setdiff(expected_cols, actual_cols)
extra <- setdiff(actual_cols, expected_cols)
if (length(missing) > 0) cat(sprintf("  MISSING columns: %s\n", paste(missing, collapse = ", ")))
if (length(extra) > 0) cat(sprintf("  EXTRA columns: %s\n", paste(extra, collapse = ", ")))
if (length(missing) == 0 && length(extra) == 0) cat("  PASS: Schema matches expected 16 columns\n")
cat(sprintf("  backbone_version: %s\n", res$backbone_version[1]))
cat("\n")


# --- 8. add_wfo_info() extension ---
cat("--- Step 8: add_wfo_info() ---\n")
res_ext <- taxify(c("Quercus robur", "Pinus sylvestris"), backend = "wfo",
                  verbose = FALSE) |>
  add_wfo_info()
extra_cols <- setdiff(names(res_ext), expected_cols)
cat(sprintf("  Extra columns added: %s\n", paste(extra_cols, collapse = ", ")))
cat("\n")


# --- Summary ---
cat("=== WFO end-to-end test COMPLETE ===\n")
cat(sprintf("  All basic assertions passed\n"))
cat(sprintf("  Backbone path: %s\n", path))

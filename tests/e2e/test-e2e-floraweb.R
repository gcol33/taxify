# End-to-end test: add_floraweb() attaches German-flora plant traits (BiolFlor
# via FloraWeb) to the correct accepted taxon and is invariant to batch
# composition. Also checks that add_biolflor() is a deprecated alias.
#
# Run with:
#   Rscript tests/e2e/test-e2e-floraweb.R
#
# Requires the WFO backbone and the floraweb enrichment (downloaded on first
# run; needs internet only then).

cat("=== taxify end-to-end test: add_floraweb() join correctness ===\n\n")

cat("--- Step 1: WFO backbone ---\n")
path <- tryCatch(
  taxify_download("wfo"),
  error = function(e) {
    cat("  SKIP: WFO backbone unavailable (", conditionMessage(e), ")\n", sep = "")
    quit(save = "no", status = 0)
  }
)
cat(sprintf("  Backbone: %s\n\n", path))

cat("--- Step 2: resolve + add_floraweb ---\n")
species <- c(
  "Bellis perennis", "Achillea millefolium", "Quercus robur",
  "Calluna vulgaris", "Urtica dioica", "Pinus sylvestris"
)

enrich <- function(x) {
  r <- tryCatch(
    taxify(x, backend = "wfo", verbose = FALSE) |> add_floraweb(verbose = FALSE),
    error = function(e) {
      cat("  SKIP: floraweb enrichment unavailable (", conditionMessage(e),
          ")\n", sep = "")
      quit(save = "no", status = 0)
    }
  )
  data.frame(
    accepted_name = r$accepted_name,
    accepted_id   = r$accepted_id,
    life_form     = as.character(r$life_form_de),
    ploidy        = as.character(r$ploidy_de),
    chrom         = as.character(r$chromosome_number_de),
    light         = as.character(r$ell_light_de),
    strategy      = as.character(r$strategy_type_de),
    stringsAsFactors = FALSE
  )
}

solo <- do.call(rbind, lapply(species, enrich))
for (i in seq_len(nrow(solo))) {
  cat(sprintf("  %-20s -> ploidy=%s light=%s strategy=%s\n",
              species[i],
              ifelse(is.na(solo$ploidy[i]), "NA", solo$ploidy[i]),
              ifelse(is.na(solo$light[i]), "NA", solo$light[i]),
              ifelse(is.na(solo$strategy[i]), "NA", substr(solo$strategy[i], 1, 20))))
}
stopifnot(all(!is.na(solo$accepted_id)))
stopifnot(sum(!is.na(solo$ploidy)) >= 4L)
cat("  PASS: resolved and enriched\n\n")

cat("--- Step 3: solo vs shuffled-batch invariance ---\n")
set.seed(1)
batch <- enrich(sample(species))
cmp <- merge(solo, batch, by = "accepted_id", suffixes = c(".s", ".b"))
same <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
ok <- same(cmp$ploidy.s, cmp$ploidy.b) & same(cmp$light.s, cmp$light.b) &
      same(cmp$strategy.s, cmp$strategy.b) & same(cmp$chrom.s, cmp$chrom.b)
if (any(!ok)) print(cmp[!ok, ])
stopifnot(nrow(cmp) == length(species), all(ok))
cat("  PASS: every column identical solo vs in-batch\n\n")

cat("--- Step 4: known-truth anchors ---\n")
pick <- function(df, name) df[df$accepted_name == name, ][1, ]
bp <- pick(solo, "Bellis perennis")
am <- pick(solo, "Achillea millefolium")
cat(sprintf("  Bellis perennis:      ploidy=%s light=%s chrom=%s\n",
            bp$ploidy, bp$light, bp$chrom))
cat(sprintf("  Achillea millefolium: ploidy=%s\n", am$ploidy))
stopifnot(identical(bp$ploidy, "diploid"))           # daisy is diploid (2n=18)
stopifnot(identical(bp$light, "8"))                  # daisy Ellenberg light = 8
stopifnot(grepl("2n = 18", bp$chrom))                # chromosome field split cleanly
# Achillea millefolium must carry rich data (regression guard for the
# resolve_enrichment_names richest-record dedup fix)
stopifnot(!is.na(am$ploidy))
cat("  PASS: traits on the correct taxon; rich-record dedup holds\n\n")

cat("--- Step 5: add_biolflor() is a deprecated alias for add_floraweb() ---\n")
x <- taxify("Bellis perennis", backend = "wfo", verbose = FALSE)
warned <- FALSE
b <- withCallingHandlers(
  add_biolflor(x, verbose = FALSE),
  warning = function(w) {
    if (grepl("deprecat", conditionMessage(w), ignore.case = TRUE)) warned <<- TRUE
    invokeRestart("muffleWarning")
  }
)
stopifnot(warned)
stopifnot(all(c("life_form_de", "ploidy_de") %in% names(b)))
cat("  PASS: add_biolflor() warns and forwards to add_floraweb()\n\n")

cat("=== add_floraweb() join test COMPLETE ===\n")
cat("  All assertions passed\n")

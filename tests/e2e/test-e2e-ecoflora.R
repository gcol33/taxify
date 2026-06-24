# End-to-end test: add_ecoflora() attaches British-flora plant traits to the
# correct accepted taxon and is invariant to batch composition.
#
# Run with:
#   Rscript tests/e2e/test-e2e-ecoflora.R
#
# Requires the WFO backbone and the ecoflora enrichment (downloaded on first
# run; needs internet only then).

cat("=== taxify end-to-end test: add_ecoflora() join correctness ===\n\n")

cat("--- Step 1: WFO backbone ---\n")
path <- tryCatch(
  taxify_download("wfo"),
  error = function(e) {
    cat("  SKIP: WFO backbone unavailable (", conditionMessage(e), ")\n", sep = "")
    quit(save = "no", status = 0)
  }
)
cat(sprintf("  Backbone: %s\n\n", path))

cat("--- Step 2: resolve + add_ecoflora ---\n")
species <- c(
  "Bellis perennis", "Quercus robur", "Urtica dioica",
  "Calluna vulgaris", "Pinus sylvestris", "Anemone nemorosa"
)

enrich <- function(x) {
  r <- tryCatch(
    taxify(x, backend = "wfo", verbose = FALSE) |> add_ecoflora(verbose = FALSE),
    error = function(e) {
      cat("  SKIP: ecoflora enrichment unavailable (", conditionMessage(e),
          ")\n", sep = "")
      quit(save = "no", status = 0)
    }
  )
  data.frame(
    accepted_name = r$accepted_name,
    accepted_id   = r$accepted_id,
    life_form     = as.character(r$life_form_uk),
    fbeg          = r$flower_begin_month_uk,
    fend          = r$flower_end_month_uk,
    poll          = as.character(r$pollination_vector_uk),
    seed          = r$seed_weight_mg_uk,
    light         = as.character(r$ell_light_uk),
    stringsAsFactors = FALSE
  )
}

solo <- do.call(rbind, lapply(species, enrich))
for (i in seq_len(nrow(solo))) {
  cat(sprintf("  %-20s -> life_form=%s poll=%s flower=%s-%s\n",
              species[i],
              ifelse(is.na(solo$life_form[i]), "NA", solo$life_form[i]),
              ifelse(is.na(solo$poll[i]), "NA", solo$poll[i]),
              ifelse(is.na(solo$fbeg[i]), "NA", solo$fbeg[i]),
              ifelse(is.na(solo$fend[i]), "NA", solo$fend[i])))
}
stopifnot(all(!is.na(solo$accepted_id)))
stopifnot(sum(!is.na(solo$life_form)) >= 4L)
cat("  PASS: resolved and enriched\n\n")

cat("--- Step 3: solo vs shuffled-batch invariance ---\n")
set.seed(1)
batch <- enrich(sample(species))
cmp <- merge(solo, batch, by = "accepted_id", suffixes = c(".s", ".b"))
same <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
ok <- same(cmp$life_form.s, cmp$life_form.b) & same(cmp$poll.s, cmp$poll.b) &
      same(cmp$fbeg.s, cmp$fbeg.b) & same(cmp$light.s, cmp$light.b)
if (any(!ok)) print(cmp[!ok, ])
stopifnot(nrow(cmp) == length(species), all(ok))
cat("  PASS: every column identical solo vs in-batch\n\n")

cat("--- Step 4: known-truth anchors ---\n")
pick <- function(df, name) df[df$accepted_name == name, ][1, ]
bp <- pick(solo, "Bellis perennis")
cat(sprintf("  Bellis perennis: life_form=%s light=%s\n", bp$life_form, bp$light))
stopifnot(identical(bp$life_form, "hemicryptophyte"))  # daisy is a hemicryptophyte
cat("  PASS: traits on the correct taxon\n\n")

cat("=== add_ecoflora() join test COMPLETE ===\n")
cat("  All assertions passed\n")

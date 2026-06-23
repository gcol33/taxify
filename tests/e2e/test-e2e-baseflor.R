# End-to-end test: add_baseflor() attaches Catminat/Julve plant traits to the
# correct accepted taxon and is invariant to batch composition.
#
# Run with:
#   Rscript tests/e2e/test-e2e-baseflor.R
#
# Requires the WFO backbone and the baseflor enrichment (downloaded on first
# run; needs internet only then).

cat("=== taxify end-to-end test: add_baseflor() join correctness ===\n\n")

# --- 1. Backbone present (skip if unavailable) ---
cat("--- Step 1: WFO backbone ---\n")
path <- tryCatch(
  taxify_download("wfo"),
  error = function(e) {
    cat("  SKIP: WFO backbone unavailable (", conditionMessage(e), ")\n", sep = "")
    quit(save = "no", status = 0)
  }
)
cat(sprintf("  Backbone: %s\n\n", path))

# --- 2. Resolve + enrich a set of well-characterised European plants ---
cat("--- Step 2: resolve + add_baseflor ---\n")
species <- c(
  "Bellis perennis", "Quercus robur", "Taraxacum officinale",
  "Anemone nemorosa", "Pinus sylvestris", "Salix alba"
)

enrich <- function(x) {
  r <- tryCatch(
    taxify(x, backend = "wfo", verbose = FALSE) |> add_baseflor(),
    error = function(e) {
      cat("  SKIP: baseflor enrichment unavailable (", conditionMessage(e),
          ")\n", sep = "")
      quit(save = "no", status = 0)
    }
  )
  data.frame(
    accepted_name = r$accepted_name,
    accepted_id   = r$accepted_id,
    fbeg          = r$flower_begin_month,
    fend          = r$flower_end_month,
    poll          = as.character(r$pollination_vector),
    breed         = as.character(r$breeding_system),
    fruit         = as.character(r$fruit_type),
    stringsAsFactors = FALSE
  )
}

solo <- do.call(rbind, lapply(species, enrich))
for (i in seq_len(nrow(solo))) {
  cat(sprintf("  %-20s -> poll=%s breed=%s flower=%s-%s\n",
              species[i],
              ifelse(is.na(solo$poll[i]), "NA", solo$poll[i]),
              ifelse(is.na(solo$breed[i]), "NA", solo$breed[i]),
              ifelse(is.na(solo$fbeg[i]), "NA", solo$fbeg[i]),
              ifelse(is.na(solo$fend[i]), "NA", solo$fend[i])))
}
stopifnot(all(!is.na(solo$accepted_id)))
# At least most should carry baseflor data (French/European flora)
stopifnot(sum(!is.na(solo$poll)) >= 4L)
cat("  PASS: resolved and enriched\n\n")

# --- 3. Join is invariant to batch composition and order ---
cat("--- Step 3: solo vs shuffled-batch invariance ---\n")
set.seed(1)
batch <- enrich(sample(species))
cmp <- merge(solo, batch, by = "accepted_id", suffixes = c(".s", ".b"))
same <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
ok <- same(cmp$poll.s, cmp$poll.b) & same(cmp$breed.s, cmp$breed.b) &
      same(cmp$fbeg.s, cmp$fbeg.b) & same(cmp$fend.s, cmp$fend.b)
if (any(!ok)) print(cmp[!ok, ])
stopifnot(nrow(cmp) == length(species), all(ok))
cat("  PASS: every column identical solo vs in-batch\n\n")

# --- 4. Known-truth anchors land on the right species ---
cat("--- Step 4: known-truth anchors ---\n")
pick <- function(df, name) df[df$accepted_name == name, ][1, ]
qr <- pick(solo, "Quercus robur")
to <- pick(solo, "Taraxacum officinale")
cat(sprintf("  Quercus robur:        poll=%s breed=%s\n", qr$poll, qr$breed))
cat(sprintf("  Taraxacum officinale: poll=%s\n", to$poll))

stopifnot(identical(qr$poll, "wind"))           # oak is wind-pollinated
stopifnot(identical(qr$breed, "monoecious"))    # oak is monoecious
stopifnot(grepl("apogamy", to$poll))            # dandelion is apomictic
cat("  PASS: traits on the correct taxon\n\n")

cat("=== add_baseflor() join test COMPLETE ===\n")
cat("  All assertions passed\n")

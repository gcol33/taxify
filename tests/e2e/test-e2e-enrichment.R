# End-to-end test: enrichment joins attach to each row's own accepted taxon
#
# Run with:
#   Rscript tests/e2e/test-e2e-enrichment.R
#
# Regression guard for #1: add_iucn() and add_common_names()
# attached values from a neighbouring within-genus taxon (e.g. Quercus robur
# got the common name of Q. pyrenaica), while add_zanne() on the same rows
# was correct. A correct per-accepted_id join is invariant to batch composition
# and order, and lands the documented value on the right species. This checks
# both properties.
#
# Requires the WFO backbone and the conservation_status, common_names, and
# woodiness enrichments (downloaded on first run; needs internet only then).

cat("=== taxify end-to-end test: enrichment join correctness (#1) ===\n\n")

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

# --- 2. Resolve + enrich within-genus congeners ---
cat("--- Step 2: resolve + enrich within-genus congeners ---\n")
congeners <- c(
  "Pinus sylvestris", "Pinus nigra", "Pinus mugo",
  "Quercus robur", "Quercus petraea", "Quercus pyrenaica"
)

enrich <- function(x) {
  taxify(x, backend = "wfo", verbose = FALSE) |>
    add_iucn() |>
    add_common_names(lang = "en") |>
    add_zanne()
}
as_df <- function(r) data.frame(
  accepted_name = r$accepted_name,
  accepted_id   = r$accepted_id,
  status        = as.character(r$conservation_status),
  common        = as.character(r$common_name),
  woodiness     = as.character(r$woodiness),
  stringsAsFactors = FALSE
)

solo <- do.call(rbind, lapply(congeners, function(n) as_df(enrich(n))))
for (i in seq_len(nrow(solo))) {
  cat(sprintf("  %-18s -> %-14s status=%-3s common=%s\n",
              congeners[i], solo$accepted_id[i],
              ifelse(is.na(solo$status[i]), "NA", solo$status[i]),
              ifelse(is.na(solo$common[i]), "NA", solo$common[i])))
}
stopifnot(all(!is.na(solo$accepted_id)))
cat("  PASS: all congeners resolved to an accepted_id\n\n")

# --- 3. Join is invariant to batch composition and order ---
# Each species' common name is distinct, so the #1 within-genus shift would
# change a row's value when its congeners are present. Comparing the same
# species resolved alone against resolved inside a shuffled batch, joined by
# accepted_id (never row order), catches that.
cat("--- Step 3: solo vs shuffled-batch invariance ---\n")
set.seed(1)
shuffled <- sample(congeners)
batch <- as_df(enrich(shuffled))

cmp <- merge(solo, batch, by = "accepted_id", suffixes = c(".solo", ".batch"))
same <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
ok_status <- same(cmp$status.solo, cmp$status.batch)
ok_common <- same(cmp$common.solo, cmp$common.batch)
ok_wood   <- same(cmp$woodiness.solo, cmp$woodiness.batch)
bad <- !(ok_status & ok_common & ok_wood)
if (any(bad)) {
  cat("  MISMATCH (solo vs in-batch):\n")
  print(cmp[bad, c("accepted_id", "status.solo", "status.batch",
                   "common.solo", "common.batch")])
}
stopifnot(nrow(cmp) == length(congeners))
stopifnot(all(ok_status), all(ok_common), all(ok_wood))
cat("  PASS: every layer identical solo vs in-batch (no within-genus shift)\n\n")

# --- 4. Documented values land on the right species (issue #1 symptom) ---
cat("--- Step 4: known-truth anchors ---\n")
pick <- function(df, name) df[df$accepted_name == name, ][1, ]
ps <- pick(solo, "Pinus sylvestris")
qr <- pick(solo, "Quercus robur")
cat(sprintf("  Pinus sylvestris: status=%s common=%s\n", ps$status, ps$common))
cat(sprintf("  Quercus robur:    status=%s common=%s\n", qr$status, qr$common))

stopifnot(identical(ps$status, "LC"))                      # bug gave "EX"
stopifnot(grepl("Scots", ps$common, ignore.case = TRUE))  # bug gave "American Red Pine"
stopifnot(identical(qr$status, "LC"))                      # bug gave NA
stopifnot(!identical(qr$common, "Pyrenean Oak"))          # bug gave Q. pyrenaica's name
cat("  PASS: conservation_status + common_name on the correct taxon\n\n")

# --- 5. woodiness (the layer that was already correct) ---
cat("--- Step 5: woodiness control ---\n")
stopifnot(all(solo$woodiness == "woody"))
cat("  PASS: all six congeners woody\n\n")

cat("=== enrichment join test COMPLETE ===\n")
cat("  All assertions passed\n")

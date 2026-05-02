setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages({
  library(openxlsx2)
})

# ReptTraits structure
rept_path <- file.path(tempdir(), "taxify_enrichment_build", "lizard_traits",
                       "ReptTraits_v1-2.xlsx")
if (!file.exists(rept_path)) {
  # try cached from earlier inspection
  rept_path <- "C:/Users/Gilles Colling/AppData/Local/Temp/rept.xlsx"
}
if (file.exists(rept_path)) {
  cat(sprintf("=== ReptTraits XLSX (%.1f MB) ===\n",
              file.size(rept_path) / 1048576))
  sheets <- wb_get_sheet_names(wb_load(rept_path))
  cat(sprintf("sheets (%d): %s\n", length(sheets), paste(sheets, collapse = ", ")))
  for (s in sheets[seq_len(min(3L, length(sheets)))]) {
    df <- read_xlsx(rept_path, sheet = s, rows = 1:5)
    cat(sprintf("\n  sheet '%s': %d cols\n", s, ncol(df)))
    cat(sprintf("    cols: %s\n",
                paste(names(df)[seq_len(min(20L, ncol(df)))], collapse = " | ")))
    cat(sprintf("    sample row: %s\n",
                paste(unlist(df[1L, seq_len(min(5L, ncol(df)))]), collapse = " | ")))
  }
} else {
  cat("ReptTraits not found at", rept_path, "\n")
}

# LEDA plant_growth_form structure (note: downloaded as life_form.txt)
cat("\n\n=== LEDA life_form.txt (plant_growth_form upstream) ===\n")
leda_lf <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/_scratch/leda/life_form.txt"
if (file.exists(leda_lf)) {
  con <- file(leda_lf, encoding = "latin1")
  lines <- readLines(con, n = 10L, warn = FALSE)
  close(con)
  cat("first 10 lines:\n")
  for (i in seq_along(lines)) cat(sprintf("  L%d: %s\n", i, substr(lines[i], 1, 200)))

  # Now try to read after skipping preamble
  hits <- which(vapply(lines, function(l) {
    sum(charToRaw(l) == charToRaw(";")) >= 3L
  }, logical(1L)))
  if (length(hits) > 0L) {
    skip_n <- hits[1L] - 1L
    cat(sprintf("\nheader detected at line %d (skip=%d)\n", hits[1L], skip_n))
    df <- read.csv(leda_lf, sep = ";", stringsAsFactors = FALSE,
                   fileEncoding = "latin1", skip = skip_n,
                   check.names = FALSE, nrows = 5)
    cat(sprintf("  ncol: %d\n", ncol(df)))
    cat(sprintf("  cols: %s\n", paste(names(df)[1:min(15L,ncol(df))], collapse=" | ")))
  }
}

setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages(library(openxlsx2))

# Re-download to scratch dir for persistent inspection
scratch <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/_scratch/glonaf"
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)

base <- "https://zenodo.org/records/13235357/files/"
files <- c("glonaf_flora2.xlsx", "glonaf_taxon_wcvp.xlsx", "glonaf_region.xlsx")
for (f in files) {
  dest <- file.path(scratch, f)
  if (!file.exists(dest) || file.size(dest) < 100L) {
    h <- curl::new_handle()
    curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
    curl::handle_setheaders(h, "User-Agent" = "Mozilla/5.0 (compatible; taxify/0.5)")
    tryCatch(curl::curl_download(paste0(base, f, "?download=1"), dest, handle = h),
             error = function(e) cat(sprintf("download FAIL %s: %s\n", f, conditionMessage(e))))
  }
  if (file.exists(dest)) {
    cat(sprintf("OK %s (%.1f KB)\n", f, file.size(dest) / 1024))
  }
}

cat("\n=== schemas ===\n")
for (f in list.files(scratch, pattern = "\\.xlsx$", full.names = TRUE)) {
  cat(sprintf("\n--- %s ---\n", basename(f)))
  sheets <- wb_get_sheet_names(wb_load(f))
  cat(sprintf("  sheets: %s\n", paste(sheets, collapse = ", ")))
  for (s in sheets) {
    df <- tryCatch(read_xlsx(f, sheet = s, rows = 1:5), error = function(e) NULL)
    if (!is.null(df)) {
      cat(sprintf("  '%s': %d cols, %d sample rows\n", s, ncol(df), nrow(df)))
      cat(sprintf("    cols: %s\n",
                  paste(names(df)[seq_len(min(20L, ncol(df)))], collapse = " | ")))
      if (nrow(df) > 0L) {
        cat(sprintf("    sample row: %s\n",
                    paste(unlist(df[1L, seq_len(min(8L, ncol(df)))]),
                          collapse = " | ")))
      }
    }
  }
}

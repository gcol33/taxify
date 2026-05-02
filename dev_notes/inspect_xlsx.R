setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages(library(openxlsx2))

inspect <- function(path, label) {
  cat(sprintf("\n=== %s (%.2f MB) ===\n", label, file.size(path) / 1048576))
  wb <- wb_load(path)
  sheets <- wb_get_sheet_names(wb)
  cat(sprintf("sheets (%d): %s\n", length(sheets), paste(sheets, collapse = ", ")))
  for (s in sheets) {
    df <- tryCatch(read_xlsx(path, sheet = s, rows = 1:3), error = function(e) NULL)
    if (is.null(df)) {
      cat(sprintf("  sheet '%s': read failed\n", s))
      next
    }
    cat(sprintf("  sheet '%s': %d cols\n", s, ncol(df)))
    cat(sprintf("    cols: %s\n",
                paste(names(df)[seq_len(min(20L, ncol(df)))], collapse = " | ")))
  }
}

inspect("C:/Users/Gilles Colling/AppData/Local/Temp/ft4.xlsx", "FungalTraits MOESM4 (~1 MB)")
inspect("C:/Users/Gilles Colling/AppData/Local/Temp/ft5.xlsx", "FungalTraits MOESM5 (~58 MB)")

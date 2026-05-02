setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages(library(openxlsx2))

inspect <- function(path, label) {
  cat(sprintf("\n=== %s (%.1f MB) ===\n", label, file.size(path) / 1048576))
  wb <- wb_load(path)
  sheets <- wb_get_sheet_names(wb)
  cat(sprintf("sheets (%d): %s\n", length(sheets), paste(sheets, collapse = ", ")))
  for (s in sheets[seq_len(min(5L, length(sheets)))]) {
    df <- tryCatch(read_xlsx(path, sheet = s, rows = 1:3), error = function(e) NULL)
    if (!is.null(df)) {
      cat(sprintf("\n  '%s': %d cols\n", s, ncol(df)))
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

inspect("C:/Users/Gilles Colling/AppData/Local/Temp/diaz5.xlsx", "MOESM5")
inspect("C:/Users/Gilles Colling/AppData/Local/Temp/diaz7.xlsx", "MOESM7")
inspect("C:/Users/Gilles Colling/AppData/Local/Temp/diaz8.xlsx", "MOESM8")

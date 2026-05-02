setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all(quiet = TRUE)

# Recreate the read_leda_trait helper inline from the patched source
read_leda_trait <- function(path) {
  find_header_skip <- function(p, max_scan = 30L) {
    con <- file(p, encoding = "latin1")
    on.exit(close(con))
    lines <- readLines(con, n = max_scan, warn = FALSE)
    hits <- which(vapply(lines, function(l) {
      sum(charToRaw(l) == charToRaw(";")) >= 3L
    }, logical(1L)))
    if (length(hits) == 0L) return(0L)
    hits[1L] - 1L
  }

  tryCatch({
    skip_n <- find_header_skip(path)
    cat(sprintf("    skip=%d\n", skip_n))
    df <- read.csv(path, sep = ";", stringsAsFactors = FALSE,
                   fileEncoding = "latin1", skip = skip_n,
                   check.names = FALSE)
    if (ncol(df) <= 1L) {
      df <- read.delim(path, stringsAsFactors = FALSE,
                       fileEncoding = "latin1", skip = skip_n,
                       check.names = FALSE)
    }
    df
  }, error = function(e) {
    cat(sprintf("    ERR: %s\n", conditionMessage(e)))
    NULL
  })
}

leda_dir <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/_scratch/leda"

for (f in list.files(leda_dir, full.names = TRUE)) {
  cat(sprintf("\n=== %s (%.1f KB) ===\n", basename(f), file.size(f) / 1024))
  df <- read_leda_trait(f)
  if (is.null(df)) {
    cat("    df is NULL\n")
  } else {
    cat(sprintf("    rows: %d  cols: %d\n", nrow(df), ncol(df)))
    cat(sprintf("    names[1:8]: %s\n",
                paste(names(df)[seq_len(min(8L, ncol(df)))], collapse = " | ")))
  }
}

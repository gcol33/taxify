setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
})

# Test species spanning all rebuilt enrichments
tests <- list(
  woodiness     = c("Quercus robur", "Bellis perennis"),
  fungal_traits = c("Amanita muscaria", "Armillaria gallica"),  # genus-level
  leda          = c("Bellis perennis", "Quercus robur"),
  lizard_traits = c("Anolis carolinensis", "Lacerta agilis"),
  funguild      = c("Amanita", "Armillaria"),
  glonaf        = c("Acacia mearnsii", "Pinus contorta"),
  common_names  = c("Quercus robur", "Panthera tigris")
)

enr_path <- function(name) {
  file.path(taxify_data_dir(), "enrichment", name, "latest", paste0(name, ".vtr"))
}

cat("=== File sizes ===\n")
for (name in names(tests)) {
  p <- enr_path(name)
  sz <- if (file.exists(p)) file.size(p) / 1048576 else NA
  cat(sprintf("  %-15s  %s  %.2f MB\n",
              name, if (file.exists(p)) "OK" else "MISSING", sz))
}

cat("\n\n=== Quick query smoke test ===\n")
for (name in names(tests)) {
  cat(sprintf("\n--- %s ---\n", name))
  vtr <- enr_path(name)
  if (!file.exists(vtr)) { cat("  MISSING\n"); next }

  rows <- tryCatch(
    {
      df <- vectra::tbl(vtr) |> vectra::collect()
      df
    },
    error = function(e) { cat("  read FAIL:", conditionMessage(e), "\n"); NULL }
  )
  if (is.null(rows)) next

  cat(sprintf("  total rows: %d  cols: %d\n", nrow(rows), ncol(rows)))
  cat(sprintf("  cols: %s\n",
              paste(names(rows)[seq_len(min(8L, ncol(rows)))], collapse = ", ")))

  key <- if ("genus" %in% names(rows)) "genus" else
         if ("canonical_name" %in% names(rows)) "canonical_name" else
         names(rows)[1L]
  hits <- rows[rows[[key]] %in% tests[[name]], ]
  cat(sprintf("  matches for %s: %d\n",
              paste(tests[[name]], collapse = ", "), nrow(hits)))
  if (nrow(hits) > 0L) {
    print(utils::head(hits, 3L))
  }
}

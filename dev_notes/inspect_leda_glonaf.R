setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressPackageStartupMessages({
  library(openxlsx2)
  library(curl)
})

# Use a stable scratch dir so we can re-run inspection
scratch <- "C:/Users/Gilles Colling/Documents/dev/taxify/dev_notes/_scratch"
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)

dl <- function(url, dest) {
  if (file.exists(dest) && file.size(dest) > 100L) return(invisible(dest))
  h <- curl::new_handle()
  curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
  curl::handle_setheaders(h, "User-Agent" = "Mozilla/5.0")
  curl::curl_download(url, dest, handle = h)
}

# ------ LEDA ------
leda_dir <- file.path(scratch, "leda")
dir.create(leda_dir, recursive = TRUE, showWarnings = FALSE)
leda_base <- "https://uol.de/f/5/inst/biologie/ag/landeco/download/LEDA/Data_files/"
leda_files <- c(
  "life_form.txt"      = "plant_growth_form.txt",
  "dispersal_type.txt" = "dispersal_type.txt",
  "TV.txt"             = "TV_2016.txt",
  "seed_mass.txt"      = "seed_mass.txt",
  "canopy_height.txt"  = "canopy_height.txt",
  "leaf_mass.txt"      = "leaf_mass.txt",
  "SLA.txt"            = "SLA_und_geo_neu2.txt",
  "clonal_growth.txt"  = "CGO.txt",
  "buoyancy.txt"       = "buoyancy_2016.txt"
)
for (out_name in names(leda_files)) {
  upstream <- leda_files[[out_name]]
  dest <- file.path(leda_dir, out_name)
  tryCatch({
    dl(paste0(leda_base, upstream), dest)
    cat(sprintf("OK %s -> %s (%.1f KB)\n", upstream, out_name, file.size(dest) / 1024))
  }, error = function(e) {
    cat(sprintf("FAIL %s: %s\n", upstream, conditionMessage(e)))
  })
}

cat("\n=== LEDA: per-file encoding check ===\n")
for (f in list.files(leda_dir, full.names = TRUE)) {
  cat(sprintf("\n--- %s ---\n", basename(f)))
  bytes <- readBin(f, what = "raw", n = 200L)
  if (length(bytes) >= 3 && bytes[1] == as.raw(0xEF) && bytes[2] == as.raw(0xBB) && bytes[3] == as.raw(0xBF)) {
    cat("UTF-8 BOM\n")
  }
  for (enc in c("latin1", "UTF-8", "")) {
    ok <- tryCatch({
      df <- read.csv(f, sep = ";", nrows = 5, stringsAsFactors = FALSE,
                     fileEncoding = if (enc == "") NA_character_ else enc,
                     check.names = FALSE)
      cat(sprintf("  enc='%s' OK: %d cols, names: %s\n", enc, ncol(df),
                  paste(names(df)[1:min(6L,ncol(df))], collapse = "|")))
      TRUE
    }, error = function(e) {
      cat(sprintf("  enc='%s' FAIL: %s\n", enc, conditionMessage(e)))
      FALSE
    })
    if (ok) break
  }
}

# ------ GloNAF ------
cat("\n\n========== GLONAF ==========\n")
gln_dir <- file.path(scratch, "glonaf")
dir.create(gln_dir, recursive = TRUE, showWarnings = FALSE)
gln_base <- "https://zenodo.org/records/13235357/files/"
for (f in c("glonaf_flora2.xlsx", "glonaf_taxon_wcvp.xlsx", "glonaf_region.xlsx")) {
  dest <- file.path(gln_dir, f)
  tryCatch({
    dl(paste0(gln_base, f, "?download=1"), dest)
    cat(sprintf("OK %s (%.1f KB)\n", f, file.size(dest) / 1024))
  }, error = function(e) {
    cat(sprintf("FAIL %s: %s\n", f, conditionMessage(e)))
  })
}

cat("\n=== GloNAF schemas ===\n")
for (f in list.files(gln_dir, pattern = "\\.xlsx$", full.names = TRUE)) {
  cat(sprintf("\n--- %s ---\n", basename(f)))
  sheets <- tryCatch(wb_get_sheet_names(wb_load(f)),
                     error = function(e) { cat("load FAIL:", conditionMessage(e), "\n"); character(0) })
  cat(sprintf("  sheets: %s\n", paste(sheets, collapse = ", ")))
  for (s in sheets) {
    df <- tryCatch(read_xlsx(f, sheet = s, rows = 1:3), error = function(e) NULL)
    if (!is.null(df)) {
      cat(sprintf("  '%s': %d cols\n", s, ncol(df)))
      cat(sprintf("    cols: %s\n",
                  paste(names(df)[seq_len(min(15L, ncol(df)))], collapse = " | ")))
    }
  }
}

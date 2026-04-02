setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
tsv_path <- file.path(dest, "Taxon.tsv")

# The zip should already be downloaded, extract again
zip_path <- file.path(dest, "col_download.zip")
if (!file.exists(zip_path)) {
  cat("Zip not found, re-downloading...\n")
  url <- "https://download.checklistbank.org/col/annual/2025_dwca.zip"
  utils::download.file(url, zip_path, mode = "wb")
}

txt_files <- utils::unzip(zip_path, list = TRUE)$Name
cat("Files in COL archive:\n")
print(head(txt_files, 20))

taxon_target <- txt_files[grepl("Taxon\\.tsv$", txt_files)]
cat("\nTaxon file:", taxon_target, "\n")

utils::unzip(zip_path, files = taxon_target[1], exdir = dest, junkpaths = TRUE)

# Read header
lines <- readLines(tsv_path, n = 2, encoding = "UTF-8")
header_raw <- strsplit(lines[1], "\t")[[1]]
cat("\nRaw header (first 20):\n")
for (i in seq_along(header_raw)) {
  cat(sprintf("  [%d] %s\n", i, header_raw[i]))
}

# Strip namespace prefixes
header_stripped <- sub("^[a-z]+:", "", header_raw)
cat("\nStripped header (first 20):\n")
for (i in seq_along(header_stripped)) {
  cat(sprintf("  [%d] %s\n", i, header_stripped[i]))
}

# Check which expected cols are present
match_cols <- c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus",
  "acceptedNameUsageID", "family", "genericName", "specificEpithet",
  "scientificNameAuthorship", "infraspecificEpithet"
)
cat("\nMatch columns present:\n")
for (col in match_cols) {
  cat(sprintf("  %s: %s\n", col, col %in% header_stripped))
}

# Read small sample
df <- utils::read.delim(tsv_path, nrows = 5, fileEncoding = "UTF-8",
                        stringsAsFactors = FALSE, na.strings = "")
names(df) <- sub("^[a-z]+:", "", names(df))
cat("\nSample scientificName values:\n")
print(df$scientificName[1:5])
cat("\nSample scientificNameAuthorship values:\n")
print(df$scientificNameAuthorship[1:5])

unlink(tsv_path)

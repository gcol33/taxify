setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
zip_path <- file.path(dest, "wfo_download.zip")

files <- utils::unzip(zip_path, list = TRUE)$Name
target <- files[grepl("classification", files)]
utils::unzip(zip_path, files = target[1], exdir = dest, junkpaths = TRUE)
csv_path <- file.path(dest, basename(target[1]))

# Read header only
header <- strsplit(readLines(csv_path, n = 1, encoding = "latin1"), "\t")[[1]]
cat("All columns:\n")
for (i in seq_along(header)) {
  cat(sprintf("  [%d] %s\n", i, header[i]))
}

# Read a small sample to check values
df <- utils::read.delim(csv_path, nrows = 100, fileEncoding = "latin1",
                        stringsAsFactors = FALSE, na.strings = "")
cat("\nColumn names in df:\n")
print(names(df))

# Check taxonomicStatus values
if ("taxonomicStatus" %in% names(df)) {
  cat("\ntaxonomicStatus values (first 100 rows):\n")
  print(table(df$taxonomicStatus, useNA = "always"))
}

# Check acceptedNameUsageID presence
cat("\nacceptedNameUsageID present:", "acceptedNameUsageID" %in% names(df), "\n")

# Check a few scientificName values
cat("\nFirst 5 scientificName:\n")
print(head(df$scientificName))

# Check if quoting is an issue
cat("\nContains quotes:", any(grepl('"', df$scientificName, fixed = TRUE)), "\n")

unlink(csv_path)

setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
zip_path <- file.path(dest, "wfo_download.zip")

# Extract just the classification file
files <- utils::unzip(zip_path, list = TRUE)$Name
target <- files[grepl("classification", files)]
cat("Target file:", target, "\n")

utils::unzip(zip_path, files = target[1], exdir = dest, junkpaths = TRUE)
csv_path <- file.path(dest, basename(target[1]))

# Read first 3 lines raw
lines <- readLines(csv_path, n = 3, encoding = "latin1")
cat("\nFirst 3 lines (raw):\n")
for (l in lines) {
  cat(substr(l, 1, 200), "\n---\n")
}

# Check separator
cat("\nContains tabs:", grepl("\t", lines[1]), "\n")
cat("Contains commas:", grepl(",", lines[1]), "\n")

# Try reading header
header <- strsplit(lines[1], "\t")[[1]]
cat("\nTab-split header (first 15):\n")
print(head(header, 15))

if (length(header) <= 2) {
  header <- strsplit(lines[1], ",")[[1]]
  cat("\nComma-split header (first 15):\n")
  print(head(header, 15))
}

# Clean up
unlink(csv_path)

setwd("C:/Users/Gilles Colling/Documents/dev/taxify")

dest <- tools::R_user_dir("taxify", "data")
tsv_path <- file.path(dest, "Taxon.tsv")
zip_path <- file.path(dest, "col_download.zip")

txt_files <- utils::unzip(zip_path, list = TRUE)$Name
taxon_target <- txt_files[grepl("Taxon\\.tsv$", txt_files)]
utils::unzip(zip_path, files = taxon_target[1], exdir = dest, junkpaths = TRUE)

# Read raw lines
lines <- readLines(tsv_path, n = 3, encoding = "UTF-8")
cat("Line 1 (header) first 300 chars:\n")
cat(substr(lines[1], 1, 300), "\n---\n")
cat("Line 2 first 300 chars:\n")
cat(substr(lines[2], 1, 300), "\n---\n")

# Count tabs in each line
cat("\nTabs in line 1:", nchar(gsub("[^\t]", "", lines[1])), "\n")
cat("Tabs in line 2:", nchar(gsub("[^\t]", "", lines[2])), "\n")

# Try read.delim with quote="" (disable quoting)
df1 <- utils::read.delim(tsv_path, nrows = 3, fileEncoding = "UTF-8",
                         stringsAsFactors = FALSE, na.strings = "", quote = "")
names(df1) <- sub("^[a-z]+:", "", names(df1))
cat("\nWith quote='': ncol =", ncol(df1), "\n")
cat("scientificName:", df1$scientificName[1], "\n")
cat("genericName:", df1$genericName[1], "\n")

# Try with default quoting
df2 <- utils::read.delim(tsv_path, nrows = 3, fileEncoding = "UTF-8",
                         stringsAsFactors = FALSE, na.strings = "")
names(df2) <- sub("^[a-z]+:", "", names(df2))
cat("\nWith default quoting: ncol =", ncol(df2), "\n")
cat("scientificName:", df2$scientificName[1], "\n")

unlink(tsv_path)

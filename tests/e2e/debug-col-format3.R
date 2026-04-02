setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
tsv_path <- file.path(dest, "Taxon.tsv")
zip_path <- file.path(dest, "col_download.zip")

txt_files <- utils::unzip(zip_path, list = TRUE)$Name
taxon_target <- txt_files[grepl("Taxon\\.tsv$", txt_files)]
utils::unzip(zip_path, files = taxon_target[1], exdir = dest, junkpaths = TRUE)

# Read 100 rows with quote="" (what the backend uses)
df <- utils::read.delim(tsv_path, nrows = 100, fileEncoding = "UTF-8",
                        stringsAsFactors = FALSE, quote = "", na.strings = "")
names(df) <- sub("^[a-z]+:", "", names(df))

cat("Columns:\n")
print(names(df))
cat("\nDimensions:", dim(df), "\n")

# Check non-NA values per column
for (col in names(df)) {
  n_valid <- sum(!is.na(df[[col]]))
  if (n_valid > 0) cat(sprintf("  %s: %d non-NA, first='%s'\n", col, n_valid,
                                 df[[col]][which(!is.na(df[[col]]))[1]]))
}

# Check column selection
match_cols <- c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus",
  "acceptedNameUsageID", "family", "genericName", "specificEpithet",
  "scientificNameAuthorship", "infraspecificEpithet"
)
extra_cols <- c(
  "notho", "nomenclaturalCode", "nomenclaturalStatus", "namePublishedIn",
  "nameAccordingTo", "kingdom", "phylum", "class", "order", "superfamily",
  "subfamily", "tribe", "taxonRemarks", "references", "scientificNameID",
  "parentNameUsageID", "infragenericEpithet", "cultivarEpithet"
)

keep <- intersect(c(match_cols, extra_cols), names(df))
cat("\nKept columns:", length(keep), "of", length(c(match_cols, extra_cols)), "\n")
missing <- setdiff(c(match_cols, extra_cols), names(df))
if (length(missing) > 0) cat("Missing:", paste(missing, collapse = ", "), "\n")

df2 <- df[, keep, drop = FALSE]
cat("\ndf2 dimensions:", dim(df2), "\n")

# Try canonicalName creation
cat("\nTesting col_strip_authorship...\n")
canonical <- taxify:::col_strip_authorship(df2$scientificName, df2$scientificNameAuthorship)
cat("First 5 canonicalName:", head(canonical[!is.na(canonical)], 5), "\n")

# Check for NULL columns
for (col in names(df2)) {
  if (is.null(df2[[col]])) cat("NULL column:", col, "\n")
}

# Try write_vtr
df2$canonicalName <- canonical
tmp <- tempfile(fileext = ".vtr")
cat("\nAttempting write_vtr on 100-row sample...\n")
tryCatch({
  vectra::write_vtr(df2, tmp)
  cat("SUCCESS\n")
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
})

unlink(tsv_path)

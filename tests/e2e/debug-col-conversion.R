setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
tsv_path <- file.path(dest, "Taxon.tsv")
zip_path <- file.path(dest, "col_download.zip")

# Re-extract if zip exists
if (file.exists(zip_path)) {
  txt_files <- utils::unzip(zip_path, list = TRUE)$Name
  taxon_target <- txt_files[grepl("Taxon\\.tsv$", txt_files)]
  utils::unzip(zip_path, files = taxon_target[1], exdir = dest, junkpaths = TRUE)
} else {
  stop("col_download.zip not found — need to re-download")
}

cat("Reading 5000 rows...\n")
df <- utils::read.delim(tsv_path, nrows = 5000, fileEncoding = "UTF-8",
                        stringsAsFactors = FALSE, quote = "",
                        na.strings = "", check.names = FALSE)
names(df) <- sub("^[a-z]+:", "", names(df))

# Keep needed columns
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
df <- df[, keep, drop = FALSE]

df$taxonRank <- toupper(df$taxonRank)
df$taxonomicStatus <- toupper(df$taxonomicStatus)

# Test col_strip_authorship
cat("Testing col_strip_authorship...\n")
df$canonicalName <- taxify:::col_strip_authorship(df$scientificName,
                                                    df$scientificNameAuthorship)
# Spot check
species_rows <- which(df$taxonRank == "SPECIES" & !is.na(df$specificEpithet))
if (length(species_rows) > 0) {
  idx <- species_rows[1:min(3, length(species_rows))]
  for (i in idx) {
    cat(sprintf("  sci='%s' auth='%s' -> canonical='%s'\n",
                df$scientificName[i], df$scientificNameAuthorship[i],
                df$canonicalName[i]))
  }
}

# Test col_resolve_family
cat("\nTesting col_resolve_family...\n")
t0 <- Sys.time()
df$family <- taxify:::col_resolve_family(df)
dt <- difftime(Sys.time(), t0, units = "secs")
cat(sprintf("  Resolved in %.1f sec\n", dt))

# Check results
n_with_family <- sum(!is.na(df$family))
cat(sprintf("  Rows with family: %d / %d (%.0f%%)\n",
            n_with_family, nrow(df), 100 * n_with_family / nrow(df)))

# Spot check species with family
species_fam <- df[df$taxonRank == "SPECIES" & !is.na(df$family), ]
if (nrow(species_fam) > 0) {
  cat("  Sample species with family:\n")
  for (i in 1:min(5, nrow(species_fam))) {
    cat(sprintf("    %s -> %s\n", species_fam$canonicalName[i],
                species_fam$family[i]))
  }
}

unlink(tsv_path)
cat("\nDone.\n")

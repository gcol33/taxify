# Freezes the syntaxon rows of the example database: whole classes of the
# EuroVegChecklist and of the Czech national classification, as taxifydb's
# readers assemble them (before keys), written to data-raw/syntaxa/<name>.tsv
# for make_example_db.R to key and write.
#
# Needs taxifydb and its frozen snapshots (downloaded from the
# evc-snapshot-* / vegcz-snapshot-* releases, or a local crawl directory).
# Run from the package root:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" data-raw/extract_syntaxon_examples.R

devtools::load_all(".", quiet = TRUE)

OUT <- file.path("data-raw", "syntaxa")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# The classes the hand-checked sample in tests/testthat/test-syntaxon-eva.R
# resolves into, and the classes holding its competing units.
EVC_CLASSES <- c(
  "BA",  # Vaccinio-Piceetea
  "CA",  # Carpino-Fagetea sylvaticae
  "CB",  # Quercetea pubescentis
  "CM",  # Molinio-Arrhenatheretea
  "DA",  # Festuco-Brometea
  "HA",  # Alno glutinosae-Populetea albae
  "OD"   # Phragmito-Magnocaricetea
)
VEGCZ_CLASSES <- c(
  "TD",  # Molinio-Arrhenatheretea
  "LB"   # Carpino-Fagetea
)

write_rows <- function(df, name) {
  df <- df[order(df$taxon_id), , drop = FALSE]
  utils::write.table(df, file.path(OUT, paste0(name, ".tsv")), sep = "\t",
                     quote = FALSE, row.names = FALSE, na = "",
                     fileEncoding = "UTF-8")
  message(sprintf("%s: %d rows", name, nrow(df)))
}

tmp <- tempfile("syntaxa_")
dir.create(tmp)

evc <- taxifydb::download_evc(file.path(tmp, "evc"))
df <- taxifydb::read_evc(evc$synonyms, evc$units, evc$synonyms_2016,
                         verbose = FALSE)
df <- df[substr(df$evc_code, 1L, 2L) %in% EVC_CLASSES, , drop = FALSE]
df$description <- NULL
df$remark <- NULL
write_rows(df, "evc")

cz <- taxifydb::download_vegcz(file.path(tmp, "vegcz"))
df <- taxifydb::read_vegcz(cz$synonyms, cz$units, verbose = FALSE)
df <- df[substr(df$vegcz_code, 1L, 2L) %in% VEGCZ_CLASSES, , drop = FALSE]
df$description_cz <- NULL
df$description_en <- NULL
df$remark <- NULL
write_rows(df, "vegcz")

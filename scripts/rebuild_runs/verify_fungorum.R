setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressMessages({
  library(vectra)
  devtools::load_all(quiet = TRUE)
})

p <- file.path(taxify_data_dir(), "fungorum", "latest", "fungorum.vtr")
cat("vtr:", p, "\n")
cat("size:", round(file.size(p) / 1024^2, 1), "MB\n")
cat("indexes:\n")
for (idx in list.files(dirname(p), pattern = "fungorum\\.vtr\\..*\\.vtri$",
                       full.names = TRUE)) {
  cat(sprintf("  %s  %.1f MB\n", basename(idx), file.size(idx) / 1024^2))
}

cat("\n--- row count ---\n")
cat("total:", collect(summarise(tbl(p), n = n()))[[1]], "\n")

cat("\n--- by status ---\n")
print(collect(summarise(group_by(tbl(p), taxonomic_status), n = n())))

cat("\n--- by rank (top 10) ---\n")
ranks <- collect(summarise(group_by(tbl(p), taxon_rank), n = n()))
print(ranks[order(-ranks$n), ][1:10, ])

cat("\n--- sample query: Amanita ---\n")
amanita <- collect(filter(tbl(p), genus == "Amanita"))
cat("rows:", nrow(amanita), "\n")
cat("status breakdown:\n")
print(table(amanita$taxonomic_status))
cat("first 5 accepted:\n")
acc <- amanita[amanita$taxonomic_status == "ACCEPTED", ]
print(acc[1:min(5, nrow(acc)), c("canonical_name", "authorship", "family")])

cat("\n--- canonical_name index lookup test ---\n")
hit <- collect(filter(tbl(p), canonical_name == "Amanita muscaria"))
print(hit[, c("taxon_id", "canonical_name", "taxon_rank", "taxonomic_status",
              "family", "genus", "authorship")])

cat("\n--- index check: filter by key_ci ---\n")
hit2 <- collect(filter(tbl(p), key_ci == "boletus edulis"))
cat("rows:", nrow(hit2), "\n")
print(hit2[1:min(3, nrow(hit2)), c("canonical_name", "taxonomic_status",
                                    "family")])

cat("\nverify OK\n")

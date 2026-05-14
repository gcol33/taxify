setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
suppressMessages({
  library(vectra)
  devtools::load_all(quiet = TRUE)
})

p <- file.path(taxify_data_dir(), "algaebase", "latest", "algaebase.vtr")
cat("vtr:", p, "\n")
cat("size:", round(file.size(p) / 1024^2, 1), "MB\n")
cat("indexes:\n")
for (idx in list.files(dirname(p), pattern = "algaebase\\.vtr\\..*\\.vtri$",
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

cat("\n--- sample query: Sargassum ---\n")
sarg <- collect(filter(tbl(p), genus == "Sargassum"))
cat("rows:", nrow(sarg), "\n")
cat("status breakdown:\n")
print(table(sarg$taxonomic_status))
acc <- sarg[sarg$taxonomic_status == "ACCEPTED", ]
if (nrow(acc) > 0L) {
  cat("first 5 accepted:\n")
  print(acc[1:min(5, nrow(acc)),
            c("canonical_name", "authorship", "family")])
}

cat("\n--- canonical_name index lookup: Chlorella vulgaris ---\n")
hit <- collect(filter(tbl(p), canonical_name == "Chlorella vulgaris"))
print(hit[, c("taxon_id", "canonical_name", "taxon_rank",
              "taxonomic_status", "family", "genus", "authorship")])

cat("\n--- key_ci index lookup: ulva lactuca ---\n")
hit2 <- collect(filter(tbl(p), key_ci == "ulva lactuca"))
cat("rows:", nrow(hit2), "\n")
print(hit2[1:min(3, nrow(hit2)),
           c("canonical_name", "taxonomic_status", "family")])

cat("\nverify OK\n")

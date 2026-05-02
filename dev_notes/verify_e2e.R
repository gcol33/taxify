setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)
devtools::load_all(quiet = TRUE)

cat(sprintf("vectra: %s\n", as.character(packageVersion("vectra"))))

names_test <- c(
  "Quercus robur",
  "Fagus sylvatica",
  "Bellis perennis",
  "Homo sapiens",
  "Escherichia coli",
  "Saccharomyces cerevisiae",
  "Mytilus edulis",
  "Pinus sylvestris",
  "NotARealName xyz"
)

backends <- c("wfo", "col", "gbif", "itis", "ncbi", "worms", "euromed")

for (b in backends) {
  cat(sprintf("\n=== %s ===\n", b))
  t0 <- Sys.time()
  res <- tryCatch(
    taxify(names_test, backend = b, verbose = FALSE),
    error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL }
  )
  if (is.null(res)) next
  dt <- as.numeric(Sys.time() - t0, units = "secs")
  show_cols <- intersect(c("input_name", "accepted_name", "match_type",
                           "taxonomic_status", "backend"),
                         names(res))
  print(res[, show_cols])
  cat(sprintf("  -- %.2f s for %d names\n", dt, length(names_test)))
}

cat("\n\n=== multi-backend fallback ===\n")
res <- taxify(names_test, backend = c("wfo", "col", "gbif", "ncbi", "worms"),
              verbose = FALSE)
show_cols <- intersect(c("input_name", "accepted_name", "match_type",
                         "taxonomic_status", "backend"),
                       names(res))
print(res[, show_cols])

cat("\n\n=== enrichment join: conservation_status ===\n")
res2 <- taxify(c("Panthera tigris", "Quercus robur", "Pongo abelii"),
               backend = c("col", "gbif"), verbose = FALSE)
res2_enr <- add_conservation_status(res2)
print(res2_enr[, intersect(c("input_name", "accepted_name", "conservation_status"),
                           names(res2_enr))])

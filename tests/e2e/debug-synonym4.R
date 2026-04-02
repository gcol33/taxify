setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

bb_path <- file.path(taxify_data_dir(), "wfo.vtr")

# Simulate what resolve_synonyms does:
# acc_ids from the match results
acc_ids <- c("wfo-0000482612", "wfo-0000292858")

id_df <- data.frame(lookup_id = acc_ids, stringsAsFactors = FALSE)
cat("Input IDs:\n")
print(id_df)

tmp_ids <- tempfile(fileext = ".vtr")
vectra::write_vtr(id_df, tmp_ids)

# Read back to verify
cat("\nRe-read from temp .vtr:\n")
print(vectra::tbl(tmp_ids) |> vectra::collect())

# Do the join
acc_info <- vectra::inner_join(
  vectra::tbl(tmp_ids),
  vectra::tbl(bb_path) |>
    vectra::select(taxonID, scientificName, family, genus),
  by = c("lookup_id" = "taxonID")
) |> vectra::collect()

cat("\nJoin result (acc_info):\n")
print(acc_info)

# Build lookup
acc_lookup <- stats::setNames(
  split(acc_info, acc_info$lookup_id),
  acc_info$lookup_id
)

cat("\nacc_lookup keys:", names(acc_lookup), "\n")
for (k in names(acc_lookup)) {
  cat(sprintf("  %s -> %s (%s)\n", k, acc_lookup[[k]]$scientificName[1],
              acc_lookup[[k]]$family[1]))
}

# What would resolve_synonyms return for these?
cat("\nLookup for wfo-0000482612:", acc_lookup[["wfo-0000482612"]]$scientificName[1], "\n")
cat("Lookup for wfo-0000292858:", acc_lookup[["wfo-0000292858"]]$scientificName[1], "\n")

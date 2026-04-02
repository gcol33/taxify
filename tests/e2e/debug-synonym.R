setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

# Check what "Pinus abies" matches to
bb_path <- file.path(taxify_data_dir(), "wfo.vtr")

# Look up "Pinus abies" exact match
input_df <- data.frame(
  row_idx = 1L,
  cleaned_name = "Pinus abies",
  stringsAsFactors = FALSE
)
tmp <- tempfile(fileext = ".vtr")
vectra::write_vtr(input_df, tmp)

matches <- vectra::inner_join(
  vectra::tbl(tmp),
  vectra::tbl(bb_path) |>
    vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                   acceptedNameUsageID, family, genus),
  by = c("cleaned_name" = "scientificName")
) |> vectra::collect()

cat("Matches for 'Pinus abies':\n")
print(matches)

# Now look up the acceptedNameUsageID
if (nrow(matches) > 0) {
  acc_id <- matches$acceptedNameUsageID[1]
  cat("\nacceptedNameUsageID:", acc_id, "\n")

  # Look up that ID
  id_df <- data.frame(lookup_id = acc_id, stringsAsFactors = FALSE)
  tmp2 <- tempfile(fileext = ".vtr")
  vectra::write_vtr(id_df, tmp2)

  acc <- vectra::inner_join(
    vectra::tbl(tmp2),
    vectra::tbl(bb_path) |>
      vectra::select(taxonID, scientificName, family, genus),
    by = c("lookup_id" = "taxonID")
  ) |> vectra::collect()

  cat("Accepted name for that ID:\n")
  print(acc)
}

# Also check "Quercus pedunculata"
cat("\n---\n")
input_df2 <- data.frame(
  row_idx = 1L,
  cleaned_name = "Quercus pedunculata",
  stringsAsFactors = FALSE
)
tmp3 <- tempfile(fileext = ".vtr")
vectra::write_vtr(input_df2, tmp3)

matches2 <- vectra::inner_join(
  vectra::tbl(tmp3),
  vectra::tbl(bb_path) |>
    vectra::select(taxonID, scientificName, taxonRank, taxonomicStatus,
                   acceptedNameUsageID, family, genus),
  by = c("cleaned_name" = "scientificName")
) |> vectra::collect()

cat("Matches for 'Quercus pedunculata':\n")
print(matches2)

if (nrow(matches2) > 0) {
  acc_id2 <- matches2$acceptedNameUsageID[1]
  cat("\nacceptedNameUsageID:", acc_id2, "\n")

  id_df2 <- data.frame(lookup_id = acc_id2, stringsAsFactors = FALSE)
  tmp4 <- tempfile(fileext = ".vtr")
  vectra::write_vtr(id_df2, tmp4)

  acc2 <- vectra::inner_join(
    vectra::tbl(tmp4),
    vectra::tbl(bb_path) |>
      vectra::select(taxonID, scientificName, family, genus),
    by = c("lookup_id" = "taxonID")
  ) |> vectra::collect()

  cat("Accepted name for that ID:\n")
  print(acc2)
}

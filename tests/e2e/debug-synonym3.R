setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

# Run through taxify() which handles dispatch internally
res <- taxify(c("Pinus abies", "Quercus pedunculata", "Centaurea jacea"),
              backend = "wfo", verbose = TRUE)

cat("\nFull result:\n")
print(res[, c("input_name", "matched_name", "accepted_name", "taxon_id",
              "accepted_id", "family", "is_synonym", "match_type")])

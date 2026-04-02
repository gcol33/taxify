setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()

fmt_mb <- function(bytes) sprintf("%.0f MB", bytes / 1024^2)

cat("=== .vtr size analysis ===\n\n")

# --- WFO ---
wfo_path <- file.path(dest, "wfo.vtr")
cat("WFO current (all cols):", fmt_mb(file.size(wfo_path)), "\n")

# Read schema
wfo_cols <- names(vectra::tbl(wfo_path) |> utils::head(1) |> vectra::collect())
cat("  Columns:", paste(wfo_cols, collapse = ", "), "\n")
cat("  N columns:", length(wfo_cols), "\n")

# Core-only: match columns
wfo_core <- c("taxonID", "scientificName", "taxonRank", "taxonomicStatus",
              "acceptedNameUsageID", "family", "genus", "specificEpithet",
              "scientificNameAuthorship", "infraspecificEpithet")
wfo_core_avail <- intersect(wfo_core, wfo_cols)

tmp_core <- tempfile(fileext = ".vtr")
wfo_df <- vectra::tbl(wfo_path) |>
  vectra::select(!!!lapply(wfo_core_avail, as.name)) |>
  vectra::collect()
vectra::write_vtr(wfo_df, tmp_core)
cat("  Core-only (", length(wfo_core_avail), " cols):", fmt_mb(file.size(tmp_core)), "\n")

# Extra-only
wfo_extra <- setdiff(wfo_cols, wfo_core)
if (length(wfo_extra) > 0) {
  tmp_extra <- tempfile(fileext = ".vtr")
  wfo_df2 <- vectra::tbl(wfo_path) |>
    vectra::select(!!!lapply(c("taxonID", wfo_extra), as.name)) |>
    vectra::collect()
  vectra::write_vtr(wfo_df2, tmp_extra)
  cat("  Extras (", length(wfo_extra), " cols + taxonID):", fmt_mb(file.size(tmp_extra)), "\n")
}
rm(wfo_df); if (exists("wfo_df2")) rm(wfo_df2); gc(verbose = FALSE)
cat("\n")

# --- COL ---
col_path <- file.path(dest, "col.vtr")
cat("COL current (all cols):", fmt_mb(file.size(col_path)), "\n")

col_cols <- names(vectra::tbl(col_path) |> utils::head(1) |> vectra::collect())
cat("  Columns:", paste(col_cols, collapse = ", "), "\n")
cat("  N columns:", length(col_cols), "\n")

col_core <- c("taxonID", "canonicalName", "taxonRank", "taxonomicStatus",
              "acceptedNameUsageID", "family", "genericName", "specificEpithet",
              "scientificNameAuthorship", "infraspecificEpithet")
col_core_avail <- intersect(col_core, col_cols)

tmp_core2 <- tempfile(fileext = ".vtr")
col_df <- vectra::tbl(col_path) |>
  vectra::select(!!!lapply(col_core_avail, as.name)) |>
  vectra::collect()
vectra::write_vtr(col_df, tmp_core2)
cat("  Core-only (", length(col_core_avail), " cols):", fmt_mb(file.size(tmp_core2)), "\n")

col_extra <- setdiff(col_cols, col_core)
if (length(col_extra) > 0) {
  tmp_extra2 <- tempfile(fileext = ".vtr")
  col_df2 <- vectra::tbl(col_path) |>
    vectra::select(!!!lapply(c("taxonID", col_extra), as.name)) |>
    vectra::collect()
  vectra::write_vtr(col_df2, tmp_extra2)
  cat("  Extras (", length(col_extra), " cols + taxonID):", fmt_mb(file.size(tmp_extra2)), "\n")
}

# COL species profile sidecar
sp_path <- file.path(dest, "col_species_profile.vtr")
if (file.exists(sp_path)) {
  cat("  SpeciesProfile sidecar:", fmt_mb(file.size(sp_path)), "\n")
}
rm(col_df); if (exists("col_df2")) rm(col_df2); gc(verbose = FALSE)
cat("\n")

# --- GBIF ---
gbif_path <- file.path(dest, "gbif.vtr")
cat("GBIF current (all cols):", fmt_mb(file.size(gbif_path)), "\n")

gbif_cols <- names(vectra::tbl(gbif_path) |> utils::head(1) |> vectra::collect())
cat("  Columns:", paste(gbif_cols, collapse = ", "), "\n")
cat("  N columns:", length(gbif_cols), "\n")

gbif_core <- c("id", "canonical_name", "rank", "status", "is_synonym_flag",
               "accepted_id", "family", "genus_or_above", "specific_epithet",
               "authorship", "infra_specific_epithet")
gbif_core_avail <- intersect(gbif_core, gbif_cols)

tmp_core3 <- tempfile(fileext = ".vtr")
gbif_df <- vectra::tbl(gbif_path) |>
  vectra::select(!!!lapply(gbif_core_avail, as.name)) |>
  vectra::collect()
vectra::write_vtr(gbif_df, tmp_core3)
cat("  Core-only (", length(gbif_core_avail), " cols):", fmt_mb(file.size(tmp_core3)), "\n")

gbif_extra <- setdiff(gbif_cols, gbif_core)
if (length(gbif_extra) > 0) {
  tmp_extra3 <- tempfile(fileext = ".vtr")
  gbif_df2 <- vectra::tbl(gbif_path) |>
    vectra::select(!!!lapply(c("id", gbif_extra), as.name)) |>
    vectra::collect()
  vectra::write_vtr(gbif_df2, tmp_extra3)
  cat("  Extras (", length(gbif_extra), " cols + id):", fmt_mb(file.size(tmp_extra3)), "\n")
}
rm(gbif_df); if (exists("gbif_df2")) rm(gbif_df2); gc(verbose = FALSE)
cat("\n")

# --- Summary ---
cat("=== Summary ===\n")
cat(sprintf("  WFO:  core=%s  extras=%s  total=%s\n",
            fmt_mb(file.size(tmp_core)),
            if (exists("tmp_extra")) fmt_mb(file.size(tmp_extra)) else "0 MB",
            fmt_mb(file.size(wfo_path))))
cat(sprintf("  COL:  core=%s  extras=%s  total=%s\n",
            fmt_mb(file.size(tmp_core2)),
            if (exists("tmp_extra2")) fmt_mb(file.size(tmp_extra2)) else "0 MB",
            fmt_mb(file.size(col_path))))
cat(sprintf("  GBIF: core=%s  extras=%s  total=%s\n",
            fmt_mb(file.size(tmp_core3)),
            if (exists("tmp_extra3")) fmt_mb(file.size(tmp_extra3)) else "0 MB",
            fmt_mb(file.size(gbif_path))))

# Generates inst/exampledb/: a tiny, self-contained taxify data directory used
# by the package examples so they run offline (no backbone/enrichment download).
#
# Layout mirrors the real taxify_data_dir():
#   <backend>/latest/<backend>.vtr        + <backend>.meta
#   enrichment/<name>/latest/<name>.vtr   + meta.json
#
# Run from the package root:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" data-raw/make_example_db.R
# Enrichment names as arguments rewrite only those enrichment fixtures and
# leave the rest of inst/exampledb/ (backbones included) untouched:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" data-raw/make_example_db.R wcvp glonaf
#
# With no arguments the script deletes inst/exampledb/ and writes only what is
# defined below. The bundled genus_register/, backend_coverage/ and the
# enrichment fixtures missing from `enr_species` (austraits, bien, brot,
# fishmorph, iucn, kew_sid, zanne) are not rebuilt by it, and the keys
# conservation_status, woodiness and fish_traits no longer exist in the
# manifest. Pass enrichment names instead of running it bare.

devtools::load_all(".", quiet = TRUE)
suppressMessages({
  library(vectra)
})

ONLY_ENR <- commandArgs(trailingOnly = TRUE)

OUT <- file.path("inst", "exampledb")
if (length(ONLY_ENR) == 0L && dir.exists(OUT)) unlink(OUT, recursive = TRUE)
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

EX_VERSION <- "example"
EX_DATE    <- "2026-06-24"

# ----------------------------------------------------------------------------
# Backbones
# ----------------------------------------------------------------------------

# Build a backbone .vtr from a plain data.frame in the pre-compute schema,
# reusing the exact pipeline the real download path and test fixtures use.
write_backbone <- function(df, backend_name) {
  if (length(ONLY_ENR) > 0L) return(invisible(NULL))
  df <- precompute_keys(df, "canonical_name", "genus", "specific_epithet")
  df <- embed_accepted(
    df,
    id_col         = "taxon_id",
    acc_id_col     = "accepted_name_usage_id",
    name_col       = "canonical_name",
    family_col     = "family",
    genus_col      = "genus",
    status_col     = "taxonomic_status",
    authorship_col = "authorship"
  )
  df <- df[order(df$genus, na.last = TRUE), ]
  rownames(df) <- NULL

  dir <- file.path(OUT, backend_name, "latest")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  vtr <- file.path(dir, paste0(backend_name, ".vtr"))
  vectra::write_vtr(df, vtr, batch_size = 50000L)

  # .meta sidecar (read_backbone_meta -> backbone_version output column)
  meta <- file.path(dir, paste0(backend_name, ".meta"))
  writeLines(c(
    paste0("backend=", backend_name),
    paste0("version=", EX_VERSION),
    paste0("build_date=", EX_DATE),
    paste0("nrow=", nrow(df)),
    "source_url=bundled example database"
  ), meta)

  # meta.json (read_version_meta -> check_version). static = TRUE freezes the
  # backbone so taxify() never tries to update it against the online manifest.
  jsonlite::write_json(
    list(backend = backend_name, version = EX_VERSION,
         nrow = nrow(df), static = TRUE),
    file.path(dir, "meta.json"),
    auto_unbox = TRUE, pretty = TRUE
  )
  invisible(vtr)
}

# Minimal backbone row helper (recycles scalars).
bb_row <- function(canonical_name, genus, specific_epithet, family,
                   taxon_id, status = "ACCEPTED", acc_id = NA_character_,
                   rank = "SPECIES", authorship = NA_character_, ...) {
  data.frame(
    taxon_id = taxon_id,
    canonical_name = canonical_name,
    taxon_rank = rank,
    taxonomic_status = status,
    accepted_name_usage_id = acc_id,
    family = family,
    genus = genus,
    specific_epithet = specific_epithet,
    authorship = authorship,
    infraspecific_epithet = NA_character_,
    stringsAsFactors = FALSE,
    ...
  )
}

# ---- WFO (plants) ----
wfo <- do.call(rbind, list(
  bb_row("Quercus robur",         "Quercus",      "robur",        "Fagaceae",    "wfo-ex-001", authorship = "L."),
  bb_row("Quercus petraea",       "Quercus",      "petraea",      "Fagaceae",    "wfo-ex-002", authorship = "(Matt.) Liebl."),
  bb_row("Quercus pyrenaica",     "Quercus",      "pyrenaica",    "Fagaceae",    "wfo-ex-003", authorship = "Willd."),
  bb_row("Pinus sylvestris",      "Pinus",        "sylvestris",   "Pinaceae",    "wfo-ex-004", authorship = "L."),
  bb_row("Abies alba",            "Abies",        "alba",         "Pinaceae",    "wfo-ex-005", authorship = "Mill."),
  bb_row("Robinia pseudoacacia",  "Robinia",      "pseudoacacia", "Fabaceae",    "wfo-ex-006", authorship = "L."),
  bb_row("Ailanthus altissima",   "Ailanthus",    "altissima",    "Simaroubaceae","wfo-ex-007", authorship = "(Mill.) Swingle"),
  bb_row("Arrhenatherum elatius", "Arrhenatherum","elatius",      "Poaceae",     "wfo-ex-008", authorship = "(L.) P.Beauv. ex J.Presl & C.Presl"),
  bb_row("Bellis perennis",       "Bellis",       "perennis",     "Asteraceae",  "wfo-ex-009", authorship = "L.")
))
# WFO-specific extra columns surfaced by add_wfo_info().
wfo$scientificNameID     <- paste0("https://list.worldfloraonline.org/", wfo$taxon_id)
wfo$parentNameUsageID    <- NA_character_
wfo$namePublishedIn      <- NA_character_
wfo$higherClassification <- paste("Plantae", wfo$family, wfo$genus, sep = "|")
wfo$taxonRemarks         <- NA_character_
write_backbone(wfo, "wfo")

# ---- GBIF (animals, fungi, algae + a plant for add_gbif_info) ----
gbif <- do.call(rbind, list(
  bb_row("Quercus robur",            "Quercus",     "robur",          "Fagaceae",        "gbif-ex-001", authorship = "L."),
  bb_row("Parus major",              "Parus",       "major",          "Paridae",         "gbif-ex-002", authorship = "Linnaeus, 1758"),
  bb_row("Bufo bufo",                "Bufo",        "bufo",           "Bufonidae",       "gbif-ex-003", authorship = "(Linnaeus, 1758)"),
  bb_row("Vulpes vulpes",            "Vulpes",      "vulpes",         "Canidae",         "gbif-ex-004", authorship = "(Linnaeus, 1758)"),
  bb_row("Drosophila melanogaster",  "Drosophila",  "melanogaster",   "Drosophilidae",   "gbif-ex-005", authorship = "Meigen, 1830"),
  bb_row("Abax parallelepipedus",    "Abax",        "parallelepipedus","Carabidae",      "gbif-ex-006", authorship = "(Piller & Mitterpacher, 1783)"),
  bb_row("Panthera tigris",          "Panthera",    "tigris",         "Felidae",         "gbif-ex-007", authorship = "(Linnaeus, 1758)"),
  bb_row("Panthera leo",             "Panthera",    "leo",            "Felidae",         "gbif-ex-008", authorship = "(Linnaeus, 1758)"),
  bb_row("Salmo trutta",             "Salmo",       "trutta",         "Salmonidae",      "gbif-ex-009", authorship = "Linnaeus, 1758"),
  bb_row("Gadus morhua",             "Gadus",       "morhua",         "Gadidae",         "gbif-ex-010", authorship = "Linnaeus, 1758"),
  bb_row("Vanessa cardui",           "Vanessa",     "cardui",         "Nymphalidae",     "gbif-ex-011", authorship = "(Linnaeus, 1758)"),
  bb_row("Pogona vitticeps",         "Pogona",      "vitticeps",      "Agamidae",        "gbif-ex-012", authorship = "(Ahl, 1926)"),
  bb_row("Amanita muscaria",         "Amanita",     "muscaria",       "Amanitaceae",     "gbif-ex-013", authorship = "(L.) Lam."),
  bb_row("Fucus vesiculosus",        "Fucus",       "vesiculosus",    "Fucaceae",        "gbif-ex-014", authorship = "Linnaeus"),
  bb_row("Octopus vulgaris",         "Octopus",     "vulgaris",       "Octopodidae",     "gbif-ex-015", authorship = "Cuvier, 1797")
))
write_backbone(gbif, "gbif")

# ---- COL (a plant for add_col_info, plus an animal for the fallback example) ----
col <- do.call(rbind, list(
  bb_row("Quercus robur", "Quercus",  "robur", "Fagaceae", "col-ex-001", authorship = "L."),
  bb_row("Panthera leo",  "Panthera", "leo",   "Felidae",  "col-ex-002", authorship = "(Linnaeus, 1758)")
))
write_backbone(col, "col")

# ---- FishBase (fishes) ----
fishbase <- do.call(rbind, list(
  bb_row("Gadus morhua",  "Gadus",  "morhua",  "Gadidae",    "fishbase-ex-001"),
  bb_row("Salmo trutta",  "Salmo",  "trutta",  "Salmonidae", "fishbase-ex-002")
))
write_backbone(fishbase, "fishbase")

# ---- SeaLifeBase (non-fish aquatic life) ----
sealifebase <- do.call(rbind, list(
  bb_row("Octopus vulgaris", "Octopus", "vulgaris", "Octopodidae", "sealifebase-ex-001"),
  bb_row("Homarus gammarus", "Homarus", "gammarus", "Nephropidae", "sealifebase-ex-002")
))
write_backbone(sealifebase, "sealifebase")

# ---- Reptile Database (reptiles: one species per suborder + a synonym) ----
reptiledb <- do.call(rbind, list(
  bb_row("Pogona vitticeps",     "Pogona",     "vitticeps",  "Agamidae",       "reptiledb-ex-001", order = "Sauria"),
  bb_row("Python regius",        "Python",     "regius",     "Pythonidae",     "reptiledb-ex-002", order = "Serpentes"),
  bb_row("Naja naja",            "Naja",       "naja",       "Elapidae",       "reptiledb-ex-003", order = "Serpentes"),
  bb_row("Chelonia mydas",       "Chelonia",   "mydas",      "Cheloniidae",    "reptiledb-ex-004", order = "Testudines"),
  bb_row("Crocodylus niloticus", "Crocodylus", "niloticus",  "Crocodylidae",   "reptiledb-ex-005", order = "Crocodylia"),
  bb_row("Sphenodon punctatus",  "Sphenodon",  "punctatus",  "Sphenodontidae", "reptiledb-ex-006", order = "Rhynchocephalia"),
  bb_row("Amphibolurus vitticeps", "Amphibolurus", "vitticeps", "Agamidae",    "reptiledb-ex-007",
         status = "SYNONYM", acc_id = "reptiledb-ex-001", order = "Sauria")
))
reptiledb$kingdom <- "Animalia"
reptiledb$phylum  <- "Chordata"
reptiledb$class   <- "Reptilia"
write_backbone(reptiledb, "reptiledb")

# ---- LCVP (Leipzig Catalogue of Vascular Plants; vascular plants + a synonym) ----
lcvp <- do.call(rbind, list(
  bb_row("Quercus robur",       "Quercus", "robur",       "Fagaceae", "lcvp-ex-001", order = "Fagales", authorship = "L."),
  bb_row("Fagus sylvatica",     "Fagus",   "sylvatica",   "Fagaceae", "lcvp-ex-002", order = "Fagales", authorship = "L."),
  bb_row("Quercus pedunculata", "Quercus", "pedunculata", "Fagaceae", "lcvp-ex-003",
         status = "SYNONYM", acc_id = "lcvp-ex-001", order = "Fagales", authorship = "Ehrh.")
))
write_backbone(lcvp, "lcvp")

# ---- WCVP (World Checklist of Vascular Plants, Kew; vascular plants + a synonym) ----
wcvp_bb <- do.call(rbind, list(
  bb_row("Quercus robur",       "Quercus", "robur",       "Fagaceae", "wcvp-ex-001", authorship = "L."),
  bb_row("Fagus sylvatica",     "Fagus",   "sylvatica",   "Fagaceae", "wcvp-ex-002", authorship = "L."),
  bb_row("Quercus pedunculata", "Quercus", "pedunculata", "Fagaceae", "wcvp-ex-003",
         status = "SYNONYM", acc_id = "wcvp-ex-001", authorship = "Ehrh.")
))
write_backbone(wcvp_bb, "wcvp")

# ----------------------------------------------------------------------------
# Enrichments (manifest-driven: columns come from manifest trait_cols)
# ----------------------------------------------------------------------------

manifest <- jsonlite::read_json("inst/manifest.json", simplifyVector = FALSE)
ENR <- manifest$enrichments

# Example species per enrichment (must be an accepted name in a bundled backbone).
enr_species <- list(
  conservation_status = "Panthera tigris",
  griis               = "Robinia pseudoacacia",
  alien_first_records = c("Robinia pseudoacacia", "Ailanthus altissima"),
  wcvp                = "Quercus robur",
  eive                = "Arrhenatherum elatius",
  elton_traits        = "Parus major",
  avonet              = "Parus major",
  pantheria           = "Vulpes vulpes",
  amphibio            = "Bufo bufo",
  common_names        = "Quercus robur",
  woodiness           = "Quercus robur",
  diaz_traits         = "Quercus robur",
  leda                = "Arrhenatherum elatius",
  funguild            = "Amanita muscaria",
  fishbase            = "Gadus morhua",
  fungal_traits       = "Amanita muscaria",
  algae_traits        = "Fucus vesiculosus",
  fish_traits         = "Salmo trutta",
  repttraits          = "Pogona vitticeps",
  anage               = "Vulpes vulpes",
  glonaf              = "Robinia pseudoacacia",
  leptraits           = "Vanessa cardui",
  animaltraits        = "Drosophila melanogaster",
  arthropod_traits    = "Abax parallelepipedus",
  baseflor            = "Bellis perennis",
  ecoflora            = "Bellis perennis",
  floraweb            = "Bellis perennis",
  sealifebase         = "Octopus vulgaris",
  groot               = "Abies alba",
  gift                = "Abies alba"
)

# Grouped enrichments: group column + example group values, which are real
# codes of the source's own vocabulary. `values` gives a column its real
# per-group value in place of the dummy one: Quercus robur is native in
# Germany and Belgium in WCVP (TDWG Level 3 GER, BGM), Robinia pseudoacacia
# is naturalized in Germany and Austria in GloNAF (DEU, AUT).
enr_groups <- list(
  griis               = list(col = "country_code", vals = c("AT", "DE")),
  alien_first_records = list(col = "country_code", vals = c("AT", "DE")),
  wcvp                = list(col = "tdwg_code",     vals = c("GER", "BGM"),
                             values = list(native_status = c("native", "native"))),
  common_names        = list(col = "lang",         vals = c("en", "de")),
  glonaf              = list(col = "region_id",    vals = c("DEU", "AUT"),
                             values = list(naturalized = c(1, 1)))
)

# Numeric trait columns (so values keep a sensible type).
NUMERIC_TRAITS <- c(
  "light", "temperature", "moisture", "reaction", "nutrients",
  "beak_length", "beak_depth", "wing_length", "tail_length", "tarsus_length",
  "body_mass_g", "hand_wing_index", "wingspan", "seed_mass", "plant_height",
  "longevity", "body_mass", "alien_first_record",
  # SeaLifeBase numeric traits
  "body_length_cm", "trophic_level", "depth_min_m", "depth_max_m",
  "vulnerability",
  # GRooT root traits (all numeric per-species means)
  "root_diameter", "specific_root_length", "root_tissue_density",
  "root_n_concentration", "root_c_concentration", "root_mass_fraction",
  "lateral_spread", "root_mycorrhizal_colonization", "rooting_depth",
  # ReptTraits numeric traits
  "elevation_min_m", "elevation_max_m", "mean_annual_temp_c", "svl_mm",
  "total_length_mm", "longevity_yr", "clutch_size",
  # GIFT numeric traits (from the default set)
  "gift_plant_height_max", "gift_seed_mass_mean", "gift_sla_mean"
)

dummy_value <- function(col, i) {
  if (col %in% NUMERIC_TRAITS) {
    round(10 + i, 1)
  } else {
    paste0("example_", col)
  }
}

write_enrichment <- function(name) {
  if (length(ONLY_ENR) > 0L && !name %in% ONLY_ENR) return(invisible(NULL))
  entry <- ENR[[name]]
  if (is.null(entry)) {
    message("  (skip enrichment not in manifest: ", name, ")")
    return(invisible(NULL))
  }
  trait_cols <- unlist(entry$trait_cols, use.names = FALSE)
  species    <- enr_species[[name]]
  grp        <- enr_groups[[name]]

  # Group columns are supplied by the fixture itself, not counted as traits.
  value_cols <- if (!is.null(grp)) setdiff(trait_cols, grp$col) else trait_cols

  rows <- list()
  k <- 0L
  for (sp in species) {
    grp_vals <- if (!is.null(grp)) grp$vals else NA_character_
    for (gi in seq_along(grp_vals)) {
      k <- k + 1L
      row <- data.frame(canonical_name = sp, stringsAsFactors = FALSE)
      if (!is.null(grp)) row[[grp$col]] <- grp_vals[[gi]]
      for (tc in value_cols) {
        row[[tc]] <- if (!is.null(grp$values[[tc]])) grp$values[[tc]][[gi]] else dummy_value(tc, k)
      }
      rows[[length(rows) + 1L]] <- row
    }
  }
  df <- do.call(rbind, rows)

  dir <- file.path(OUT, "enrichment", name, "latest")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  vtr <- file.path(dir, paste0(name, ".vtr"))
  vectra::write_vtr(df, vtr)

  meta <- list(
    name    = name,
    version = EX_VERSION,
    nrow    = nrow(df),
    static  = TRUE,
    license = entry$license %||% NA_character_,
    # extract_manifest_citations() drops empty fields (a manifest doi/url with
    # no value arrives as {} -> a zero-length list) so they never reach
    # meta.json, and reads a multi-work citation array as one list per work.
    citation = extract_manifest_citations(manifest, "enrichments", name)
  )
  if (!is.null(grp)) {
    meta$group_col        <- grp$col
    meta$available_groups <- grp$vals
  }
  jsonlite::write_json(meta, file.path(dir, "meta.json"),
                       auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(vtr)
}

for (nm in names(enr_species)) write_enrichment(nm)

cat("Example DB written to", normalizePath(OUT), "\n")
cat("Backbones:", paste(list.files(OUT), collapse = ", "), "\n")
cat("Enrichments:", length(list.files(file.path(OUT, "enrichment"))), "\n")

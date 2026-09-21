# Generates inst/exampledb/: a tiny, self-contained taxify data directory used
# by the package examples and tests so they run offline (no backbone or
# enrichment download).
#
# Layout mirrors the real taxify_data_dir():
#   <backbone>/latest/<backbone>.vtr      + <backbone>.meta + meta.json
#   enrichment/<name>/latest/<name>.vtr   + meta.json (+ <name>_references.vtr)
#   genus_register/latest/, backend_coverage/latest/
#
# Backbones are built from the rows defined below, through the same
# precompute_keys() + embed_accepted() pipeline the real download path uses.
# Every other table is written from its typed JSON spec under
# data-raw/exampledb/ (same relative path, `.json` for `.vtr`), and every
# other file there (meta.json) is copied as is. A new enrichment fixture is a
# new spec directory.
#
# Each target replaces only its own directory. Run from the package root:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" data-raw/make_example_db.R
# or name the targets, as relative directories of inst/exampledb/:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" data-raw/make_example_db.R wfo enrichment/wcvp
# TAXIFY_EXAMPLEDB_OUT writes somewhere other than inst/exampledb/.

devtools::load_all(".", quiet = TRUE)

OUT  <- Sys.getenv("TAXIFY_EXAMPLEDB_OUT", file.path("inst", "exampledb"))
SPEC <- file.path("data-raw", "exampledb")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

EX_VERSION <- "example"
EX_DATE    <- "2026-06-24"

# ----------------------------------------------------------------------------
# Backbones
# ----------------------------------------------------------------------------

# Build a backbone .vtr from a plain data.frame in the pre-compute schema,
# reusing the exact pipeline the real download path and test fixtures use.
write_backbone <- function(df, backend_name) {
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

backbones <- list()

# ---- WFO (plants) ----
backbones$wfo <- function() {
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
}

# ---- GBIF (animals, fungi, algae + a plant for add_gbif_info) ----
backbones$gbif <- function() {
  write_backbone(do.call(rbind, list(
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
  )), "gbif")
}

# ---- COL (a plant for add_col_info, plus an animal for the fallback example) ----
backbones$col <- function() {
  write_backbone(do.call(rbind, list(
    bb_row("Quercus robur", "Quercus",  "robur", "Fagaceae", "col-ex-001", authorship = "L."),
    bb_row("Panthera leo",  "Panthera", "leo",   "Felidae",  "col-ex-002", authorship = "(Linnaeus, 1758)")
  )), "col")
}

# ---- FishBase (fishes) ----
backbones$fishbase <- function() {
  write_backbone(do.call(rbind, list(
    bb_row("Gadus morhua",  "Gadus",  "morhua",  "Gadidae",    "fishbase-ex-001"),
    bb_row("Salmo trutta",  "Salmo",  "trutta",  "Salmonidae", "fishbase-ex-002")
  )), "fishbase")
}

# ---- SeaLifeBase (non-fish aquatic life) ----
backbones$sealifebase <- function() {
  write_backbone(do.call(rbind, list(
    bb_row("Octopus vulgaris", "Octopus", "vulgaris", "Octopodidae", "sealifebase-ex-001"),
    bb_row("Homarus gammarus", "Homarus", "gammarus", "Nephropidae", "sealifebase-ex-002")
  )), "sealifebase")
}

# ---- Reptile Database (reptiles: one species per suborder + a synonym) ----
backbones$reptiledb <- function() {
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
}

# ---- LCVP (Leipzig Catalogue of Vascular Plants; vascular plants + a synonym) ----
backbones$lcvp <- function() {
  write_backbone(do.call(rbind, list(
    bb_row("Quercus robur",       "Quercus", "robur",       "Fagaceae", "lcvp-ex-001", order = "Fagales", authorship = "L."),
    bb_row("Fagus sylvatica",     "Fagus",   "sylvatica",   "Fagaceae", "lcvp-ex-002", order = "Fagales", authorship = "L."),
    bb_row("Quercus pedunculata", "Quercus", "pedunculata", "Fagaceae", "lcvp-ex-003",
           status = "SYNONYM", acc_id = "lcvp-ex-001", order = "Fagales", authorship = "Ehrh.")
  )), "lcvp")
}

# ---- WCVP (World Checklist of Vascular Plants, Kew; vascular plants + a synonym) ----
backbones$wcvp <- function() {
  write_backbone(do.call(rbind, list(
    bb_row("Quercus robur",       "Quercus", "robur",       "Fagaceae", "wcvp-ex-001", authorship = "L."),
    bb_row("Fagus sylvatica",     "Fagus",   "sylvatica",   "Fagaceae", "wcvp-ex-002", authorship = "L."),
    bb_row("Quercus pedunculata", "Quercus", "pedunculata", "Fagaceae", "wcvp-ex-003",
           status = "SYNONYM", acc_id = "wcvp-ex-001", authorship = "Ehrh.")
  )), "wcvp")
}

# ----------------------------------------------------------------------------
# Spec-defined tables (enrichments, reference tables, register, coverage)
# ----------------------------------------------------------------------------

# A table spec is {"columns": [{"name", "type", "values"}]}; `null` is NA.
read_table_spec <- function(path) {
  spec <- jsonlite::read_json(path, simplifyVector = FALSE)
  cols <- lapply(spec$columns, function(cl) {
    na <- switch(cl$type, character = NA_character_, numeric = NA_real_,
                 integer = NA_integer_, logical = NA,
                 stop(sprintf("%s: column '%s' has unsupported type '%s'",
                              path, cl$name, cl$type), call. = FALSE))
    vapply(cl$values, function(v) if (is.null(v)) na else methods::as(v, cl$type),
           na, USE.NAMES = FALSE)
  })
  names(cols) <- vapply(spec$columns, `[[`, character(1L), "name")
  as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
}

# Every spec target is a directory under data-raw/exampledb/ holding files
# directly (enrichment/<name>/latest, genus_register/latest, ...), named by
# its path without the trailing /latest.
spec_files <- list.files(SPEC, recursive = TRUE)
spec_targets <- unique(sub("/latest/[^/]+$", "", spec_files))

write_spec_target <- function(target) {
  files <- spec_files[startsWith(spec_files, paste0(target, "/latest/"))]
  for (f in files) {
    out <- file.path(OUT, f)
    dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
    if (grepl("\\.json$", f) && basename(f) != "meta.json") {
      vectra::write_vtr(read_table_spec(file.path(SPEC, f)),
                        sub("\\.json$", ".vtr", out))
    } else {
      file.copy(file.path(SPEC, f), out, overwrite = TRUE)
    }
  }
}

# ----------------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------------

all_targets <- c(names(backbones), spec_targets)
targets <- commandArgs(trailingOnly = TRUE)
if (length(targets) == 0L) targets <- all_targets
unknown <- setdiff(targets, all_targets)
if (length(unknown) > 0L) {
  stop("Unknown target(s): ", paste(unknown, collapse = ", "),
       ". Known: ", paste(all_targets, collapse = ", "), call. = FALSE)
}

for (t in targets) {
  unlink(file.path(OUT, t), recursive = TRUE)
  if (t %in% names(backbones)) backbones[[t]]() else write_spec_target(t)
}

cat("Wrote", length(targets), "target(s) to", normalizePath(OUT), "\n")

# Compare the accepted names taxify and WorldFlora give for the same names.
#
# Names are sampled from the WFO backbone taxify reads: species-rank names of
# any status (accepted, synonym, unchecked), with a fixed seed. Both packages
# match them without fuzzy matching, WorldFlora through WFO.match() and
# WFO.one(), taxify through taxify(backbone = "wfo"). The script records how
# many accepted names agree and every name where they differ. WorldFlora reads
# the WFO classification file named in benchmark-worldflora.R, which can be a
# different WFO release from taxify's backbone; the file names both.
#
# Usage (from the repository root, after scripts/benchmark-worldflora.R has
# downloaded the WorldFlora file):
#   Rscript scripts/agreement-worldflora.R
#
# Writes scripts/agreement-worldflora-results.json.

repo <- normalizePath(getwd(), winslash = "/")
if (!dir.exists(file.path(repo, "R"))) stop("run this from the repository root")

N    <- 300L
SEED <- 20261013L
work_dir <- Sys.getenv("TAXIFY_BENCH_DIR",
                       file.path(repo, "dev_notes", "_scratch", "wfo_bench"))
wfo_file <- list.files(work_dir, pattern = "^classification\\.(csv|txt|tsv)$",
                       full.names = TRUE)[1]
if (is.na(wfo_file)) stop("run scripts/benchmark-worldflora.R first")

Sys.setenv(TAXIFY_OFFLINE = "1")
pkgload::load_all(repo, quiet = TRUE)
wfo_data <- data.table::fread(wfo_file, encoding = "UTF-8")

bb <- taxify:::backbone_path("wfo", verbose = FALSE)
pool <- vectra::tbl(bb) |>
  vectra::filter(taxon_rank == "SPECIES") |>
  vectra::select(canonical_name, taxonomic_status) |>
  vectra::collect()
pool <- pool[grepl("^[A-Z][a-z]+ [a-z]+$", pool$canonical_name), ]
set.seed(SEED)
s <- pool[sample(nrow(pool), N), ]

wf <- WorldFlora::WFO.one(
  WorldFlora::WFO.match(spec.data = s$canonical_name, WFO.data = wfo_data,
                        Fuzzy = 0, verbose = FALSE, counter = 1e9),
  verbose = FALSE)
tx <- suppressWarnings(taxify::taxify(s$canonical_name, backbone = "wfo",
                                      fuzzy = FALSE, verbose = FALSE))

wf_acc <- wf$scientificName[match(s$canonical_name, wf$spec.name)]
wf_acc[!nzchar(wf_acc)] <- NA
tx_acc <- tx$accepted_name
same <- !is.na(wf_acc) & !is.na(tx_acc) & wf_acc == tx_acc
diff <- data.frame(input = s$canonical_name, status = s$taxonomic_status,
                   taxify = tx_acc, worldflora = wf_acc)[!same, ]

# Names that differ although both packages matched them, and how many of
# those taxify reports with more than one accepted taxon behind the spelling.
both <- !same & !is.na(wf_acc) & !is.na(tx_acc)
n_multi <- sum(tx$n_ids[both] > 1L, na.rm = TRUE)

# The four names the comparison article matches in taxify, through WorldFlora
# with fuzzy matching, as the article's WorldFlora code runs them.
ex_names <- c("Quercus robur", "Quercus pedonculata", "Pinus silvestris",
              "Rosa canina")
ex <- WorldFlora::WFO.one(
  WorldFlora::WFO.match(spec.data = ex_names, WFO.data = wfo_data,
                        Fuzzy = 0.1, verbose = FALSE, counter = 1e9),
  verbose = FALSE)
example <- data.frame(input = ex$spec.name, accepted = ex$scientificName,
                      fuzzy = ex$Fuzzy)

# A second task in both packages: the synonyms of one accepted name.
wf_syn <- WorldFlora::WFO.synonyms(taxon = "Picea abies", WFO.data = wfo_data)
wf_syn_names <- setdiff(unique(wf_syn$scientificName), "Picea abies")
tx_syn <- taxify::synonyms("Picea abies", backbone = "wfo", verbose = FALSE)
tx_syn_names <- unique(tx_syn$synonym)
synonyms_cmp <- list(
  taxon = "Picea abies",
  n_worldflora = length(wf_syn_names),
  n_taxify = length(tx_syn_names),
  n_shared = length(intersect(wf_syn_names, tx_syn_names))
)

meta <- taxify:::read_version_meta("wfo")
out <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  script = "scripts/agreement-worldflora.R",
  seed = SEED,
  n_names = N,
  status_mix = as.list(table(s$taxonomic_status)),
  n_agree = sum(same),
  n_differ = sum(!same & !is.na(wf_acc) & !is.na(tx_acc)),
  n_worldflora_none = sum(is.na(wf_acc)),
  n_taxify_none = sum(is.na(tx_acc)),
  n_differ_multiple_ids = n_multi,
  differences = diff,
  example = example,
  synonyms = synonyms_cmp,
  snapshot = list(taxify_backbone_version = if (is.null(meta$version)) NA else meta$version,
                  worldflora_file = basename(wfo_file)),
  platform = list(r = paste(R.version$major, R.version$minor, sep = "."),
                  taxify = as.character(utils::packageVersion("taxify")),
                  worldflora = as.character(utils::packageVersion("WorldFlora")))
)
path <- file.path(repo, "scripts", "agreement-worldflora-results.json")
jsonlite::write_json(out, path, pretty = TRUE, auto_unbox = TRUE, dataframe = "rows")
message("wrote ", path)

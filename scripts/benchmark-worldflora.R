# Benchmark: taxify vs WorldFlora on the same WFO snapshot
#
# Produces the figures quoted in README.md. Both packages read the same Zenodo
# Darwin Core backbone release, so the comparison is between the two matching
# implementations and not between two versions of WFO:
#
#   taxify     -> the .vtr taxifydb built from that archive (columnar, on disk)
#   WorldFlora -> the classification TSV inside that archive (data.table in RAM)
#
# Names are drawn from the backbone itself with a fixed seed, so the corpus is
# reproducible from the backbone version alone. The fuzzy corpus is the exact
# corpus with one substituted character per epithet, which forces both packages
# off their exact path.
#
# Usage (from the repository root):
#   Rscript scripts/benchmark-worldflora.R
#
# Writes scripts/benchmark-worldflora-results.json.

repo <- normalizePath(getwd(), winslash = "/")
if (!dir.exists(file.path(repo, "R"))) {
  stop("run this from the taxify repository root")
}

work_dir <- Sys.getenv("TAXIFY_BENCH_DIR",
                       file.path(repo, "dev_notes", "_scratch", "wfo_bench"))
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)

N_EXACT <- 1000L
N_FUZZY <- 1000L
N_SCALE <- 5000L
SEED    <- 20260722L
ZENODO  <- "https://zenodo.org/records/14538251/files/_DwC_backbone_R.zip"

say <- function(...) {
  message(format(Sys.time(), "[%H:%M:%S] "), sprintf(...))
  utils::flush.console()
}

# Elapsed time plus the peak R heap the call reached, so the memory figures are
# measured on the same runs as the timings.
timed <- function(label, expr) {
  gc(reset = TRUE, full = TRUE)
  t <- system.time(value <- force(expr))
  g <- gc()
  # gc() reports "max used" in cells, with the megabyte equivalent in the
  # column immediately after it; sum Ncells and Vcells for the heap total.
  peak <- sum(g[, grep("max used", colnames(g))[1L] + 1L])
  say("%-36s %9.2f s   peak R heap %7.1f MB", label, t[["elapsed"]], peak)
  list(value = value, elapsed = unname(t[["elapsed"]]), peak_mb = peak)
}

# ---- The shared snapshot -----------------------------------------------------

zip_path <- file.path(work_dir, "_DwC_backbone_R.zip")
if (!file.exists(zip_path)) {
  say("downloading the WFO Darwin Core backbone from Zenodo ...")
  old <- options(timeout = 7200)
  utils::download.file(ZENODO, zip_path, mode = "wb", quiet = FALSE)
  options(old)
}

members <- utils::unzip(zip_path, list = TRUE)$Name
member  <- members[grepl("classification\\.(txt|csv|tsv)$", members)][1]
if (is.na(member)) stop("no classification file inside ", zip_path)

wfo_file <- file.path(work_dir, basename(member))
if (!file.exists(wfo_file)) {
  say("extracting %s ...", member)
  utils::unzip(zip_path, files = member, exdir = work_dir, junkpaths = TRUE)
}
say("WorldFlora backbone file: %s (%.0f MB)",
    basename(wfo_file), file.size(wfo_file) / 1024^2)

# ---- The corpus --------------------------------------------------------------

pkgload::load_all(repo, quiet = TRUE)

bb_path <- taxify:::backbone_path("wfo", verbose = FALSE)
say("taxify backbone: %s (%.0f MB)", basename(bb_path), file.size(bb_path) / 1024^2)

pool <- vectra::tbl(bb_path) |>
  vectra::filter(taxon_rank == "SPECIES", taxonomic_status == "ACCEPTED") |>
  vectra::select(canonical_name) |>
  vectra::collect()
pool <- unique(pool$canonical_name)
pool <- pool[grepl("^[A-Z][a-z]+ [a-z]+$", pool)]           # clean binomials only
say("candidate pool: %d accepted binomials", length(pool))

set.seed(SEED)
names_scale <- sample(pool, N_SCALE)
names_exact <- names_scale[seq_len(N_EXACT)]

# One substituted character in the epithet: far enough from the original to miss
# the exact index, close enough that both packages resolve it by distance.
typo <- function(x) {
  vapply(strsplit(x, " ", fixed = TRUE), function(p) {
    ep  <- p[2]
    pos <- max(2L, nchar(ep) - 1L)
    substr(ep, pos, pos) <- if (substr(ep, pos, pos) == "a") "o" else "a"
    paste(p[1], ep)
  }, character(1))
}
names_fuzzy       <- typo(names_exact)
names_fuzzy_scale <- typo(names_scale)

results <- list()

# ---- taxify ------------------------------------------------------------------

say("--- taxify %s ---", as.character(utils::packageVersion("taxify")))

r <- timed("taxify backbone load (first call)",
           taxify("Quercus robur", backend = "wfo", verbose = FALSE))
results$taxify_load <- list(elapsed = r$elapsed, peak_mb = r$peak_mb)

r <- timed(sprintf("taxify exact, %d names", N_EXACT),
           taxify(names_exact, backend = "wfo", verbose = FALSE))
results$taxify_exact <- list(n = N_EXACT, elapsed = r$elapsed, peak_mb = r$peak_mb,
                             matched = sum(r$value$match_type != "none"))

r <- timed(sprintf("taxify fuzzy, %d names", N_FUZZY),
           taxify(names_fuzzy, backend = "wfo", verbose = FALSE))
results$taxify_fuzzy <- list(n = N_FUZZY, elapsed = r$elapsed, peak_mb = r$peak_mb,
                             matched = sum(r$value$match_type != "none"))

r <- timed(sprintf("taxify fuzzy, %d names", N_SCALE),
           taxify(names_fuzzy_scale, backend = "wfo", verbose = FALSE))
results$taxify_fuzzy_scale <- list(n = N_SCALE, elapsed = r$elapsed,
                                   peak_mb = r$peak_mb,
                                   matched = sum(r$value$match_type != "none"))

# ---- WorldFlora --------------------------------------------------------------

say("--- WorldFlora %s ---", as.character(utils::packageVersion("WorldFlora")))

# The same call WFO.match() makes internally when handed WFO.file.
r <- timed("WorldFlora backbone load (CSV into RAM)",
           data.table::fread(wfo_file, encoding = "UTF-8"))
wfo_data <- r$value
results$worldflora_load <- list(elapsed = r$elapsed, peak_mb = r$peak_mb,
                                nrow = nrow(wfo_data))

r <- timed(sprintf("WorldFlora exact, %d names", N_EXACT),
           WorldFlora::WFO.match(spec.data = names_exact, WFO.data = wfo_data,
                                 Fuzzy = FALSE, verbose = FALSE, counter = 1e9))
results$worldflora_exact <- list(n = N_EXACT, elapsed = r$elapsed,
                                 peak_mb = r$peak_mb)

r <- timed(sprintf("WorldFlora fuzzy, %d names", N_FUZZY),
           WorldFlora::WFO.match(spec.data = names_fuzzy, WFO.data = wfo_data,
                                 Fuzzy = 0.1, verbose = FALSE, counter = 1e9))
results$worldflora_fuzzy <- list(n = N_FUZZY, elapsed = r$elapsed,
                                 peak_mb = r$peak_mb)

# ---- Provenance --------------------------------------------------------------

meta <- taxify:::read_version_meta("wfo")

out <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  script       = "scripts/benchmark-worldflora.R",
  git_sha      = tryCatch(system2("git", c("rev-parse", "--short", "HEAD"),
                                  stdout = TRUE),
                          error = function(e) NA_character_),
  seed         = SEED,
  corpus       = paste("accepted WFO binomials sampled from the backbone;",
                       "the fuzzy corpus substitutes one character per epithet"),
  snapshot     = list(source = ZENODO,
                      taxify_backbone_version = if (is.null(meta$version)) NA
                                                else meta$version,
                      worldflora_file = basename(wfo_file)),
  platform     = list(
    os         = utils::sessionInfo()$running,
    r          = paste(R.version$major, R.version$minor, sep = "."),
    taxify     = as.character(utils::packageVersion("taxify")),
    vectra     = as.character(utils::packageVersion("vectra")),
    worldflora = as.character(utils::packageVersion("WorldFlora"))
  ),
  results = results
)

json_path <- file.path(repo, "scripts", "benchmark-worldflora-results.json")
jsonlite::write_json(out, json_path, pretty = TRUE, auto_unbox = TRUE, digits = 4)
say("wrote %s", json_path)

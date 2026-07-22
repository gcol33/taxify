# Measure taxify's memory footprint.
#
# Reports resident set size, not the R heap. vectra reads a .vtr through the
# operating system rather than materializing it as R objects, so gc() cannot see
# most of what a backbone costs; RSS is what a user's machine actually pays.
# Each stage runs in its own R process, because RSS never falls back after a
# peak and stages measured in one process would each inherit the last one's
# high-water mark.
#
# Usage (from the repository root):
#   Rscript scripts/benchmark-memory.R
#
# Writes scripts/benchmark-memory-results.json.

repo <- normalizePath(getwd(), winslash = "/")
if (!dir.exists(file.path(repo, "R"))) stop("run this from the repository root")

BACKBONES <- c("wfo", "col", "gbif")
N_NAMES   <- 5000L
SEED      <- 20260722L

rss_mb <- function() {
  pid <- Sys.getpid()
  if (.Platform$OS.type == "windows") {
    out <- system2("powershell", c("-NoProfile", "-Command",
                                   sprintf("(Get-Process -Id %d).WorkingSet64", pid)),
                   stdout = TRUE)
    as.numeric(out[1]) / 1024^2
  } else {
    as.numeric(system2("ps", c("-o", "rss=", "-p", pid), stdout = TRUE)) / 1024
  }
}

# ---- Child process: one stage, printed as a single JSON line ----------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2L && args[1] == "--stage") {
  be    <- args[2]
  stage <- args[3]
  pkgload::load_all(repo, quiet = TRUE)
  base <- rss_mb()

  bb <- taxify:::backbone_path(be, verbose = FALSE)
  after_load <- NA_real_
  after_match <- NA_real_

  if (stage %in% c("load", "match", "fuzzy")) {
    invisible(taxify::taxify("Quercus robur", backend = be, verbose = FALSE))
    after_load <- rss_mb()
  }
  if (stage %in% c("match", "fuzzy")) {
    pool <- vectra::tbl(bb) |>
      vectra::filter(taxon_rank == "SPECIES") |>
      vectra::select(canonical_name) |>
      vectra::collect()
    pool <- unique(pool$canonical_name)
    pool <- pool[grepl("^[A-Z][a-z]+ [a-z]+$", pool)]
    set.seed(SEED)
    nm <- sample(pool, min(N_NAMES, length(pool)))
    if (stage == "fuzzy") {
      nm <- vapply(strsplit(nm, " ", fixed = TRUE), function(p) {
        ep <- p[2]; pos <- max(2L, nchar(ep) - 1L)
        substr(ep, pos, pos) <- if (substr(ep, pos, pos) == "a") "o" else "a"
        paste(p[1], ep)
      }, character(1))
    }
    invisible(taxify::taxify(nm, backend = be, verbose = FALSE))
    after_match <- rss_mb()
  }

  cat(jsonlite::toJSON(list(
    backbone = be, stage = stage,
    vtr_mb = unname(file.size(bb) / 1e6),
    baseline_mb = base, after_load_mb = after_load, after_match_mb = after_match
  ), auto_unbox = TRUE, digits = 4), "\n", sep = "")
  quit(save = "no")
}

# ---- Parent: run each stage in a fresh process ------------------------------

rscript <- file.path(R.home("bin"), "Rscript")
rows <- list()
for (be in BACKBONES) {
  for (stage in c("load", "match", "fuzzy")) {
    message(sprintf("[%s] %s ...", be, stage))
    out <- system2(rscript, c(shQuote(file.path(repo, "scripts", "benchmark-memory.R")),
                              "--stage", be, stage),
                   stdout = TRUE, stderr = FALSE)
    line <- out[length(out)]
    rows[[length(rows) + 1L]] <- jsonlite::fromJSON(line)
    message("   ", line)
  }
}

res <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  script       = "scripts/benchmark-memory.R",
  metric       = "resident set size (WorkingSet64 on Windows), megabytes",
  n_names      = N_NAMES,
  seed         = SEED,
  platform     = list(os = utils::sessionInfo()$running,
                      r = paste(R.version$major, R.version$minor, sep = "."),
                      taxify = as.character(utils::packageVersion("taxify")),
                      vectra = as.character(utils::packageVersion("vectra"))),
  stages = rows
)

path <- file.path(repo, "scripts", "benchmark-memory-results.json")
jsonlite::write_json(res, path, pretty = TRUE, auto_unbox = TRUE, digits = 4)
message("wrote ", path)

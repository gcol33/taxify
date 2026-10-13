# Measure how long taxify() takes as a name list grows.
#
# Names are drawn from the WFO backbone itself with a fixed seed: accepted
# binomials, so every name exists and the exact run resolves all of them. The
# typo list is the same list with one substituted character in the epithet of
# every tenth name, the share of misspelt names a field list of moderate
# quality might carry; those names go through fuzzy matching. Each list size
# runs in its own R process, after one call that loads the backbone, so the
# timings measure matching alone and the load is reported on its own.
#
# Usage (from the repository root, with the WFO backbone installed):
#   Rscript scripts/benchmark-scale.R
#
# Writes scripts/benchmark-scale-results.json.

repo <- normalizePath(getwd(), winslash = "/")
if (!dir.exists(file.path(repo, "R"))) stop("run this from the repository root")

BACKBONE <- "wfo"
SIZES    <- c(1000L, 10000L, 100000L)
TYPO_SHARE <- 0.1
SEED     <- 20261013L

make_names <- function(n, typos) {
  bb <- taxify:::backbone_path(BACKBONE, verbose = FALSE)
  pool <- vectra::tbl(bb) |>
    vectra::filter(taxon_rank == "SPECIES", taxonomic_status == "ACCEPTED") |>
    vectra::select(canonical_name) |>
    vectra::collect()
  pool <- unique(pool$canonical_name)
  pool <- pool[grepl("^[A-Z][a-z]+ [a-z]{4,}$", pool)]
  set.seed(SEED)
  nm <- sample(pool, n)
  if (typos) {
    hit <- seq(1L, n, by = round(1 / TYPO_SHARE))
    nm[hit] <- vapply(strsplit(nm[hit], " ", fixed = TRUE), function(p) {
      ep <- p[2]; pos <- max(2L, nchar(ep) - 1L)
      substr(ep, pos, pos) <- if (substr(ep, pos, pos) == "a") "o" else "a"
      paste(p[1], ep)
    }, character(1))
  }
  nm
}

# ---- Child process: one list size, printed as a single JSON line ------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 3L && args[1] == "--run") {
  n     <- as.integer(args[2])
  typos <- identical(args[3], "typos")
  pkgload::load_all(repo, quiet = TRUE)
  Sys.setenv(TAXIFY_OFFLINE = "1")
  load_s <- system.time(
    invisible(taxify::taxify("Quercus robur", backbone = BACKBONE,
                             verbose = FALSE))
  )[["elapsed"]]
  nm <- make_names(n, typos)
  t <- system.time(
    res <- suppressWarnings(taxify::taxify(nm, backbone = BACKBONE,
                                           verbose = FALSE))
  )[["elapsed"]]
  cat(jsonlite::toJSON(list(
    n_names = n, typos = typos, load_s = load_s, match_s = t,
    match_types = as.list(table(res$match_type))
  ), auto_unbox = TRUE, digits = 4), "\n", sep = "")
  quit(save = "no")
}

# ---- Parent: run each size in a fresh process -------------------------------

rscript <- file.path(R.home("bin"), "Rscript")
rows <- list()
for (typos in c("exact", "typos")) {
  for (n in SIZES) {
    message(sprintf("[%s] %d names ...", typos, n))
    out <- system2(rscript,
                   c(shQuote(file.path(repo, "scripts", "benchmark-scale.R")),
                     "--run", n, typos),
                   stdout = TRUE, stderr = FALSE)
    line <- out[length(out)]
    rows[[length(rows) + 1L]] <- jsonlite::fromJSON(line)
    message("   ", line)
  }
}

cpu <- if (.Platform$OS.type == "windows") {
  system2("powershell", c("-NoProfile", "-Command",
                          "(Get-CimInstance Win32_Processor).Name"),
          stdout = TRUE)[1]
} else {
  NA_character_
}

res <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  script       = "scripts/benchmark-scale.R",
  backbone     = BACKBONE,
  typo_share   = TYPO_SHARE,
  seed         = SEED,
  platform     = list(os = utils::sessionInfo()$running,
                      cpu = cpu,
                      cores = parallel::detectCores(),
                      r = paste(R.version$major, R.version$minor, sep = "."),
                      taxify = as.character(utils::packageVersion("taxify")),
                      vectra = as.character(utils::packageVersion("vectra"))),
  runs = rows
)

path <- file.path(repo, "scripts", "benchmark-scale-results.json")
jsonlite::write_json(res, path, pretty = TRUE, auto_unbox = TRUE, digits = 4)
message("wrote ", path)

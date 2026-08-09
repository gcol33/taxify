# Rewrite the manifest-derived blocks of README.md and the vignettes.
#
# Row counts, download sizes and the backbone/enrichment totals are all in
# inst/manifest.json already, and a hand-kept second copy drifts every release.
# Each generated block is delimited by a pair of HTML comments:
#
#   <!-- manifest:backbone-table -->
#   ... generated ...
#   <!-- /manifest:backbone-table -->
#
# Everything outside the markers is left byte-identical. Run after a manifest
# sync; tests/testthat/test-readme-stats.R fails if a block is stale.
#
# Usage (from the repository root):
#   Rscript scripts/sync-readme-stats.R          # rewrite in place
#   Rscript scripts/sync-readme-stats.R --check  # report drift, exit 1

repo <- normalizePath(getwd(), winslash = "/")
if (!dir.exists(file.path(repo, "R"))) stop("run this from the repository root")
check_only <- "--check" %in% commandArgs(trailingOnly = TRUE)

source(file.path(repo, "scripts", "manifest-stats.R"))

stats <- manifest_stats(file.path(repo, "inst", "manifest.json"))

blocks <- list(
  "backbone-table"   = readme_backbone_table(stats),
  "backbone-sizes"   = vignette_size_table(stats),
  "backbone-count"   = as.character(nrow(stats$backbones)),
  "enrichment-count" = as.character(stats$n_enrichments)
)

targets <- c("README.md",
             file.path("vignettes", c("backbones.Rmd", "large-scale.Rmd",
                                      "enrichments.Rmd", "quickstart.Rmd",
                                      "migration.Rmd")))

# Scalars appear mid-sentence, so they are replaced inline; tables get their own
# lines. Both use the same marker pair, and an HTML comment renders invisibly in
# Markdown either way.
inline <- c("backbone-count", "enrichment-count")

stale <- character(0)
for (f in targets) {
  path <- file.path(repo, f)
  if (!file.exists(path)) next
  txt <- readLines(path, warn = FALSE)
  out <- txt
  for (nm in inline) {
    out <- gsub(
      sprintf("(<!-- manifest:%s -->).*?(<!-- /manifest:%s -->)", nm, nm),
      sprintf("\\1%s\\2", blocks[[nm]]), out, perl = TRUE
    )
  }
  for (nm in setdiff(names(blocks), inline)) {
    open  <- sprintf("<!-- manifest:%s -->", nm)
    close <- sprintf("<!-- /manifest:%s -->", nm)
    i <- which(trimws(out) == open)
    j <- which(trimws(out) == close)
    if (length(i) == 0L) next
    if (length(i) != length(j)) {
      stop(sprintf("%s: unbalanced markers for '%s'", f, nm))
    }
    for (k in rev(seq_along(i))) {
      out <- c(out[seq_len(i[k])], blocks[[nm]], out[j[k]:length(out)])
    }
  }
  if (!identical(out, txt)) {
    stale <- c(stale, f)
    if (!check_only) {
      # Binary, so the line endings are LF on every platform. A text-mode
      # connection writes CRLF on Windows, which rewrites every line of every
      # target and buries the handful of changed figures in a whole-file diff.
      con <- file(path, open = "wb")
      on.exit(close(con), add = TRUE)
      writeLines(out, con)
      close(con)
      on.exit()
    }
  }
}

if (check_only) {
  if (length(stale)) {
    message("stale manifest blocks in: ", paste(stale, collapse = ", "))
    quit(status = 1L)
  }
  message("all manifest blocks current")
} else if (length(stale)) {
  message("rewrote: ", paste(stale, collapse = ", "))
} else {
  message("nothing to rewrite")
}

# Copy a freshly built enrichment .vtr + meta.json from taxify-backbones
# output dir into the local taxify enrichment cache, where ensure_enrichment()
# picks it up at runtime.
#
# Usage:  Rscript scripts/deploy_enrichment.R <name> [<name> ...]

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) {
  stop("Usage: Rscript scripts/deploy_enrichment.R <name> [<name> ...]",
       call. = FALSE)
}

src_root <- "C:/Users/Gilles Colling/Documents/dev/taxify-backbones/output/enrichment"
dst_root <- file.path(Sys.getenv("APPDATA"), "R", "data", "R", "taxify",
                      "enrichment")

for (name in args) {
  src_dir <- file.path(src_root, name)
  vtr_src <- file.path(src_dir, sprintf("%s.vtr", name))
  meta_src <- file.path(src_dir, "meta.json")

  if (!file.exists(vtr_src)) {
    message(sprintf("[%s] SKIP: %s not found", name, vtr_src))
    next
  }

  dst_dir <- file.path(dst_root, name, "latest")
  dir.create(dst_dir, recursive = TRUE, showWarnings = FALSE)

  vtr_dst <- file.path(dst_dir, sprintf("%s.vtr", name))
  meta_dst <- file.path(dst_dir, "meta.json")

  # Backup old files for rollback (one rotation only)
  for (p in c(vtr_dst, meta_dst)) {
    if (file.exists(p)) {
      bak <- paste0(p, ".bak")
      if (file.exists(bak)) file.remove(bak)
      file.rename(p, bak)
    }
  }

  file.copy(vtr_src, vtr_dst, overwrite = TRUE)
  if (file.exists(meta_src)) file.copy(meta_src, meta_dst, overwrite = TRUE)

  size_mb <- file.size(vtr_dst) / 1048576
  message(sprintf("[%s] deployed %.1f MB to %s", name, size_mb, dst_dir))
}

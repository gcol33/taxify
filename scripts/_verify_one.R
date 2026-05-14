# Quick row count + sample probe for a deployed enrichment.
# Usage:  Rscript scripts/_verify_one.R <name>

suppressPackageStartupMessages(library(vectra))

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript scripts/_verify_one.R <name>",
                        call. = FALSE)
name <- args[1L]

vtr <- file.path(Sys.getenv("APPDATA"), "R", "data", "R", "taxify",
                 "enrichment", name, "latest", sprintf("%s.vtr", name))
if (!file.exists(vtr)) stop(sprintf("not found: %s", vtr), call. = FALSE)

df <- vectra::tbl(vtr) |> vectra::collect()
cat(sprintf("[%s] %d rows, %.1f MB\n",
            name, nrow(df), file.size(vtr) / 1048576))
cat("columns:", paste(names(df), collapse = ", "), "\n")
cat("head:\n")
print(utils::head(df, 3L))

meta_path <- file.path(dirname(vtr), "meta.json")
if (file.exists(meta_path)) {
  m <- jsonlite::read_json(meta_path)
  cat(sprintf("\nmeta: version=%s built=%s license=%s\n",
              m$version %||% "?", m$built %||% "?", m$license %||% "?"))
}

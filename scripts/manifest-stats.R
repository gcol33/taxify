# Manifest-derived figures for the generated documentation blocks.
#
# Sourced by scripts/sync-readme-stats.R. Every number here comes from
# inst/manifest.json; every label comes from taxify's own backbone registry, so
# a backbone added to the package appears in the docs without a second edit.

manifest_stats <- function(manifest_path) {
  m <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)

  # Always the source tree's registry, never an older installed copy.
  pkgload::load_all(dirname(dirname(manifest_path)), quiet = TRUE)
  reg <- taxify:::.backbone_registry()

  entry <- m$backends[reg$name]
  reg$display  <- sub("^the ", "", sub(" backbone$", "", reg$label))
  reg$nrow     <- vapply(entry, function(e) as.numeric(e$nrow %||% NA), numeric(1))
  reg$bytes    <- vapply(entry, function(e) as.numeric(e$full_size %||% NA), numeric(1))
  reg$version  <- vapply(entry, function(e) as.character(e$latest %||% NA), character(1))

  list(backbones     = reg,
       n_enrichments = length(m$enrichments),
       total_bytes   = sum(reg$bytes, na.rm = TRUE))
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Download sizes are quoted in decimal MB / GB, the unit a download is measured
# in; the manifest stores plain bytes.
fmt_size <- function(bytes) {
  ifelse(is.na(bytes), "-",
         ifelse(bytes >= 1e9, sprintf("%.1f GB", bytes / 1e9),
                sprintf("%.0f MB", bytes / 1e6)))
}

fmt_names <- function(n) {
  ifelse(is.na(n), "-",
         ifelse(n >= 1e6, sprintf("%.1fM", n / 1e6), sprintf("%.0fk", n / 1e3)))
}

readme_backbone_table <- function(stats) {
  b <- stats$backbones
  c(
    "| Backbone | Scope | Names | Download |",
    "|---|---|---|---|",
    sprintf("| [%s](%s) | %s | %s | %s |",
            b$display, b$source, b$scope, fmt_names(b$nrow), fmt_size(b$bytes))
  )
}

vignette_size_table <- function(stats) {
  b <- stats$backbones
  c(
    "| Backbone | Names | Download | Version |",
    "|---|---|---|---|",
    sprintf("| %s | %s | %s | %s |",
            b$display, fmt_names(b$nrow), fmt_size(b$bytes), b$version),
    sprintf("| **All %d** | **%s** | **%s** | |",
            nrow(b), fmt_names(sum(b$nrow, na.rm = TRUE)),
            fmt_size(stats$total_bytes))
  )
}

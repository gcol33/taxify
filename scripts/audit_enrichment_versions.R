#  Audit upstream vs local enrichment versions
#
#  - Reads taxify/inst/manifest.json for each enrichment's source spec
#  - Reads installed meta.json (under taxify_data_dir) for the locally built version
#  - Probes upstream for the latest available version
#  - Prints a table: name | local | upstream | status
#  - Writes JSON result to scripts/enrichment_audit.json

suppressPackageStartupMessages({
  library(jsonlite)
})

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a[1])) b else a

manifest_path <- "inst/manifest.json"
manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
enrichments <- manifest$enrichments

local_root <- file.path(Sys.getenv("APPDATA"), "R", "data", "R", "taxify",
                        "enrichment")

# ---- upstream probes ----

probe_zenodo <- function(url) {
  m <- regmatches(url, regexpr("records/[0-9]+", url))
  if (!length(m)) return(NA_character_)
  rid <- sub("records/", "", m)
  api <- sprintf("https://zenodo.org/api/records/%s", rid)
  r <- tryCatch(jsonlite::read_json(api), error = function(e) NULL)
  if (is.null(r)) return(NA_character_)
  ver <- r$metadata$version %||% r$metadata$publication_date %||% NA_character_
  as.character(ver)
}

probe_figshare <- function(url) {
  m <- regmatches(url, regexpr("files/[0-9]+", url))
  if (!length(m)) return(NA_character_)
  fid <- sub("files/", "", m)
  api <- sprintf("https://api.figshare.com/v2/files/%s", fid)
  r <- tryCatch(jsonlite::read_json(api), error = function(e) NULL)
  if (is.null(r) || is.null(r$article_id)) return(NA_character_)
  vurl <- sprintf("https://api.figshare.com/v2/articles/%s/versions",
                  r$article_id)
  v <- tryCatch(jsonlite::read_json(vurl), error = function(e) NULL)
  if (is.null(v) || !length(v)) return(NA_character_)
  as.character(v[[1]]$version)
}

probe_dryad <- function(url) {
  m <- regmatches(url, regexpr("doi%3A[^/?&]+", url))
  if (!length(m)) return(NA_character_)
  doi <- utils::URLdecode(m)
  api <- sprintf("https://datadryad.org/api/v2/datasets/%s",
                 utils::URLencode(doi, reserved = TRUE))
  r <- tryCatch(jsonlite::read_json(api), error = function(e) NULL)
  if (is.null(r)) return(NA_character_)
  as.character(r$versionNumber %||% NA_character_)
}

probe_http_lastmod <- function(url) {
  hdr <- tryCatch(curlGetHeaders(url), error = function(e) character(0))
  lm <- grep("^Last-Modified:", hdr, value = TRUE, ignore.case = TRUE)
  if (!length(lm)) return(NA_character_)
  ds <- trimws(sub("^Last-Modified:\\s*", "", lm[1], ignore.case = TRUE))
  d <- suppressWarnings(as.Date(ds, format = "%a, %d %b %Y %H:%M:%S"))
  if (is.na(d)) return(ds)
  format(d, "%Y.%m")
}

probe_gbif_dataset <- function() {
  api <- "https://api.gbif.org/v1/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c"
  r <- tryCatch(jsonlite::read_json(api), error = function(e) NULL)
  if (is.null(r)) return(NA_character_)
  d <- as.Date(substr(r$modified %||% r$pubDate %||% "", 1, 10))
  if (is.na(d)) return(NA_character_)
  format(d, "%Y.%m")
}

# Source-specific dispatcher (returns upstream version string or NA + note)
probe_upstream <- function(name, entry) {
  url  <- entry$source_url %||% NA_character_
  fmt  <- entry$source_format %||% NA_character_
  stat <- isTRUE(entry$static)

  if (stat) return(list(version = entry$source_version, note = "static"))

  if (is.na(url)) return(list(version = NA_character_, note = "no source_url"))

  if (grepl("zenodo\\.org", url))    return(list(version = probe_zenodo(url),
                                                  note = "zenodo"))
  if (grepl("figshare\\.com", url))  return(list(version = probe_figshare(url),
                                                  note = "figshare"))
  if (grepl("dryad", url))           return(list(version = probe_dryad(url),
                                                  note = "dryad"))
  if (grepl("hosted-datasets\\.gbif\\.org", url) ||
      grepl("kew\\.org", url))       return(list(
                                          version = probe_http_lastmod(url),
                                          note = "http last-modified"))
  if (grepl("api\\.gbif\\.org", url) ||
      identical(fmt, "gbif_api"))    return(list(
                                          version = probe_gbif_dataset(),
                                          note = "gbif api"))
  list(version = NA_character_,
       note = sprintf("no probe for url=%s (fmt=%s)", url, fmt))
}

read_local_meta <- function(name) {
  meta <- file.path(local_root, name, "latest", "meta.json")
  if (!file.exists(meta)) return(list(version = NA_character_,
                                      built = NA_character_))
  m <- jsonlite::read_json(meta)
  list(
    version = as.character(m$version %||% m$source_version %||% NA_character_),
    built   = as.character(m$built_on %||% m$build_date  %||% NA_character_)
  )
}

# ---- run ----

results <- list()
for (name in names(enrichments)) {
  cat(sprintf("[%s] probing...\n", name))
  loc <- read_local_meta(name)
  upstream <- probe_upstream(name, enrichments[[name]])
  status <- if (isTRUE(enrichments[[name]]$static)) {
    "STATIC"
  } else if (is.na(upstream$version)) {
    "UNKNOWN"
  } else if (is.na(loc$version)) {
    "NO_LOCAL"
  } else if (identical(loc$version, upstream$version)) {
    "CURRENT"
  } else {
    "OUTDATED"
  }
  results[[name]] <- list(
    name = name,
    local_version = loc$version,
    upstream_version = upstream$version,
    status = status,
    source_format = enrichments[[name]]$source_format %||% NA_character_,
    static = isTRUE(enrichments[[name]]$static),
    note = upstream$note,
    built = loc$built
  )
}

df <- do.call(rbind, lapply(results, function(r) {
  data.frame(
    name = r$name,
    local = r$local_version %||% "",
    upstream = r$upstream_version %||% "",
    status = r$status,
    fmt = r$source_format %||% "",
    note = r$note %||% "",
    stringsAsFactors = FALSE
  )
}))

cat("\n")
print(df, row.names = FALSE)

cat("\n=== Status counts ===\n")
print(table(df$status))

# Persist for downstream tasks
out_path <- "scripts/enrichment_audit.json"
jsonlite::write_json(results, out_path, pretty = TRUE, auto_unbox = TRUE)
cat(sprintf("\nWrote %s\n", out_path))

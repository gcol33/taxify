# ---- Citation helpers ----
#
# cite() prints and optionally writes citations for all data sources used
# in a taxify_result (backends + enrichments + taxify itself).


#' Cite data sources used in a taxify result
#'
#' Prints formatted citations for the taxonomic backbone(s), enrichment
#' layers, and the taxify package itself. Optionally writes a BibTeX file.
#'
#' @param x A `taxify_result` object.
#' @param file Optional file path. If provided, BibTeX entries are written
#'   to this file (extension should be `.bib`).
#' @return `x`, invisibly (pipe-friendly).
#'
#' @examples
#' \donttest{
#' result <- taxify("Quercus robur", backend = "wfo")
#' result |> cite()
#' result |> cite(file = tempfile(fileext = ".bib"))
#' }
#'
#' @export
cite <- function(x, file = NULL) {
  meta <- attr(x, "taxify_meta")
  if (is.null(meta)) {
    stop("x has no taxify_meta attribute -- was it created by taxify()?",
         call. = FALSE)
  }

  citations <- collect_citations(meta)

  # Console output
  rule <- strrep("\u2500", 60)
  cat(sprintf("\u2500\u2500 taxify citations %s\n", rule))
  for (i in seq_along(citations)) {
    txt <- format_citation_text(citations[[i]])
    cat(sprintf("  [%d] %s\n", i, txt))
  }
  cat(sprintf("  %s\n", rule))

  # BibTeX file
  if (!is.null(file)) {
    bibtex <- vapply(citations, format_bibtex_entry, character(1L))
    writeLines(paste(bibtex, collapse = "\n\n"), file)
    cat(sprintf("  BibTeX written to: %s\n", file))
  }

  invisible(x)
}


# ---- Internal helpers ----

#' Collect citation objects for all sources used in a result
#'
#' @param meta The `taxify_meta` attribute list.
#' @return A list of citation lists, each with at least `key`, `type`,
#'   `authors`, `year`, `title`, and either `doi`/`journal` or `url`.
#' @noRd
collect_citations <- function(meta) {
  citations <- list()

  # 1. taxify itself
  pkg_ver <- tryCatch(
    as.character(utils::packageVersion("taxify")),
    error = function(e) "dev"
  )
  citations <- c(citations, list(list(
    key     = paste0("taxify", gsub("\\.", "", pkg_ver)),
    type    = "misc",
    authors = "Colling G",
    year    = format(Sys.Date(), "%Y"),
    title   = sprintf("taxify: Offline Taxonomic Name Matching (version %s)",
                      pkg_ver),
    url     = "https://github.com/gcol33/taxify"
  )))

  # Fetch manifest for citation metadata
  manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)

  # 2. Backends
  backends <- meta$backend
  if (!is.null(backends) && length(backends) > 0L) {
    for (be in backends) {
      cit <- extract_manifest_citation(manifest, "backends", be)
      if (!is.null(cit)) {
        citations <- c(citations, list(cit))
      } else {
        # Fallback: minimal citation from meta
        citations <- c(citations, list(list(
          key     = paste0(be, gsub("\\.", "", meta$version %||% "")),
          type    = "misc",
          authors = toupper(be),
          year    = sub("^(\\d{4}).*", "\\1", meta$version %||% ""),
          title   = sprintf("%s Backbone Taxonomy", toupper(be)),
          url     = NA_character_
        )))
      }
    }
  }

  # 3. Enrichments
  enrichments <- meta$enrichments
  if (!is.null(enrichments) && length(enrichments) > 0L) {
    for (e in enrichments) {
      cit <- extract_manifest_citation(manifest, "enrichments", e$name)
      if (!is.null(cit)) {
        citations <- c(citations, list(cit))
      } else {
        # Fallback: reconstruct from registered enrichment metadata
        citations <- c(citations, list(list(
          key     = paste0(e$name, gsub("\\.", "", e$version %||% "")),
          type    = "misc",
          authors = e$source %||% e$name,
          year    = sub("^(\\d{4}).*", "\\1", e$version %||% ""),
          title   = e$name,
          url     = NA_character_
        )))
      }
    }
  }

  citations
}


#' Extract a citation object from the manifest
#'
#' @param manifest Parsed manifest list.
#' @param section `"backends"` or `"enrichments"`.
#' @param name Entry name (e.g., `"wfo"`, `"eive"`).
#' @return A citation list, or NULL.
#' @noRd
extract_manifest_citation <- function(manifest, section, name) {
  if (is.null(manifest)) return(NULL)
  entry <- manifest[[section]][[name]]
  if (is.null(entry) || is.null(entry$citation)) return(NULL)
  entry$citation
}


#' Format a citation object as human-readable text
#'
#' @param cit A citation list.
#' @return Character string.
#' @noRd
format_citation_text <- function(cit) {
  authors <- cit$authors %||% "Unknown"
  year    <- cit$year    %||% ""
  title   <- cit$title   %||% ""

  # Base: Authors (Year). Title.
  base <- sprintf("%s (%s). %s.", authors, year, title)

  # Article: add journal, volume, pages
  if (identical(cit$type, "article")) {
    journal <- cit$journal %||% ""
    vol     <- cit$volume  %||% ""
    pages   <- cit$pages   %||% ""
    if (nzchar(journal)) {
      base <- sprintf("%s (%s). %s. %s", authors, year, title, journal)
      if (nzchar(vol))   base <- paste0(base, " ", vol)
      if (nzchar(pages)) base <- paste0(base, ":", pages)
      base <- paste0(base, ".")
    }
  }

  # DOI or URL
  doi <- cit$doi %||% NA_character_
  url <- cit$url %||% NA_character_
  if (!is.na(doi) && nzchar(doi)) {
    base <- paste0(base, " doi:", doi)
  } else if (!is.na(url) && nzchar(url)) {
    base <- paste0(base, " ", url)
  }

  base
}


#' Format a citation object as a BibTeX entry
#'
#' @param cit A citation list.
#' @return Character string (one complete BibTeX entry).
#' @noRd
format_bibtex_entry <- function(cit) {
  bib_type <- if (identical(cit$type, "article")) "article" else "misc"
  key      <- cit$key %||% "unknown"

  fields <- character(0L)
  add_field <- function(name, value) {
    if (!is.null(value) && !is.na(value) && nzchar(value)) {
      fields[[length(fields) + 1L]] <<- sprintf("  %s = {%s}", name, value)
    }
  }

  add_field("author",  cit$authors)
  add_field("year",    cit$year)
  add_field("title",   cit$title)
  add_field("journal", cit$journal)
  add_field("volume",  cit$volume)
  add_field("pages",   cit$pages)
  add_field("doi",     cit$doi)
  add_field("url",     cit$url)

  paste0(
    sprintf("@%s{%s,\n", bib_type, key),
    paste(fields, collapse = ",\n"),
    "\n}"
  )
}


#' Build a compact citation footer for print.taxify_result()
#'
#' @param meta The `taxify_meta` attribute list.
#' @return Character string, e.g., `"WFO 2024-12, EIVE 1.0"`.
#' @noRd
cite_footer <- function(meta) {
  parts <- character(0L)

  # Backends
  backends <- meta$backend
  if (!is.null(backends)) {
    version <- meta$version %||% ""
    if (length(backends) == 1L && nzchar(version)) {
      parts <- c(parts, sprintf("%s %s", toupper(backends), version))
    } else {
      parts <- c(parts, paste(toupper(backends), collapse = " + "))
    }
  }

  # Enrichments
  enrichments <- meta$enrichments
  if (!is.null(enrichments) && length(enrichments) > 0L) {
    for (e in enrichments) {
      label <- e$source %||% e$name
      if (!is.na(e$version) && nzchar(e$version)) {
        label <- paste(label, e$version)
      }
      parts <- c(parts, label)
    }
  }

  paste(parts, collapse = ", ")
}

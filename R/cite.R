# ---- Citation helpers ----
#
# cite() prints and optionally writes citations for all data sources used
# in a taxify_result (backbones + enrichments + taxify itself).


#' Cite data sources used in a taxify result
#'
#' Prints formatted citations for the taxonomic backbone(s), enrichment
#' layers, and the taxify package itself. Optionally writes a BibTeX file.
#'
#' Given reference ids instead of a result, `cite()` resolves them to the works
#' a trait value was taken from: the per-value references [add_trait()] returns
#' with `provenance = TRUE` (`<trait>_refs`), or a door's `<col>_source` column
#' read with `source =`.
#'
#' @param x A `taxify_result` object, or a character vector of reference ids
#'   (cells of `<enrichment>:<id>` joined by `|`, as in `<trait>_refs`).
#' @param file Optional file path. If provided, BibTeX entries are written
#'   to this file (extension should be `.bib`).
#' @param source For a character `x` only: `NULL` (default) when the ids carry
#'   their enrichment prefix, or the enrichment the bare ids belong to (e.g.
#'   `"austraits"` for the `dispersal_syndrome_source` column of
#'   `add_austraits(cols = "all")`).
#' @param ... Unused.
#' @return For a `taxify_result`, `x`, invisibly (pipe-friendly). For reference
#'   ids, invisibly, a data.frame with one row per distinct id: `ref` (the
#'   qualified id), `source`, `ref_id`, `citation`, `doi`, and any further
#'   columns the source's reference table carries.
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' result <- taxify("Quercus robur", backbone = "wfo")
#' result |> cite()
#' result |> cite(file = tempfile(fileext = ".bib"))
#'
#' options(old)
#'
#' @export
cite <- function(x, ...) {
  UseMethod("cite")
}


#' @rdname cite
#' @export
cite.default <- function(x, file = NULL, ...) {
  meta <- attr(x, "taxify_meta")
  download <- attr(x, "gbif_download")
  if (is.null(meta) && is.null(download)) {
    stop("x has no taxify_meta attribute -- was it created by taxify()?",
         call. = FALSE)
  }

  citations <- if (is.null(meta)) list() else collect_citations(meta)

  # Console output
  rule <- strrep("\u2500", 60)
  cat(sprintf("\u2500\u2500 taxify citations %s\n", rule))
  for (i in seq_along(citations)) {
    txt <- format_citation_text(citations[[i]])
    cat(sprintf("  [%d] %s\n", i, txt))
  }
  # A GBIF download is cited by its own DOI, separately from the backbone the
  # names were matched against, because it is a distinct archived dataset.
  # A list too long for one GBIF query is split across several downloads, each
  # with its own DOI, so every one of them is reported.
  n <- length(citations)
  for (key in download) {
    dl <- gbif_download_citation(key)
    if (is.null(dl)) next
    n <- n + 1L
    cat(sprintf("  [%d] %s\n", n, dl$text))
  }
  cat(sprintf("  %s\n", rule))

  # BibTeX file
  if (!is.null(file)) {
    bibtex <- vapply(citations, format_bibtex_entry, character(1L))
    for (key in download) {
      dl <- gbif_download_citation(key)
      if (is.null(dl) || is.na(dl$doi)) next
      bibtex <- c(bibtex, sprintf(paste0(
        "@misc{gbif_download_%s,\n",
        "  title = {GBIF Occurrence Download},\n",
        "  author = {{GBIF.org}},\n",
        "  year = {%s},\n",
        "  doi = {%s},\n",
        "  note = {Download key %s}\n}"),
        gsub("[^A-Za-z0-9]", "", key),
        format(Sys.Date(), "%Y"), dl$doi, key))
    }
    writeLines(paste(bibtex, collapse = "\n\n"), file)
    cat(sprintf("  BibTeX written to: %s\n", file))
  }

  invisible(x)
}


#' @rdname cite
#' @export
cite.character <- function(x, file = NULL, source = NULL, ...) {
  refs <- resolve_ref_ids(parse_ref_ids(x, source = source))

  rule <- strrep("\u2500", 60)
  cat(sprintf("\u2500\u2500 taxify references %s\n", rule))
  for (i in seq_len(nrow(refs))) {
    txt <- refs$citation[i]
    if (is.na(txt)) {
      note <- if (is.null(refs$note)) NA_character_ else refs$note[i]
      txt  <- if (is.na(note)) "(no citation)" else paste0("(no citation) ", note)
    }
    if (!is.na(refs$doi[i]) && nzchar(refs$doi[i]) &&
        !grepl(refs$doi[i], txt, fixed = TRUE)) {
      txt <- paste0(txt, " doi:", refs$doi[i])
    }
    cat(sprintf("  [%s] %s\n", refs$ref[i], txt))
  }
  cat(sprintf("  %s\n", rule))

  if (!is.null(file)) {
    bibtex <- vapply(which(!is.na(refs$citation)), function(i) {
      format_bibtex_entry(list(
        key  = gsub("[^A-Za-z0-9_:.-]", "_", refs$ref[i]),
        type = "misc",
        note = refs$citation[i],
        doi  = refs$doi[i]
      ))
    }, character(1L))
    writeLines(paste(bibtex, collapse = "\n\n"), file)
    cat(sprintf("  BibTeX written to: %s\n", file))
  }

  invisible(refs)
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
  backbones <- meta$backbone
  if (!is.null(backbones) && length(backbones) > 0L) {
    for (be in backbones) {
      cits <- extract_manifest_citations(manifest, "backends", be)
      if (length(cits) > 0L) {
        citations <- c(citations, cits)
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

  # 3. Enrichments -- only those that actually contributed a value to the
  # result. A source queried but matching no rows (n_matched == 0), e.g. a bird
  # trait layer on a plant, or an add_trait() source with no data for these
  # species, is dropped rather than cited.
  enrichments <- meta$enrichments
  if (!is.null(enrichments) && length(enrichments) > 0L) {
    for (e in enrichments) {
      if (!enrichment_contributed(e)) next
      cits <- extract_manifest_citations(manifest, "enrichments", e$name)
      if (length(cits) > 0L) {
        citations <- c(citations, cits)
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

  # Dedup: the same source can be registered more than once (a door plus an
  # add_trait() call, or repeated calls). Keep the first citation per key.
  keys <- vapply(citations, function(c) c$key %||% "", character(1L))
  citations[!duplicated(keys) | !nzchar(keys)]
}


#' Extract the citation objects of a manifest entry
#'
#' An entry's `citation` is either one citation object or an array of them,
#' for a source whose data rest on more than one work (a dataset release and
#' the paper that introduced it). The first element is the work the data
#' version belongs to and carries the `source_date` note.
#'
#' @param manifest Parsed manifest list.
#' @param section `"backends"` or `"enrichments"`.
#' @param name Entry name (e.g., `"wfo"`, `"eive"`).
#' @return A list of citation lists, empty when the entry has none.
#' @noRd
extract_manifest_citations <- function(manifest, section, name) {
  if (is.null(manifest)) return(list())
  entry <- manifest[[section]][[name]]
  if (is.null(entry) || is.null(entry$citation)) return(list())

  raw <- entry$citation
  if (is.list(raw) && is.null(names(raw))) {
    cits <- lapply(raw, clean_citation)
  } else {
    cits <- list(clean_citation(raw))
  }
  cits <- cits[!vapply(cits, is.null, logical(1L))]
  if (length(cits) == 0L) return(list())

  # A citation year is the year of the work; a frozen source can be packaged
  # under a much later release, so the date of the data itself is carried in
  # the note where a reader of the methods section will see it.
  src_date <- entry$source_date
  if (!is.null(src_date) && length(src_date) == 1L && is.atomic(src_date) &&
      !is.na(src_date) && nzchar(as.character(src_date))) {
    note <- sprintf("Data version %s", as.character(src_date))
    first <- cits[[1L]]
    first$note <- if (is.null(first$note)) note else paste(first$note, note, sep = "; ")
    cits[[1L]] <- first
  }
  cits
}


#' Drop empty citation fields to clean length-1 character values
#'
#' A manifest citation field with no value arrives from `jsonlite` as a JSON
#' `null` or `{}`, both read as a zero-length list rather than `NULL`. Those
#' slip past `%||%` and then break `is.na()`/`nzchar()` downstream. Each field
#' is collapsed to a length-1 character scalar, or dropped when it holds no
#' usable value, so the `%||%` fallbacks see a clean absence.
#'
#' @param cit A raw citation list from the manifest.
#' @return A citation list with only non-empty scalar fields, or `NULL`.
#' @noRd
clean_citation <- function(cit) {
  if (!is.list(cit) || length(cit) == 0L) return(NULL)
  cleaned <- lapply(cit, function(v) {
    if (is.null(v) || length(v) != 1L || !is.atomic(v)) return(NULL)
    v <- as.character(v)
    if (is.na(v) || !nzchar(v)) return(NULL)
    v
  })
  cleaned <- cleaned[!vapply(cleaned, is.null, logical(1L))]
  if (length(cleaned) == 0L) return(NULL)
  cleaned
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
  # Carries the access date for sources harvested live from a server, where
  # the year alone does not identify what was retrieved.
  add_field("note",    cit$note)

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
  backbones <- meta$backbone
  if (!is.null(backbones)) {
    version <- meta$version %||% ""
    if (length(backbones) == 1L && nzchar(version)) {
      parts <- c(parts, sprintf("%s %s", toupper(backbones), version))
    } else {
      parts <- c(parts, paste(toupper(backbones), collapse = " + "))
    }
  }

  # Enrichments -- only those that contributed a value (drop 0-match sources),
  # deduplicated by label.
  enrichments <- meta$enrichments
  if (!is.null(enrichments) && length(enrichments) > 0L) {
    seen <- character(0L)
    for (e in enrichments) {
      if (!enrichment_contributed(e)) next
      label <- e$source %||% e$name
      if (!is.null(e$version) && !is.na(e$version) && nzchar(e$version)) {
        label <- paste(label, e$version)
      }
      if (label %in% seen) next
      seen  <- c(seen, label)
      parts <- c(parts, label)
    }
  }

  paste(parts, collapse = ", ")
}

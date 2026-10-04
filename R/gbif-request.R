#' Require rgbif for a GBIF request
#'
#' rgbif is a Suggests-level dependency: taxify resolves names and reports GBIF
#' keys offline without it, and needs it only to send a request.
#'
#' @noRd
require_rgbif <- function(operation = "this operation") {
  if (!requireNamespace("rgbif", quietly = TRUE)) {
    stop(
      sprintf(
        "%s requires the 'rgbif' package.\n  Install with: install.packages(\"rgbif\")",
        operation
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}


#' Check that GBIF download credentials are present
#'
#' `occ_download()` is an authenticated call. rgbif reads the account from
#' these three environment variables, so the absence of one is reported here
#' rather than left to fail inside the request.
#'
#' @noRd
check_gbif_credentials <- function() {
  vars <- c("GBIF_USER", "GBIF_PWD", "GBIF_EMAIL")
  missing <- vars[!nzchar(Sys.getenv(vars))]
  if (length(missing)) {
    stop(
      sprintf(
        paste0("A GBIF download needs a GBIF account; %s not set.\n",
               "  Set them in ~/.Renviron (see ?gbif_request), or use ",
               "method = \"search\" for an unauthenticated request."),
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}


#' Which rows of a result carry GBIF keys a request can use
#'
#' A row on the `gbif` backbone does. So does a row on a backbone whose build
#' carries a GBIF crosswalk (COL XR) when its picked `accepted_id` has a GBIF
#' key: the request then follows the taxon the result names. The other IDs of
#' the row are sorted by role in [taxify_ids()], so a homonym's target under
#' another author is reported rather than requested.
#'
#' @noRd
rows_with_gbif_key <- function(x) {
  keyed <- !is.na(x$backbone) & x$backbone == "gbif"
  cand <- !keyed & !is.na(x$accepted_id)
  if (any(cand)) {
    tab <- taxify_ids(as.data.frame(x)[cand, , drop = FALSE], verbose = FALSE)
    tab <- tab[tab$is_pick & !is.na(tab$gbif_key), , drop = FALSE]
    keyed[cand] <- x$input_name[cand] %in% tab$input_name
  }
  keyed
}


#' Make sure a result carries GBIF keys
#'
#' The default backbone chain starts at COL XR, whose own IDs GBIF serves no
#' records for. A COL XR build carries the legacy GBIF keys of each usage as a
#' `gbif_key` column, so such a row already holds what a request needs. Every
#' other matched row is re-matched against GBIF by its `accepted_name`, not its
#' input name, so the request follows the taxon the result names rather than
#' whichever taxon GBIF would pick for the input; the row keeps its
#' `input_name`. A row nothing matched is re-matched by its input name. The
#' names re-matched are recorded in the `rematched` attribute.
#'
#' @noRd
ensure_gbif_match <- function(x, verbose = TRUE) {
  if (!is.data.frame(x) || !all(c("backbone", "input_name") %in% names(x))) {
    return(x)
  }
  keyed <- rows_with_gbif_key(x)
  if (all(keyed)) return(x)

  if (verbose) {
    message(sprintf(
      "%d of %d name(s) carry no GBIF key; re-matching their accepted names ",
      sum(!keyed), nrow(x)), "against the GBIF backbone.")
  }
  todo <- which(!keyed)
  query <- if ("accepted_name" %in% names(x)) x$accepted_name[todo] else
    rep(NA_character_, length(todo))
  query <- ifelse(is.na(query), x$input_name[todo], query)
  redone <- as.data.frame(taxify_input(query, backbone = "gbif",
                                       verbose = verbose))
  redone$input_name <- x$input_name[todo]

  out <- if (any(keyed)) {
    rbind_union(list(as.data.frame(x)[keyed, , drop = FALSE], redone))
  } else {
    redone
  }
  out <- out[order(match(out$input_name, x$input_name)), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "rematched") <- x$input_name[todo]
  out
}


#' One row per GBIF key
#'
#' A `taxify_ids()` row on a crosswalked backbone can hold several GBIF keys
#' (`"a|b"`). This spreads each into a row of its own, keeping the rest of the
#' row, and drops the rows with none.
#'
#' @noRd
expand_gbif_keys <- function(tab) {
  tab <- tab[!is.na(tab$gbif_key), , drop = FALSE]
  keys <- strsplit(tab$gbif_key, "|", fixed = TRUE)
  out <- tab[rep(seq_len(nrow(tab)), lengths(keys)), , drop = FALSE]
  out$gbif_key <- unlist(keys, use.names = FALSE)
  rownames(out) <- NULL
  out
}


#' The GBIF keys behind a matched name list
#'
#' Reduces a `taxify()` result to the GBIF taxon keys to request data with,
#' erroring where the keys are not GBIF's integer keys (as when taxify is
#' pointed at the bundled example database, whose IDs are synthetic).
#'
#' @noRd
gbif_keys_of <- function(x, keys = "taxon", verbose = TRUE) {
  if (!is.data.frame(x) || !all(c("backbone", "accepted_id") %in% names(x))) {
    stop("x must be a taxify() result or a character vector of names.",
         call. = FALSE)
  }
  if (!"input_name" %in% names(x)) {
    stop("No names matched the GBIF backbone. Match against it with ",
         "taxify(x, backbone = \"gbif\").", call. = FALSE)
  }
  rematched <- attr(x, "rematched")
  usable <- rows_with_gbif_key(x)
  if (!all(usable)) {
    if (verbose) {
      message(sprintf("Dropping %d name(s) with no GBIF key; ",
                      length(unique(x$input_name[!usable]))),
              "GBIF keys come from the GBIF backbone.")
    }
    x <- as.data.frame(x)[usable, , drop = FALSE]
  }
  tab <- taxify_ids(x, verbose = verbose)
  if (nrow(tab) == 0L || all(is.na(tab$gbif_key))) {
    stop("No names matched the GBIF backbone. Match against it with ",
         "taxify(x, backbone = \"gbif\").", call. = FALSE)
  }
  tab$key_source <- ifelse(tab$backbone != "gbif", "crosswalk",
                           ifelse(tab$input_name %in% rematched, "rematch",
                                  "backbone"))
  long <- complete_crosswalk_keys(expand_gbif_keys(tab))
  long$requested <- switch(keys,
    pick  = long$role == "pick",
    taxon = long$role %in% c("pick", "same_name"),
    all   = rep(TRUE, nrow(long)))
  bad <- !grepl("^[0-9]+$", long$gbif_key)
  if (any(bad)) {
    stop(sprintf(
      paste0("%d of %d GBIF keys are not GBIF taxon keys (e.g. %s).\n",
             "  A GBIF request needs the real GBIF backbone; the bundled ",
             "example database carries synthetic IDs."),
      sum(bad), nrow(long), long$gbif_key[which(bad)[1L]]), call. = FALSE)
  }
  if (verbose) message(request_breakdown(long, keys))

  out <- unique(as.integer(long$gbif_key[long$requested]))
  attr(out, "taxa") <- long
  out
}


#' Complete crosswalked keys from the installed GBIF backbone
#'
#' A crosswalk carries the GBIF key of the taxon a row picked, but not GBIF's
#' further records of the same name (its doubtful or duplicate records, which
#' keep the name as their own concept), nor an occurrence count, since both
#' live on the GBIF backbone. When the GBIF backbone is installed, both are
#' read from it: the same-name records by the picked taxon's name, as rows of
#' role `"same_name"`, and the counts by key. A crosswalked list then requests
#' the keys a GBIF-matched one does and its size estimate covers every key.
#' Nothing is downloaded for this; without the backbone the rows are returned
#' as they came.
#'
#' @param long One row per GBIF key, from `expand_gbif_keys()`.
#' @noRd
complete_crosswalk_keys <- function(long) {
  xw <- long$key_source == "crosswalk"
  if (!any(xw) || !"gbif" %in% installed_backbones()) return(long)
  bb <- versioned_vtr_path("gbif", "latest")
  schema <- vtr_schema(bb)

  pick <- long[xw & long$role == "pick", , drop = FALSE]
  cols <- intersect(c("taxon_id", "canonical_name", "authorship",
                      "taxon_rank", "taxonomic_status", "family",
                      "n_occurrences", "is_synonym"), schema)
  same <- backbone_join(bb, pick$accepted_name, bb_key = "canonical_name",
                        select_cols = cols)
  if (!is.null(same) && nrow(same)) {
    own <- status_score_vec(same$taxonomic_status, same$is_synonym) <=
      .status_unplaced
    same <- same[own, , drop = FALSE]
    rows <- lapply(seq_len(nrow(pick)), function(i) {
      hit <- same[same$lookup == pick$accepted_name[i] &
                    !same$taxon_id %in% long$gbif_key[
                      long$input_name == pick$input_name[i]], , drop = FALSE]
      if (!nrow(hit)) return(NULL)
      add <- pick[rep(i, nrow(hit)), , drop = FALSE]
      add$gbif_key <- add$accepted_id <- as.character(hit$taxon_id)
      add$authorship <- hit$authorship %||% NA_character_
      add$taxonomic_status <- hit$taxonomic_status
      add$n_occurrences <- as.numeric(hit$n_occurrences %||% NA_real_)
      add$is_pick <- FALSE
      add$role <- "same_name"
      add
    })
    extra <- do.call(rbind, rows)
    if (!is.null(extra)) {
      long <- rbind(long, extra)
      long <- long[order(match(long$input_name, unique(long$input_name))), ,
                   drop = FALSE]
      rownames(long) <- NULL
    }
  }

  miss <- which(long$key_source == "crosswalk" & is.na(long$n_occurrences))
  if (length(miss) && "n_occurrences" %in% schema) {
    joined <- backbone_join(bb, unique(long$gbif_key[miss]),
                            bb_key = "taxon_id",
                            select_cols = c("taxon_id", "n_occurrences"))
    if (!is.null(joined)) {
      long$n_occurrences[miss] <- as.numeric(
        joined$n_occurrences[match(long$gbif_key[miss], joined$lookup)])
    }
  }
  long
}


#' One line reconciling the key count with the name count
#'
#' @param long One row per GBIF key, with `role` and `requested`.
#' @param keys The `keys` choice.
#' @noRd
request_breakdown <- function(long, keys) {
  req <- long[long$requested, , drop = FALSE]
  left <- long[!long$requested & !long$gbif_key %in% req$gbif_key, ,
               drop = FALSE]
  n_role <- function(d, r) length(unique(d$gbif_key[d$role == r]))
  msg <- sprintf(
    "%d name(s): %d picked key(s) and %d other key(s) of the same taxa",
    length(unique(long$input_name)), n_role(req, "pick"),
    n_role(req, "same_name"))
  if (n_role(req, "other_taxon")) {
    msg <- paste0(msg, sprintf(", %d key(s) of other taxa",
                               n_role(req, "other_taxon")))
  }
  msg <- paste0(msg, " requested.")
  parts <- vapply(c("same_name", "other_taxon"), function(r) {
    k <- n_role(left, r)
    if (k == 0L) return("")
    nm <- unique(left$input_name[left$role == r])
    sprintf("%d %s key(s) (%s%s)", k,
            if (r == "same_name") "same-taxon" else "other-taxon",
            paste(utils::head(nm, 3L), collapse = ", "),
            if (length(nm) > 3L) ", ..." else "")
  }, character(1L))
  parts <- parts[nzchar(parts)]
  if (length(parts)) {
    msg <- paste0(msg, sprintf(" Left out under keys = \"%s\": %s.", keys,
                               paste(parts, collapse = ", ")))
  }
  msg
}


#' Request GBIF occurrence data for a matched name list
#'
#' Takes a list of names, matches it against the GBIF backbone and requests
#' occurrence data for every accepted taxon key the matches resolve to. A name
#' GBIF files under more than one key -- a homonym published by two authors, or
#' a name held once as accepted and again as a doubtful record -- contributes
#' all of its keys, so the request covers the whole matched concept rather than
#' whichever key [taxify()] reported first.
#'
#' The keys themselves are read off [taxify_ids()], which resolves each one
#' against the backbone and carries its occurrence count; call it directly to
#' see what a request would cover before sending it, or pass `dry_run = TRUE`
#' here for the keys alone.
#'
#' @section Choosing a method:
#' `method = "download"` submits an asynchronous GBIF download. It has no
#' record cap and yields a citable DOI, which is what GBIF asks for in
#' published work, and it needs a GBIF account: set `GBIF_USER`, `GBIF_PWD` and
#' `GBIF_EMAIL` in `~/.Renviron`. The call returns as soon as the request is
#' queued; wait for it and fetch it with rgbif's `occ_download_wait()` and
#' `occ_download_get()`.
#'
#' `method = "search"` sends unauthenticated searches and returns the records
#' directly. It needs no account, and the GBIF search API caps what it will
#' page through, so it suits a look at a handful of taxa rather than a
#' checklist-wide pull.
#'
#' @param x A character vector of names, or a [taxify()] result. A character
#'   vector is matched against the GBIF backbone first.
#' @param method `"download"` (authenticated, no cap, citable) or `"search"`
#'   (unauthenticated, capped). See Choosing a method.
#' @param keys Which of a name's GBIF keys to request, by their `role` in
#'   [taxify_ids()]. `"taxon"` (default) requests the key [taxify()] picked
#'   and every other record of the same taxon (a doubtful or duplicate record
#'   of the name), and reports the keys of other taxa a homonym's synonym
#'   records point to. `"pick"` requests the picked key alone. `"all"`
#'   requests every key, other taxa included. The keys left out are named in
#'   the verbose line.
#' @param limit Records per key for `method = "search"`. Ignored by
#'   `"download"`.
#' @param format Download format for `method = "download"`, passed to rgbif.
#'   Ignored by `"search"`.
#' @param dry_run Logical. If `TRUE`, return the keys without contacting GBIF.
#' @param ... Matching arguments passed to [taxify()] (`fuzzy`, `kingdom`,
#'   `region`, ...); only when `x` is a character vector, and must be named.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return With `dry_run = TRUE`, an integer vector of GBIF taxon keys. With
#'   `method = "download"`, the object rgbif's `occ_download()` returns (the
#'   download key, to be passed to `occ_download_wait()`). With
#'   `method = "search"`, a data.frame of occurrence records, empty if none
#'   matched. In every case the keys and the [taxify_ids()] table behind them
#'   are attached as the `keys` and `taxa` attributes, along with the match's
#'   `taxify_meta`; a download also carries its key as `gbif_download`, which
#'   is what lets [cite()] report the download's DOI beside the backbone.
#'
#' @seealso [taxify_ids()] for the keys and their occurrence counts,
#'   [taxify()] for the matching itself.
#'
#' @examples
#' \dontrun{
#' # A checklist, matched and requested in one call. Needs the full GBIF
#' # backbone, so it cannot run on a check machine.
#' spp <- c("Quercus robur", "Bellis perennis", "Morus alba")
#'
#' # What would be requested, without contacting GBIF:
#' gbif_request(spp, dry_run = TRUE)
#'
#' # An unauthenticated search:
#' recs <- gbif_request(spp, method = "search", limit = 50)
#'
#' # A citable download (needs GBIF_USER / GBIF_PWD / GBIF_EMAIL):
#' dl <- gbif_request(spp, method = "download")
#' rgbif::occ_download_wait(dl)
#' rgbif::occ_download_get(dl)
#' }
#'
#' @export
gbif_request <- function(x,
                         method = c("download", "search"),
                         keys = c("taxon", "pick", "all"),
                         limit = 500,
                         format = "SIMPLE_CSV",
                         dry_run = FALSE,
                         ...,
                         verbose = TRUE) {
  method <- match.arg(method)
  keys_choice <- match.arg(keys)

  if (is.character(x)) {
    x <- taxify_input(x, backbone = "gbif", ..., verbose = verbose)
  } else if (...length() > 0L) {
    stop("Matching arguments in ... apply only when x is a character vector; ",
         "pass them to taxify() instead.", call. = FALSE)
  } else {
    x <- ensure_gbif_match(x, verbose = verbose)
  }

  keys <- gbif_keys_of(x, keys = keys_choice, verbose = verbose)
  taxa <- attr(keys, "taxa")
  # Attached before the dry-run return, so the keys carry the same provenance
  # the records would.
  attr(keys, "taxify_meta") <- attr(x, "taxify_meta")
  if (verbose) {
    message(sprintf("%d GBIF key(s) from %d matched name(s).%s",
                    length(keys), length(unique(taxa$input_name)),
                    expected_records_note(
                      taxa[taxa$requested & !duplicated(taxa$gbif_key), ,
                           drop = FALSE])))
  }
  if (isTRUE(dry_run)) return(keys)

  require_rgbif(sprintf("gbif_request(method = \"%s\")", method))

  out <- if (method == "download") {
    check_gbif_credentials()
    gbif_download_keys(keys, format = format, verbose = verbose)
  } else {
    gbif_search_keys(keys, limit = limit, verbose = verbose)
  }

  attr(out, "keys") <- as.integer(keys)
  attr(out, "taxa") <- taxa
  if (method == "download") attr(out, "gbif_download") <- as.character(out)
  # Carry the backbone provenance from the match, and the download key, so
  # cite() can report both what the names were matched against and the
  # download GBIF asks you to cite.
  attr(out, "taxify_meta") <- attr(x, "taxify_meta")
  out
}


# GBIF caps a download query at 12,000 characters. Measured against
# occ_download_prep(), a taxonKey predicate costs 10 characters per key on top
# of 125 of envelope, so about 1,187 keys fit. Chunking at 1,000 leaves room
# for a longer format string or an added predicate without recomputing this.
.gbif_keys_per_query <- 1000L


#' Submit a GBIF download, splitting it when the query would be too long
#'
#' A list of any size has to fit GBIF's 12,000-character query limit, which a
#' few hundred names can exceed once their homonyms are included. Above the
#' limit the keys are split across several downloads, submitted through rgbif's
#' queue so the three-concurrent-downloads rule is respected, and every
#' resulting key is returned. Each download gets its own DOI, and [cite()]
#' reports all of them.
#'
#' @return A character vector of download keys, one per submitted download.
#' @noRd
gbif_download_keys <- function(keys, format = "SIMPLE_CSV", verbose = TRUE) {
  chunks <- split(keys, ceiling(seq_along(keys) / .gbif_keys_per_query))

  if (length(chunks) == 1L) {
    if (verbose) message("Submitting a GBIF download...")
    return(as.character(
      rgbif::occ_download(rgbif::pred_in("taxonKey", keys), format = format)))
  }

  if (verbose) {
    message(sprintf(
      paste0("%d keys exceed GBIF's query limit; splitting into %d downloads ",
             "of up to %d keys. Each gets its own DOI."),
      length(keys), length(chunks), .gbif_keys_per_query))
  }
  reqs <- lapply(chunks, function(k)
    rgbif::occ_download_prep(rgbif::pred_in("taxonKey", k), format = format))
  res <- rgbif::occ_download_queue(.list = reqs)
  vapply(res, as.character, character(1L), USE.NAMES = FALSE)
}


#' How many records a request is about to ask for
#'
#' The GBIF backbone carries an occurrence count per key, so the size of a
#' download can be reported before it is submitted rather than discovered
#' afterwards. The counts were taken when the backbone was built and an
#' accepted key's count includes its synonyms and descendants, so this is the
#' order of magnitude, not a promise. Silent when no key carries a count.
#'
#' @noRd
expected_records_note <- function(taxa) {
  n <- suppressWarnings(as.numeric(taxa$n_occurrences))
  if (all(is.na(n))) return("")
  sprintf(" About %s occurrence record(s) across them.",
          format(sum(n, na.rm = TRUE), big.mark = ",", scientific = FALSE))
}


#' Link GBIF occurrence records back to the names they were requested for
#'
#' A request built from [gbif_request()] covers several keys per name, so the
#' records that come back have to be traced to the name that asked for them
#' before they can be counted or grouped.
#'
#' Joining on `taxonKey` alone loses records, silently. GBIF returns the
#' records of a key's descendants as well as its own, and a record identified
#' to a subspecies carries the subspecies key: requesting *Pinus nigra*
#' (5284809) returns records whose `taxonKey` is 5686674, *P. nigra* subsp.
#' *salzmannii*. Those rows match on `speciesKey` and on nothing else. This
#' function therefore tries the record's keys from the most specific outwards
#' and takes the first that is one of the requested keys.
#'
#' @param records A data.frame of occurrence records: what
#'   `gbif_request(method = "search")` returns, or a download imported with
#'   rgbif's `occ_download_import()`.
#' @param x What the keys came from: the object [gbif_request()] returned, a
#'   [taxify_ids()] table, or a [taxify()] result.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return `records` with three columns added: `requested_key` (the key that
#'   matched), `input_name` (the name as queried) and `accepted_name`. Records
#'   matching no requested key keep `NA` in all three. The provenance on `x`
#'   travels with them, so [cite()] on the result reports the backbone and,
#'   for a download, its DOI.
#'
#' @seealso [gbif_request()], [taxify_ids()].
#'
#' @examples
#' \dontrun{
#' spp <- c("Pinus nigra", "Quercus robur")
#' recs <- gbif_request(spp, method = "search", limit = 100)
#'
#' recs <- gbif_backmatch(recs, recs)
#' table(recs$input_name, useNA = "ifany")
#' }
#'
#' @export
gbif_backmatch <- function(records, x, verbose = TRUE) {
  if (!is.data.frame(records)) {
    stop("records must be a data.frame of occurrence records.", call. = FALSE)
  }
  taxa <- gbif_taxa_table(x)
  if (nrow(records) == 0L) {
    records$requested_key <- integer(0L)
    records$input_name <- character(0L)
    records$accepted_name <- character(0L)
    return(records)
  }

  taxa <- expand_gbif_keys(taxa)
  if ("requested" %in% names(taxa)) {
    taxa <- taxa[taxa$requested, , drop = FALSE]
  }
  keys <- as.integer(taxa$gbif_key)
  matched <- rep(NA_integer_, nrow(records))

  # Most specific first: the record's own key, then the accepted taxon it was
  # filed under, then the species/genus/family it sits in. The first of these
  # that is a requested key is the one the request asked for.
  for (cn in c("taxon_key_requested", "taxonKey", "acceptedTaxonKey",
               "speciesKey", "genusKey", "familyKey")) {
    if (!cn %in% names(records)) next
    v <- suppressWarnings(as.integer(records[[cn]]))
    fill <- is.na(matched) & !is.na(v) & v %in% keys
    matched[fill] <- v[fill]
    if (!anyNA(matched)) break
  }

  idx <- match(matched, keys)
  records$requested_key <- matched
  records$input_name    <- taxa$input_name[idx]
  records$accepted_name <- taxa$accepted_name[idx]

  # Provenance travels with the records: the backbone the names were matched
  # against, and the download to cite, so cite() works on the result.
  for (a in c("taxify_meta", "gbif_download")) {
    if (!is.null(attr(x, a))) attr(records, a) <- attr(x, a)
  }

  if (verbose) {
    lost <- sum(is.na(matched))
    if (lost) {
      message(sprintf(
        "%d of %d record(s) matched no requested key; their %s are NA.",
        lost, nrow(records), "input_name"))
    }
  }
  records
}


#' The citation for a GBIF download
#'
#' GBIF asks that a download be cited by its DOI, which the download is issued
#' once it finishes preparing, not when it is submitted. The DOI is therefore
#' read from GBIF at citation time rather than stored when the request was
#' made. Returns NULL when rgbif is absent or GBIF cannot be reached, so a
#' citation listing degrades to the backbone entries instead of failing.
#'
#' @param key A GBIF download key.
#' @return A one-row list with `text` and `doi`, or NULL.
#' @noRd
gbif_download_citation <- function(key) {
  if (!requireNamespace("rgbif", quietly = TRUE)) return(NULL)
  meta <- tryCatch(rgbif::occ_download_meta(key), error = function(e) NULL)
  if (is.null(meta)) return(NULL)
  doi <- meta$doi
  if (is.null(doi) || !nzchar(doi)) {
    return(list(
      text = sprintf(paste0("GBIF Occurrence Download, key %s (status %s). ",
                            "No DOI yet; it is issued when the download ",
                            "finishes."),
                     key, meta$status %||% "unknown"),
      doi = NA_character_))
  }
  date <- substr(meta$created %||% "", 1L, 10L)
  list(
    text = sprintf("GBIF.org%s GBIF Occurrence Download https://doi.org/%s",
                   if (nzchar(date)) sprintf(" (%s)", date) else "", doi),
    doi = doi)
}


#' The taxify_ids table behind a set of requested keys
#'
#' Accepts whatever the caller has to hand: a `gbif_request()` return value
#' (which carries the table as an attribute), the table itself, or a
#' `taxify()` result to derive it from.
#'
#' @noRd
gbif_taxa_table <- function(x) {
  taxa <- attr(x, "taxa")
  if (is.null(taxa) && is.data.frame(x) &&
      all(c("gbif_key", "input_name", "accepted_name") %in% names(x))) {
    taxa <- x
  }
  if (is.null(taxa) && is.data.frame(x) &&
      all(c("input_name", "backbone", "accepted_id") %in% names(x))) {
    taxa <- attr(gbif_keys_of(x, verbose = FALSE), "taxa")
  }
  if (is.null(taxa)) {
    stop("x must be a gbif_request() result, a taxify_ids() table, or a ",
         "taxify() result.", call. = FALSE)
  }
  taxa
}


#' Search GBIF occurrences for a set of taxon keys
#'
#' The search API answers one key per query, so the keys are requested in turn
#' and their records stacked. Columns differ between keys (GBIF returns only
#' the fields a record carries), so the frames are reconciled on the union of
#' their columns rather than assuming a shared schema.
#'
#' @noRd
gbif_search_keys <- function(keys, limit = 500, verbose = TRUE) {
  if (verbose && length(keys) > 10L) {
    message(sprintf("Searching %d keys, one request each...", length(keys)))
  }
  parts <- list()
  for (k in keys) {
    res <- rgbif::occ_search(taxonKey = k, limit = limit)
    d <- res$data
    if (is.null(d) || !is.data.frame(d) || nrow(d) == 0L) next
    d$taxon_key_requested <- k
    parts[[length(parts) + 1L]] <- d
  }
  if (length(parts) == 0L) {
    if (verbose) message("No occurrence records returned.")
    return(data.frame())
  }
  rbind_union(parts)
}


#' Stack frames that do not share a schema
#'
#' GBIF returns only the fields a record carries, so two keys, or two
#' downloads, can come back with different columns. Stacking them on the union
#' of their columns keeps every field instead of failing or silently dropping
#' the ones not shared.
#'
#' @param parts A list of data.frames.
#' @return One data.frame.
#' @noRd
rbind_union <- function(parts) {
  parts <- Filter(function(d) is.data.frame(d) && nrow(d) > 0L, parts)
  if (length(parts) == 0L) return(data.frame())
  cols <- unique(unlist(lapply(parts, names), use.names = FALSE))
  parts <- lapply(parts, function(d) {
    for (cn in setdiff(cols, names(d))) d[[cn]] <- NA
    d[, cols, drop = FALSE]
  })
  do.call(rbind, parts)
}


#' Fetch the records of a submitted GBIF download
#'
#' Waits for the download [gbif_request()] submitted, retrieves it, imports it
#' and returns the records. A request too long for one GBIF query is split
#' across several downloads, and all of them are waited for and stacked, so a
#' sharded request is fetched the same way as a single one.
#'
#' @param x What `gbif_request(method = "download")` returned.
#' @param backmatch Logical. Attach the queried names with [gbif_backmatch()].
#'   Default `TRUE`.
#' @param path Directory to download into. Defaults to a session temp
#'   directory, so nothing is written outside it unless you ask.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame of occurrence records, carrying the same `keys`,
#'   `taxa`, `taxify_meta` and `gbif_download` attributes as `x`, so [cite()]
#'   reports the backbone and every download DOI.
#'
#' @seealso [gbif_request()], [gbif_backmatch()], [cite()].
#'
#' @examples
#' \dontrun{
#' dl <- gbif_request(c("Quercus robur", "Bellis perennis"))
#' recs <- gbif_fetch(dl)
#' cite(recs)
#' }
#'
#' @export
gbif_fetch <- function(x, backmatch = TRUE, path = tempdir(), verbose = TRUE) {
  require_rgbif("gbif_fetch()")
  keys <- attr(x, "gbif_download") %||% as.character(x)
  keys <- keys[!is.na(keys) & nzchar(keys)]
  if (length(keys) == 0L) {
    stop("x carries no GBIF download key; was it made by ",
         "gbif_request(method = \"download\")?", call. = FALSE)
  }

  parts <- vector("list", length(keys))
  for (i in seq_along(keys)) {
    if (verbose) {
      message(sprintf("Waiting for download %d of %d (%s)...",
                      i, length(keys), keys[i]))
    }
    rgbif::occ_download_wait(keys[i], quiet = !verbose)
    got <- rgbif::occ_download_get(keys[i], path = path, overwrite = TRUE)
    parts[[i]] <- rgbif::occ_download_import(got)
  }

  out <- rbind_union(parts)
  for (a in c("keys", "taxa", "taxify_meta", "gbif_download")) {
    if (!is.null(attr(x, a))) attr(out, a) <- attr(x, a)
  }
  if (verbose) message(sprintf("%d record(s).", nrow(out)))

  if (isTRUE(backmatch) && nrow(out) > 0L && !is.null(attr(x, "taxa"))) {
    out <- gbif_backmatch(out, x, verbose = verbose)
  }
  out
}

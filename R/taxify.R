#' Match taxonomic names against local backbone databases
#'
#' Matches a vector of taxonomic names against locally stored Darwin Core
#' backbone databases. Returns a data.frame with one row per input name
#' containing the matched name, accepted name, taxonomic hierarchy, and
#' match quality information.
#'
#' By default `taxify()` matches against **every installed backbone**, tried in
#' priority order as a fallback chain: a name is resolved by the first backbone
#' (COL, then the domain authorities, then the broad aggregators) that matches
#' it, and names matched earlier are not re-matched later. On a fresh setup with
#' nothing installed yet, the first call downloads a default set (COL, GBIF,
#' ITIS) once; pre-install a different set with [install_backbones()]. Name a
#' backend (or several) explicitly to match only against that one, or those in
#' that order.
#'
#' @param x Character vector of taxonomic names.
#' @param backend Character vector of backend names (e.g., `"wfo"`, `"col"`,
#'   `"gbif"`) or a single `taxify_backend` object. Several are tried in order
#'   as a fallback chain. `NULL` (default) uses every installed backbone in
#'   priority order, installing the default set (COL, GBIF, ITIS) on first use;
#'   override the priority with `options(taxify.backbone_priority = ...)` and the
#'   first-run set with `options(taxify.default_backbones = ...)`.
#' @param fuzzy Logical. Enable fuzzy matching for names that fail exact
#'   match. Default `TRUE`.
#' @param fuzzy_threshold Numeric. Maximum allowed distance for fuzzy matches.
#'   Two modes depending on the value:
#'   - **Fractional** (`0 < fuzzy_threshold < 1`): normalized distance
#'     (edits / max name length). Default `0.2` is about 1 edit per 5 characters.
#'   - **Integer** (`fuzzy_threshold >= 1`): maximum raw edit count, e.g.
#'     `fuzzy_threshold = 2L` allows at most 2 insertions/deletions/substitutions
#'     regardless of name length. Not supported for `fuzzy_method = "jw"`.
#' @param fuzzy_method Character. One of `"dl"` (Damerau-Levenshtein,
#'   default), `"levenshtein"`, or `"jw"` (Jaro-Winkler).
#' @param aggregates Character. How to treat species aggregates (names with an
#'   `agg.` / `s.l.` qualifier). `"preserve"` (default) keeps the aggregate as
#'   its own concept: it matches the backbone's aggregate taxon
#'   (`"<binomial> aggr."`) where one exists, otherwise falls back to the
#'   binomial. When it falls back, the `aggregate_fallback` column is set `TRUE`
#'   so the aggregate-to-species collapse is visible rather than silent (only
#'   the aggregate-bearing backbones -- Euro+Med, WoRMS -- carry aggregate taxa,
#'   so preserve falls back for the others). `"collapse"` strips the marker and
#'   matches the binomial species, the way any non-aggregate name is matched.
#'   Either way the qualifier is recorded in the `qualifier` column.
#' @param region Region(s) to constrain fuzzy matching to, or `NULL` (default)
#'   for no geographic constraint. Botanical (WCVP, vascular plants): TDWG Level
#'   3 codes (`"BGM"`, `c("BGM", "GER")`) or region names at any level, matched
#'   case- and accent-insensitively against the bundled WGSRPD crosswalk -- a
#'   Level 3 name (`"Belgium"`), a Level 2 region (`"Middle Europe"`), or a Level
#'   1 continent (`"Europe"`, which expands to all its codes). Marine (only when
#'   the `marine_distribution` asset is installed): a MEOW ecoregion `ECO_CODE`,
#'   or an ecoregion / province / realm name (a province or realm expands to its
#'   member ecoregions). See [taxify_regions()] for the botanical list. When set,
#'   **fuzzy** candidates are restricted to species with range records in the
#'   region(s); exact matches are always kept. The filter only narrows genuinely
#'   ambiguous fuzzy candidates: a candidate is dropped only when the same input
#'   name has another candidate that is in-region or has no range data, so a
#'   match in a group with no range coverage is never affected and a name whose
#'   only candidate is out-of-region is still returned.
#' @param coords Coordinates to constrain fuzzy matching to, mapped to region
#'   codes by point-in-polygon and unioned with `region`. Points are tested
#'   against the WGSRPD botanical boundaries (yielding TDWG codes) and, when the
#'   marine asset is installed, the MEOW ecoregion boundaries (yielding
#'   `ECO_CODE`s), so a coastal point can resolve to both. A single
#'   `c(lon, lat)` pair, a matrix/data.frame of longitude/latitude columns
#'   (named `lon`/`lat` or `x`/`y`, else the first two columns as lon, lat), or
#'   a point-geometry spatial object (an \pkg{sf}/`sfc` object or a \pkg{terra}
#'   `SpatVector`, reprojected to longitude/latitude automatically). `NULL`
#'   (default) for none. Each boundary file is downloaded once and cached;
#'   coordinate lookup needs that download (or a prior cache). The point-in-
#'   polygon test uses \pkg{terra} or \pkg{sf} when installed, otherwise a
#'   native fallback; force the engine with
#'   `options(taxify.pip_engine = "terra" | "sf" | "native")`.
#' @param range Character. Which range statuses count as in-region when `region`
#'   or `coords` is set. `"present"` (default) accepts any record (native,
#'   introduced, extinct, or unknown status) -- the right choice for name
#'   disambiguation. `"native"` accepts only native records, `"introduced"` only
#'   introduced (alien) records; both fold an ecological filter into matching and
#'   are for callers who want that. Ignored when no region is set.
#' @param kingdom Character. Restrict matches to one or more kingdoms, to
#'   disambiguate a name shared across kingdoms (a *Prunella* that is both a bird
#'   and a plant, an *Oenanthe* that is both). `NULL` (default) applies no
#'   constraint. Accepts a kingdom name or a common alias, case-insensitively:
#'   `"animals"`/`"Animalia"`/`"Metazoa"`, `"plants"`/`"Plantae"`,
#'   `"fungi"`, `"bacteria"`, `"archaea"`, `"chromista"`, `"protozoa"`,
#'   `"viruses"`. A matched taxon is kept only when its kingdom is the requested
#'   one (or is unknown, which is never rejected); with the default multi-backend
#'   fallback, a name a backbone resolves into the wrong kingdom is passed on to
#'   the next backbone, so the in-kingdom treatment wins. The kingdom is read
#'   from the backbone where it stores one (COL, ITIS, NCBI, OTT, WoRMS); for a
#'   backbone that does not (WFO, GBIF), it falls back to the genus register's
#'   kingdom, which cannot split a genus that is itself homonymous across
#'   kingdoms -- name a kingdom-appropriate `backend` for those.
#' @param mode Character. How to combine results when `backend` names more than
#'   one backbone. `"fallback"` (default) is the fallback chain described above:
#'   one answer per name, from the first backbone that matched. `"wide"` and
#'   `"agreement"` instead consult **every** backbone for every name and report
#'   how they compare, so a backbone disagreement (see the *Backbone-specific
#'   accepted names* section) is visible in one call rather than by querying each
#'   backbone by hand. Both return a strict superset of the `"fallback"` result
#'   (the same standard columns, with `accepted_name` still the fallback pick, so
#'   the frame still pipes into the `add_*()` enrichments) plus:
#'   \itemize{
#'     \item `"wide"`: one `accepted_<backbone>` column per backbone and a
#'       logical `all_agree`.
#'     \item `"agreement"`: `n_backbones_matched`, `n_distinct_accepted`, and
#'       `all_agree`.
#'   }
#'   `all_agree` is `TRUE`/`FALSE` when at least two backbones matched the name
#'   and `NA` when fewer than two did (nothing to compare). Ignored (with a
#'   message) when only one backbone is given, since there is nothing to compare.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return A data.frame with one row per input name and the following columns:
#' \describe{
#'   \item{input_name}{The original name as provided.}
#'   \item{matched_name}{Full name in the backbone that matched. For an
#'     unresolved hybrid formula (`match_type = "hybrid_formula"`) it holds the
#'     input-parent cross (e.g. `"Salix alba x Salix fragilis"`) when both
#'     parents resolve, else `NA`.}
#'   \item{accepted_name}{Resolved accepted name (equals `matched_name`
#'     if not a synonym). For a hybrid formula it holds the accepted-parent
#'     cross (both parents resolved), else `NA`.}
#'   \item{taxon_id}{Backend-specific ID of the matched name.}
#'   \item{accepted_id}{ID of the accepted name.}
#'   \item{rank}{Taxonomic rank (species, subspecies, genus, etc.).}
#'   \item{family}{Family name.}
#'   \item{genus}{Genus name.}
#'   \item{epithet}{Specific epithet.}
#'   \item{authorship}{Authorship of the matched name.}
#'   \item{accepted_authorship}{Authorship of the accepted name. For a synonym
#'     this is the author of the resolved accepted name, not the synonym's own
#'     author, so `accepted_name` and `accepted_authorship` together form the
#'     accepted name's full citation.}
#'   \item{is_synonym}{Logical. Was the match a synonym?}
#'   \item{is_hybrid}{Logical. Was a hybrid marker detected in the input?}
#'   \item{hybrid_type}{`"nothogenus"` (`"x Cupressocyparis leylandii"`),
#'     `"nothospecies"` (`"Quercus x hispanica"`), `"formula"`
#'     (`"Salix alba x Salix fragilis"`), or `NA` for a non-hybrid. Nothogenus
#'     and nothospecies resolve to a single backbone taxon in the usual columns;
#'     a formula does not (its match columns are `NA` and `match_type` is
#'     `"hybrid_formula"`). The parent binomials of a formula, and their accepted
#'     names, are added on demand by [add_hybrid_info()].}
#'   \item{qualifier}{Canonical taxonomic qualifier found in the input name
#'     (`"cf."`, `"aff."`, `"agg."`, `"s.l."`, `"s.str."`, `"sp."`, ...), or
#'     `NA`. Spelling variants are folded to one token (`"aggr."`, `"agg"` and
#'     `"sensu lato"` all map to `"agg."`/`"s.l."`).}
#'   \item{qualifier_position}{`"genus"` when the qualifier leads the name and
#'     qualifies the whole name (e.g. `"Cf. Pinus sylvestris"`), `"species"`
#'     when it qualifies the species (inline `cf.` or trailing `agg.`), `NA`
#'     when there is no qualifier.}
#'   \item{aggregate_fallback}{Logical. For an aggregate query under
#'     `aggregates = "preserve"`: `FALSE` when it resolved to the backbone's
#'     dedicated aggregate taxon, `TRUE` when no such taxon existed and it fell
#'     back to the nominal binomial. `NA` for non-aggregate queries and under
#'     `aggregates = "collapse"`, where the collapse is explicit.}
#'   \item{match_type}{One of `"exact"`, `"exact_ci"`, `"fuzzy"`, `"abbrev"`
#'     (an abbreviated genus such as `"Q. robur"` resolved via genus initial
#'     plus epithet), `"hybrid_formula"` (a two-parent cross; the row's
#'     backbone-match columns are `NA` and the parents are resolved into the
#'     `hybrid_parent_*` columns instead), or `"none"`.}
#'   \item{fuzzy_dist}{Normalized string distance (0--1), `NA` if exact.}
#'   \item{is_ambiguous}{Logical. `TRUE` when the matched scientificName had
#'     multiple synonym rows pointing to different accepted taxa at the same
#'     priority tier (homonym ambiguity). Disambiguated via
#'     `nomenclaturalStatus = "Valid"` when that column is in the backbone;
#'     for irreducible ambiguity, the scalar columns hold one candidate.}
#'   \item{ambiguous_targets}{Character. `|`-joined list of conflicting
#'     accepted taxon IDs when `is_ambiguous = TRUE`; `NA` otherwise.}
#'   \item{backend}{Which backend was used (e.g., `"wfo"`, `"col"`,
#'     `"gbif"`).}
#'   \item{backbone_version}{Backend name, version, and download date
#'     (e.g., `"wfo:2024-12 (2026-04-01)"`). Useful for reproducibility.}
#' }
#'
#' @section Backbone-specific accepted names:
#' Each backend is an independent taxonomy, and they can legitimately disagree
#' on which name is accepted and which is a synonym. `taxify()` returns the
#' matched backend's own current treatment; it does not reconcile backends
#' against each other by voting (a consensus would regress toward the most
#' conservative treatment across backbones that copy one another). With the
#' default multi-backend fallback, `accepted_name` is the pick of the
#' highest-priority backbone that matched. To see where backbones disagree, pass
#' `mode = "wide"` (or `"agreement"`) for each backbone's `accepted_name` side by
#' side; to follow one authority, name a single `backend`.
#'
#' For example, the red and parma kangaroos: the GBIF Backbone Taxonomy
#' accepts `Macropus rufus` and `Macropus parma`, treating `Osphranter rufus`
#' and `Notamacropus parma` as synonyms of them, so
#' `taxify("Osphranter rufus", backend = "gbif")` resolves to `Macropus rufus`.
#' The Catalogue of Life splits the genus and does the reverse, so
#' `taxify("Macropus rufus", backend = "col")` resolves to `Osphranter rufus`.
#' Both are faithful to their source; the difference is in the backbones, not in
#' the matching.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Match a few names
#' taxify(c("Quercus robur", "Pinus sylvestris"))
#'
#' # Disable fuzzy matching
#' taxify("Quercus robus", fuzzy = FALSE)
#'
#' # Constrain fuzzy candidates to a geographic region: a TDWG Level 3 code,
#' # or a region name resolved via the bundled WGSRPD crosswalk
#' taxify("Quercus robus", region = "EUR")
#' taxify("Quercus robus", region = "Belgium")
#'
#' # Constrain by coordinates (downloads WGSRPD boundaries on first use)
#' \dontrun{
#' taxify("Quercus robus", coords = c(4.35, 50.85))
#' }
#'
#' # Fallback chain: try WFO first, then COL for unmatched
#' taxify(c("Quercus robur", "Panthera leo"),
#'        backend = c("wfo", "col"))
#'
#' # Compare how two backbones resolve the same names, side by side
#' taxify(c("Quercus robur", "Pinus sylvestris"),
#'        backend = c("wfo", "col"), mode = "wide")
#'
#' options(old)
#'
#' @export
taxify <- function(x,
                   backend = NULL,
                   fuzzy = TRUE,
                   fuzzy_threshold = 0.2,
                   fuzzy_method = c("dl", "levenshtein", "jw"),
                   aggregates = c("preserve", "collapse"),
                   region = NULL,
                   coords = NULL,
                   range = c("present", "native", "introduced"),
                   kingdom = NULL,
                   mode = c("fallback", "wide", "agreement"),
                   verbose = TRUE) {

  fuzzy_method <- match.arg(fuzzy_method)
  aggregates   <- match.arg(aggregates)
  range        <- match.arg(range)
  mode         <- match.arg(mode)
  region       <- resolve_region(region, coords, verbose = verbose)
  kingdom      <- resolve_kingdom_filter(kingdom)

  if (!is.character(x)) {
    stop("x must be a character vector", call. = FALSE)
  }
  if (length(x) == 0L) {
    stop("x must have at least one element", call. = FALSE)
  }

  # Default backend = every installed backbone, in priority order (first-match
  # fallback). On a fresh setup this downloads the default set once.
  if (is.null(backend)) {
    backend <- resolve_default_backend(verbose = verbose)
  }

  # Comparison modes consult every backbone for every name. They need >= 2
  # named backbones; with fewer there is nothing to compare, so fall through to
  # the normal single-answer result.
  if (mode != "fallback") {
    be_names <- if (inherits(backend, "taxify_backend")) backend$name else backend
    if (!is.character(be_names) || length(be_names) < 2L) {
      if (verbose) message(sprintf(
        "mode = \"%s\" needs >= 2 backends; returning the standard result.",
        mode))
    } else {
      ensure_backends_current(be_names, verbose = verbose)
      return(taxify_compare(x, be_names, mode, fuzzy, fuzzy_threshold,
                            fuzzy_method, aggregates, region, range, kingdom,
                            verbose))
    }
  }

  # Handle single backend object
  if (inherits(backend, "taxify_backend")) {
    ensure_backends_current(backend$name, verbose = verbose)
    return(taxify_single(x, backend, fuzzy, fuzzy_threshold, fuzzy_method,
                         aggregates, region = region, range_mode = range,
                         kingdom = kingdom, verbose = verbose))
  }

  if (!is.character(backend) || length(backend) == 0L) {
    stop("backend must be a character vector or taxify_backend object",
         call. = FALSE)
  }

  ensure_backends_current(backend, verbose = verbose)

  if (length(backend) == 1L) {
    be <- resolve_backend(backend)
    return(taxify_single(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                         aggregates, region = region, range_mode = range,
                         kingdom = kingdom, verbose = verbose))
  }

  # Multi-backend fallback chain
  if (verbose) message(sprintf("Matching %d names against %d backends: %s",
                                length(x), length(backend),
                                paste(backend, collapse = " -> ")))

  names_df <- attach_agg_key(clean_names(x), aggregates)
  result <- NULL

  for (be_name in backend) {
    be <- resolve_backend(be_name)
    bb_path <- ensure_backbone(be, verbose = verbose)

    if (is.null(result)) {
      # First backend: match all names
      if (verbose) message(sprintf("  [%s] Matching %d names...",
                                    be_name, nrow(names_df)))

      result <- run_match_stages(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                                 fuzzy_method, region = region,
                                 range_mode = range, verbose = verbose,
                                 label = be_name)
      result <- filter_result_by_kingdom(result, bb_path, kingdom, be$name)

      matched <- !is.na(result$match_type)
      result$backend <- ifelse(matched, be$name, NA_character_)
      bb_ver <- format_backbone_version(bb_path, be$name, be$version)
      result$backbone_version[matched] <- bb_ver
    } else {
      # Subsequent backends: only try unmatched names
      unmatched_idx <- which(is.na(result$match_type) &
                             !is.na(result$input_name))
      if (length(unmatched_idx) == 0L) {
        if (verbose) message(sprintf("  [%s] Skipped (all names matched)",
                                      be_name))
        next
      }

      if (verbose) message(sprintf("  [%s] Matching %d remaining names...",
                                    be_name, length(unmatched_idx)))

      sub_names_df <- names_df[unmatched_idx, , drop = FALSE]
      rownames(sub_names_df) <- NULL

      sub_result <- run_match_stages(be, sub_names_df, bb_path, fuzzy,
                                     fuzzy_threshold, fuzzy_method,
                                     region = region, range_mode = range,
                                     verbose = verbose, label = be_name)
      sub_result <- filter_result_by_kingdom(sub_result, bb_path, kingdom,
                                             be$name)

      # Merge sub_result back into main result. Copy every match column the
      # sub-result carries (so a schema addition needs no edit here); backend and
      # backbone_version are stamped from this backend, and input_name / the
      # input-side qualifier columns are left untouched (reassigned later).
      matched_in_sub <- which(!is.na(sub_result$match_type))
      if (length(matched_in_sub) > 0L) {
        bb_ver <- format_backbone_version(bb_path, be$name, be$version)
        dst    <- unmatched_idx[matched_in_sub]
        copy_cols <- setdiff(intersect(names(sub_result), names(result)),
                             c("input_name", "backend", "backbone_version",
                               "qualifier", "qualifier_position"))
        for (col in copy_cols) {
          result[[col]][dst] <- sub_result[[col]][matched_in_sub]
        }
        result$backend[dst]          <- be$name
        result$backbone_version[dst] <- bb_ver
      }
    }
  }

  # Set match_type = "none" for still-unmatched
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  # Ensure classification columns always exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  # Carry input-side qualifier info (rows are 1:1 with names_df)
  result$qualifier          <- names_df$qualifier
  result$qualifier_position <- names_df$qualifier_position
  result <- attach_aggregate_fallback(result, names_df)

  result <- enrich_with_register(result, names_df, backend)
  result <- finalize_hybrids(result, names_df, backend)
  rownames(result) <- NULL
  as_taxify_result(result, backend = backend)
}


#' Compare name resolution across several backbones
#'
#' Backs `taxify(..., mode = "wide" | "agreement")`. Runs every backbone
#' independently over the full name list (no fallback chaining), then assembles
#' one result. The base columns are the fallback pick -- the first backbone in
#' `backend` order that matched each name -- so a comparison result is a strict
#' superset of the standard `mode = "fallback"` output and still carries a single
#' `accepted_name` that pipes into the `add_*()` enrichments. On top of the base:
#'   * `"wide"` adds one `accepted_<backbone>` column per backbone plus a logical
#'     `all_agree`;
#'   * `"agreement"` adds `n_backbones_matched`, `n_distinct_accepted`, and
#'     `all_agree`.
#' `all_agree` is `TRUE`/`FALSE` when at least two backbones matched the name and
#' `NA` when fewer than two did.
#'
#' @param x Character vector of names.
#' @param backend Character vector of >= 2 backbone names, in priority order.
#' @param mode `"wide"` or `"agreement"`.
#' @param fuzzy,fuzzy_threshold,fuzzy_method,aggregates,region,range,verbose
#'   Passed through to each per-backbone [taxify_single()] run.
#' @return A `taxify_result` data.frame.
#' @noRd
taxify_compare <- function(x, backend, mode, fuzzy, fuzzy_threshold,
                           fuzzy_method, aggregates, region, range,
                           kingdom = NULL, verbose) {
  if (verbose) message(sprintf(
    "Comparing %d names across %d backbones: %s",
    length(x), length(backend), paste(backend, collapse = ", ")))

  # One independent run per backbone over all names (no fallback chaining), so
  # every backbone reports its own treatment of every name.
  per_be <- lapply(backend, function(be_name) {
    be <- resolve_backend(be_name)
    r  <- taxify_single(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                        aggregates, region = region, range_mode = range,
                        kingdom = kingdom, verbose = verbose)
    attr(r, "taxify_meta") <- NULL
    class(r) <- "data.frame"
    r
  })
  names(per_be) <- backend

  is_matched <- function(r) {
    !is.na(r$match_type) & !r$match_type %in% c("none", "out_of_scope")
  }

  # Base = fallback pick: first backbone (in order) that matched each name.
  base <- per_be[[1L]]
  base_matched <- is_matched(base)
  for (k in seq_along(backend)[-1L]) {
    r    <- per_be[[k]]
    fill <- which(!base_matched & is_matched(r))
    if (length(fill)) {
      for (col in intersect(names(base), names(r))) {
        base[[col]][fill] <- r[[col]][fill]
      }
      base_matched[fill] <- TRUE
    }
  }

  # Per-backbone accepted names, masked to matched rows for the agreement stats.
  acc_masked <- lapply(per_be, function(r) {
    a <- r$accepted_name
    a[!is_matched(r)] <- NA_character_
    a
  })
  acc_mat    <- do.call(cbind, acc_masked)          # character matrix
  n_matched  <- rowSums(!is.na(acc_mat))
  n_distinct <- apply(acc_mat, 1L, function(v) length(unique(v[!is.na(v)])))
  all_agree  <- ifelse(n_matched >= 2L, n_distinct <= 1L, NA)

  if (mode == "wide") {
    for (k in seq_along(backend)) {
      base[[paste0("accepted_", backend[k])]] <- per_be[[k]]$accepted_name
    }
    base$all_agree <- all_agree
  } else { # "agreement"
    base$n_backbones_matched <- as.integer(n_matched)
    base$n_distinct_accepted <- as.integer(n_distinct)
    base$all_agree           <- all_agree
  }

  rownames(base) <- NULL
  out  <- as_taxify_result(base, backend = backend)
  meta <- attr(out, "taxify_meta")
  meta$mode <- mode
  attr(out, "taxify_meta") <- meta
  out
}


#' Run the full matching pipeline against a single backend
#'
#' @param x Character vector of names.
#' @param be A taxify_backend object.
#' @param fuzzy Logical.
#' @param fuzzy_threshold Numeric.
#' @param fuzzy_method Character.
#' @param verbose Logical.
#' @return A data.frame with the 16-column output schema.
#' @noRd
taxify_single <- function(x, be, fuzzy, fuzzy_threshold, fuzzy_method,
                          aggregates = "preserve", region = NULL,
                          range_mode = "present", kingdom = NULL, verbose) {
  bb_path <- ensure_backbone(be, verbose = verbose)

  if (verbose) message(sprintf("Matching %d names...", length(x)))
  names_df <- attach_agg_key(clean_names(x), aggregates)

  result <- run_match_stages(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                             fuzzy_method, region = region,
                             range_mode = range_mode, verbose = verbose)
  result <- filter_result_by_kingdom(result, bb_path, kingdom, be$name)

  matched <- !is.na(result$match_type)
  result$backend <- ifelse(matched, be$name, NA_character_)
  result$backbone_version[matched] <- format_backbone_version(
    bb_path, be$name, be$version
  )
  result$match_type[is.na(result$match_type) &
                    !is.na(result$input_name)] <- "none"

  # Ensure classification columns always exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  # Carry input-side qualifier info (rows are 1:1 with names_df)
  result$qualifier          <- names_df$qualifier
  result$qualifier_position <- names_df$qualifier_position
  result <- attach_aggregate_fallback(result, names_df)

  result <- enrich_with_register(result, names_df, be$name)
  result <- finalize_hybrids(result, names_df, be)
  rownames(result) <- NULL
  as_taxify_result(result, backend = be$name)
}


#' Attach the aggregate-taxon lookup key to a cleaned-names frame
#'
#' In preserve mode, aggregate-concept rows get `agg_key = "<binomial> aggr."`,
#' the form that the aggregate-bearing backbones (Euro+Med, WoRMS) use for their
#' dedicated aggregate taxa. `match_exact_compiled()` tries this key before the
#' binomial. In collapse mode every `agg_key` is `NA`, so the aggregate pass is a
#' no-op and aggregates match as plain binomials.
#'
#' @param names_df Data.frame from `clean_names()`.
#' @param aggregates `"preserve"` or `"collapse"`.
#' @return `names_df` with an `agg_key` column.
#' @noRd
attach_agg_key <- function(names_df, aggregates = "preserve") {
  names_df$agg_key <- NA_character_
  if (identical(aggregates, "preserve")) {
    rows <- which(names_df$is_aggregate & !is.na(names_df$cleaned))
    if (length(rows)) {
      names_df$agg_key[rows] <- paste0(names_df$cleaned[rows], " aggr.")
    }
  }
  names_df
}


#' Flag aggregate queries that silently collapsed to the binomial
#'
#' In preserve mode an aggregate input (`"<binomial> agg."`) should match the
#' backbone's dedicated aggregate taxon (`"<binomial> aggr."`). Where the
#' backbone carries no such taxon the match falls through to the nominal
#' binomial, and without a signal that collapse is invisible. This records it in
#' an `aggregate_fallback` column so a preserve query that could not honour the
#' aggregate concept is visible rather than hidden:
#'   * `TRUE`  aggregate input resolved to the binomial (preserve fell back),
#'   * `FALSE` aggregate input resolved to the dedicated aggregate taxon,
#'   * `NA`    not an aggregate query (or one that matched nothing), or
#'             `aggregates = "collapse"`, where discarding the aggregate concept
#'             is what the caller asked for.
#'
#' The flag keys on `agg_key`, which `attach_agg_key()` populates only in
#' preserve mode, so it is uniformly `NA` under collapse. Resolution to the
#' aggregate taxon is detected from the trailing `aggr.` marker on the matched
#' backbone name -- only aggregate taxa carry it.
#'
#' @param result The match result data.frame.
#' @param names_df Data.frame from `attach_agg_key()`; rows 1:1 with `result`.
#' @return `result` with an `aggregate_fallback` logical column.
#' @noRd
attach_aggregate_fallback <- function(result, names_df) {
  fb <- rep(NA, nrow(result))
  agg_key <- names_df$agg_key
  if (!is.null(agg_key)) {
    tracked <- !is.na(agg_key)
    matched <- !is.na(result$match_type) &
      !result$match_type %in% c("none", "out_of_scope")
    resolved_agg <- !is.na(result$matched_name) &
      grepl("\\baggr?\\.?\\s*$", result$matched_name, ignore.case = TRUE)
    idx <- which(tracked & matched)
    fb[idx] <- !resolved_agg[idx]
  }
  result$aggregate_fallback <- fb
  result
}


#' Finalize hybrid rows: attach `hybrid_type` and mark unresolved formula crosses
#'
#' `hybrid_type` (`"nothogenus"` / `"nothospecies"` / `"formula"` / `NA`) is the
#' one hybrid column carried in the default output. A formula such as
#' `"Salix alba x Salix fragilis"` is first tried against the backbone as a whole
#' (some backbones store the cross as a name/synonym of the resulting
#' nothospecies -- see Pass 1b in `match_exact_compiled()`); when it resolves it
#' is a normal match. When it does not, the row is left unresolved --
#' `match_type = "hybrid_formula"`, `is_hybrid = TRUE`, all backbone-match
#' columns `NA` -- rather than silently collapsed to parent 1. The parents feed
#' the hybrid-aware trait fallback and are materialized on demand by
#' [add_hybrid_info()].
#'
#' @param result The match result data.frame.
#' @param names_df Data.frame from `clean_names()`; rows 1:1 with `result`.
#' @param backend Backend name(s) or a `taxify_backend`, used to resolve the
#'   parents of an unresolved formula.
#' @return `result` with `hybrid_type` attached and unresolved formulas marked.
#' @noRd
finalize_hybrids <- function(result, names_df, backend) {
  n <- nrow(result)
  ht <- names_df$hybrid_type %||% rep(NA_character_, n)
  result$hybrid_type <- ht

  # Only formula rows that did NOT resolve against the backbone (Pass 1b) are
  # marked as an unresolved cross; a formula that matched a stored nothospecies
  # keeps its normal resolution.
  unresolved <- is.na(result$match_type) | result$match_type == "none"
  form <- which(!is.na(ht) & ht == "formula" & !is.na(result$input_name) &
                  unresolved)
  if (length(form) == 0L) return(result)

  na_cols <- intersect(
    c("matched_name", "taxon_id", "accepted_id", "rank",
      "family", "genus", "epithet", "authorship", "accepted_authorship",
      "is_synonym", "fuzzy_dist", "is_ambiguous", "ambiguous_targets",
      "aggregate_fallback"),
    names(result))
  for (col in na_cols) result[[col]][form] <- NA
  result$match_type[form] <- "hybrid_formula"
  result$is_hybrid[form]  <- TRUE

  # No single backbone taxon matched, but the cross is named by its parents.
  # When BOTH parents resolve against the backend, fill matched_name with the
  # input-parent cross and accepted_name with the accepted-parent cross (the two
  # differ only when a parent is itself a synonym, mirroring synonym rows).
  # When a parent does not resolve, both stay NA.
  if ("accepted_name" %in% names(result)) {
    result$accepted_name[form] <- NA_character_
    pf <- lapply(result$input_name[form], parse_hybrid_formula)
    p1 <- vapply(pf, function(z) z$parent_1 %||% NA_character_, character(1L))
    p2 <- vapply(pf, function(z) z$parent_2 %||% NA_character_, character(1L))
    acc <- .resolve_parents_accepted(c(p1, p2), backend)
    a1  <- unname(acc[p1]); a2 <- unname(acc[p2])
    both <- !is.na(a1) & !is.na(a2)
    if (any(both)) {
      result$accepted_name[form[both]] <- paste(a1[both], .hybrid_sign, a2[both])
      if ("matched_name" %in% names(result)) {
        result$matched_name[form[both]] <-
          paste(p1[both], .hybrid_sign, p2[both])
      }
    }
  }
  result
}


#' Run the core matching stages against one backend
#'
#' The shared sequence used by both the single-backend and multi-backend paths:
#' exact matching, the out-of-scope prefilter, abbreviated-genus resolution,
#' then (optionally) fuzzy matching of whatever remains.
#'
#' @param be A taxify_backend object.
#' @param names_df Data.frame from `clean_names()`.
#' @param bb_path Path to the compiled backbone .vtr file.
#' @param fuzzy Logical. Enable the fuzzy pass.
#' @param fuzzy_threshold Numeric. Fuzzy distance threshold.
#' @param fuzzy_method Character. Fuzzy distance method.
#' @param verbose Logical.
#' @param label Optional backend label for verbose messages (NULL = no prefix).
#' @return The match result data.frame.
#' @noRd
run_match_stages <- function(be, names_df, bb_path, fuzzy, fuzzy_threshold,
                             fuzzy_method, region = NULL,
                             range_mode = "present", verbose = FALSE,
                             label = NULL) {
  pre <- if (is.null(label)) "  " else sprintf("  [%s] ", label)
  n_unresolved <- function(res) {
    sum(is.na(res$match_type) & !is.na(names_df$cleaned))
  }

  result <- match_exact(be, names_df, bb_path)
  result <- prefilter_out_of_scope(result, names_df, be$name)

  if (n_unresolved(result) > 0L) {
    result <- match_abbrev_genus(be, result, names_df, bb_path)
  }

  n_un <- n_unresolved(result)
  if (fuzzy && n_un > 0L) {
    if (verbose) message(sprintf("%sFuzzy matching %d unmatched...", pre, n_un))
    result <- match_fuzzy(be, result, bb_path, method = fuzzy_method,
                          threshold = fuzzy_threshold, names_df = names_df,
                          region = region, range_mode = range_mode)
  }

  # Settle homonym ambiguity where the input carried an author (no-op when no
  # ambiguous row carries one).
  result <- disambiguate_by_authorship(result, bb_path)
  result
}


# ---- Kingdom disambiguation (the `kingdom =` filter) ----
#
# A coarse kingdom vocabulary shared by the user hint, the backbone `kingdom`
# column, and the genus register's `kingdom_group`, so all three compare in one
# space. Values outside the vocabulary (informal clade names, "incertae sedis",
# "unknown", "") collapse to NA and are never a rejection reason -- an unknown
# kingdom is kept, only a known-and-wrong kingdom is filtered out.


#' Aliases mapping user/source kingdom spellings to the coarse vocabulary
#' @noRd
.kingdom_group_aliases <- c(
  animal = "animalia", animals = "animalia", animalia = "animalia",
  metazoa = "animalia", fauna = "animalia",
  plant = "plantae", plants = "plantae", plantae = "plantae",
  viridiplantae = "plantae", archaeplastida = "plantae",
  chloroplastida = "plantae", flora = "plantae",
  fungus = "fungi", fungi = "fungi",
  bacterium = "bacteria", bacteria = "bacteria", eubacteria = "bacteria",
  monera = "bacteria",
  archaeon = "archaea", archaea = "archaea", archaeal = "archaea",
  chromista = "chromista", chromist = "chromista",
  protozoa = "protozoa", protozoan = "protozoa", protist = "protozoa",
  protists = "protozoa",
  virus = "viruses", viruses = "viruses", viral = "viruses"
)


#' Normalize a kingdom string to the coarse kingdom-group vocabulary
#'
#' Case-insensitive; also folds the NCBI clade / OTT names that
#' [normalize_kingdom_names()] resolves. Unrecognised, empty, or explicitly
#' unknown values return `NA` (never a rejection reason downstream).
#'
#' @param x Character vector.
#' @return Character vector of coarse kingdom groups (or `NA`).
#' @noRd
normalize_kingdom_group <- function(x) {
  if (length(x) == 0L) return(character(0L))
  y <- tolower(trimws(as.character(normalize_kingdom_names(as.character(x)))))
  y[is.na(y) | !nzchar(y) | y %in% c("unknown", "incertae sedis",
                                     "incertae_sedis", "na")] <- NA_character_
  hit <- match(y, names(.kingdom_group_aliases))
  # Anything outside the coarse vocabulary is NA: an unknown source kingdom is
  # then never a rejection reason, and an unknown user hint fails validation.
  ifelse(!is.na(hit), unname(.kingdom_group_aliases[hit]), NA_character_)
}


#' Resolve the user `kingdom =` argument to a set of coarse kingdom groups
#'
#' @param kingdom `NULL`, or a character vector of kingdom names / aliases.
#' @return `NULL` when no constraint, else a character vector of coarse kingdom
#'   groups. Errors when none of the supplied values are recognisable.
#' @noRd
resolve_kingdom_filter <- function(kingdom) {
  if (is.null(kingdom)) return(NULL)
  if (!is.character(kingdom) || length(kingdom) == 0L) {
    stop("kingdom must be NULL or a character vector of kingdom names.",
         call. = FALSE)
  }
  set <- unique(normalize_kingdom_group(kingdom))
  set <- set[!is.na(set)]
  if (length(set) == 0L) {
    stop(sprintf(paste0(
      "kingdom: none of %s is a recognised kingdom. Use one of: animalia, ",
      "plantae, fungi, bacteria, archaea, chromista, protozoa, viruses ",
      "(aliases like \"animals\"/\"plants\" are accepted)."),
      paste(sQuote(kingdom), collapse = ", ")), call. = FALSE)
  }
  set
}


#' Demote matched rows back to unmatched (blanking their match columns)
#'
#' Used by the kingdom filter: an out-of-kingdom match is cleared so the
#' fallback chain treats the name as still unresolved (a later backbone may
#' supply an in-kingdom answer); a single-backend run then finalizes it to
#' `"none"`.
#'
#' @param result The match result data.frame.
#' @param rows Integer row indices to demote.
#' @return `result` with those rows blanked.
#' @noRd
demote_match_rows <- function(result, rows) {
  if (length(rows) == 0L) return(result)
  na_cols <- intersect(
    c("matched_name", "accepted_name", "taxon_id", "accepted_id", "rank",
      "family", "genus", "epithet", "authorship", "accepted_authorship",
      "is_synonym", "fuzzy_dist", "is_ambiguous", "ambiguous_targets",
      "aggregate_fallback", "backend", "backbone_version"),
    names(result))
  for (col in na_cols) result[[col]][rows] <- NA
  result$match_type[rows] <- NA_character_
  result
}


#' Drop matched rows whose kingdom is not among the requested set
#'
#' Reads each matched row's kingdom from the backbone's `kingdom` column where
#' it stores one, falling back to the genus register's `kingdom_group`. A row
#' whose resolved kingdom is known and outside `kingdom_set` is demoted (see
#' [demote_match_rows()]); an unknown kingdom is always kept.
#'
#' @param result The match result data.frame (post `run_match_stages()`).
#' @param bb_path Path to the backbone `.vtr`.
#' @param kingdom_set `NULL` (no-op) or a coarse kingdom-group vector.
#' @param be_name Backend name (unused directly; kept for symmetry / clarity).
#' @return `result`, possibly with out-of-kingdom rows demoted.
#' @noRd
filter_result_by_kingdom <- function(result, bb_path, kingdom_set, be_name) {
  if (is.null(kingdom_set)) return(result)
  matched <- which(!is.na(result$match_type) &
                     !result$match_type %in%
                       c("none", "out_of_scope", "hybrid_formula"))
  if (length(matched) == 0L) return(result)

  kg <- rep(NA_character_, nrow(result))

  # 1. Backbone kingdom column (COL/ITIS/NCBI/OTT/WoRMS store one).
  schema <- tryCatch(
    names(vectra::collect(utils::head(vectra::tbl(bb_path), 1L))),
    error = function(e) character(0L))
  if ("kingdom" %in% schema && "accepted_id" %in% names(result)) {
    j <- tryCatch(
      backbone_join(bb_path, result$accepted_id[matched], bb_key = "taxon_id",
                    select_cols = c("taxon_id", "kingdom")),
      error = function(e) NULL)
    if (!is.null(j) && nrow(j) > 0L) {
      j   <- j[!duplicated(j$lookup), , drop = FALSE]
      idx <- match(result$accepted_id[matched], j$lookup)
      kg[matched] <- normalize_kingdom_group(j$kingdom[idx])
    }
  }

  # 2. Genus register fallback for rows the backbone left unknown.
  need <- matched[is.na(kg[matched])]
  if (length(need) > 0L && "genus" %in% names(result)) {
    reg <- load_register_or_null()
    if (!is.null(reg) && all(c("genus", "kingdom_group") %in% names(reg))) {
      gk <- stats::setNames(reg$kingdom_group, reg$genus)
      kg[need] <- normalize_kingdom_group(unname(gk[result$genus[need]]))
    }
  }

  bad <- matched[!is.na(kg[matched]) & !(kg[matched] %in% kingdom_set)]
  demote_match_rows(result, bad)
}


#' Load the genus register from cache or disk, or NULL if unavailable
#'
#' @return The register data.frame, or NULL if it is not installed / fails to
#'   load.
#' @noRd
load_register_or_null <- function() {
  tryCatch({
    if (is.null(.taxify_env$register)) {
      path <- register_vtr_path()
      if (file.exists(path)) taxify_load_register(verbose = FALSE)
    }
    .taxify_env$register
  }, error = function(e) NULL)
}


#' Union of genera covered by the given backend(s)
#'
#' Reads the backend-coverage table once per backend and memoizes each backend's
#' covered-genus vector in the package environment.
#'
#' @param backend Character vector of backend names, or a `taxify_backend`.
#' @return A character vector of covered genera, or NULL when no coverage table
#'   is installed / it fails to read.
#' @noRd
covered_genera_for <- function(backend) {
  tryCatch({
    cov_path <- coverage_vtr_path()
    if (!file.exists(cov_path)) return(NULL)
    be_names <- if (is.character(backend)) backend else backend$name
    covered <- character(0)
    for (be in be_names) {
      cache_key <- paste0("coverage_", be)
      if (is.null(.taxify_env[[cache_key]])) {
        cov <- vectra::tbl(cov_path) |>
          vectra::filter(backend == be) |>
          vectra::collect()
        .taxify_env[[cache_key]] <- cov$genus
      }
      covered <- union(covered, .taxify_env[[cache_key]])
    }
    covered
  }, error = function(e) NULL)
}


#' Pre-filter out-of-scope names before fuzzy matching
#'
#' Checks unmatched names against the genus register and backend coverage.
#' Names whose genus is known but not covered by the requested backend are
#' marked `"out_of_scope"` immediately.
#'
#' @param result The match result data.frame after exact matching.
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param backend Character scalar or vector of backend names being tried.
#' @return The result data.frame, possibly with some NA match_type rows
#'   promoted to `"out_of_scope"`.
#' @noRd
prefilter_out_of_scope <- function(result, names_df, backend) {
  reg <- load_register_or_null()
  if (is.null(reg) || nrow(reg) == 0L) return(result)

  covered_genera <- covered_genera_for(backend)
  if (is.null(covered_genera)) return(result)

  reg_lookup <- stats::setNames(seq_len(nrow(reg)), reg$genus)

  unmatched_rows <- which(is.na(result$match_type) & !is.na(result$input_name))
  if (length(unmatched_rows) == 0L) return(result)

  cleaned_um <- names_df$cleaned[unmatched_rows]
  raw_um     <- result$input_name[unmatched_rows]
  genus_names <- ifelse(!is.na(cleaned_um) & nzchar(cleaned_um),
                        sub(" .*", "", cleaned_um),
                        ifelse(!is.na(raw_um) & nzchar(raw_um),
                               sub(" .*", "", trimws(raw_um)),
                               NA_character_))

  in_register   <- !is.na(genus_names) & nzchar(genus_names) &
                   !is.na(reg_lookup[genus_names])
  not_covered   <- !genus_names %in% covered_genera
  oos_mask      <- in_register & not_covered

  if (any(oos_mask)) {
    result$match_type[unmatched_rows[oos_mask]] <- "out_of_scope"
  }

  result
}


#' Enrich unmatched names using the unified genus register
#'
#' @param result The match result data.frame.
#' @param names_df The cleaned names data.frame from `clean_names()`.
#' @param backend Character scalar or vector of backend names that were tried.
#' @return The result data.frame with life_form enrichment.
#' @noRd
enrich_with_register <- function(result, names_df, backend) {
  reg <- load_register_or_null()
  if (is.null(reg) || nrow(reg) == 0L) return(result)

  covered_genera <- covered_genera_for(backend)

  # Ensure classification columns exist
  if (!"kingdom_group" %in% names(result)) result$kingdom_group <- NA_character_
  if (!"taxon_group"   %in% names(result)) result$taxon_group   <- NA_character_
  if (!"life_form"     %in% names(result)) result$life_form     <- NA_character_

  has_kingdom_group <- "kingdom_group" %in% names(reg)
  has_taxon_group   <- "taxon_group"   %in% names(reg)

  reg_lookup <- stats::setNames(seq_len(nrow(reg)), reg$genus)

  active_rows <- which(!is.na(result$input_name))
  if (length(active_rows) == 0L) return(result)

  mt <- result$match_type[active_rows]
  is_matched <- !is.na(mt) & mt != "none" & mt != "out_of_scope"

  genus_names <- rep(NA_character_, length(active_rows))

  if (any(is_matched)) {
    m_idx <- which(is_matched)
    m_rows <- active_rows[m_idx]
    g <- result$genus[m_rows]
    fallback <- is.na(g) | !nzchar(g)
    if (any(fallback)) {
      mn <- result$matched_name[m_rows[fallback]]
      g[fallback] <- ifelse(!is.na(mn), sub(" .*", "", mn), NA_character_)
    }
    genus_names[m_idx] <- g
  }

  if (any(!is_matched)) {
    u_idx <- which(!is_matched)
    u_rows <- active_rows[u_idx]
    cleaned_u <- names_df$cleaned[u_rows]
    raw_u     <- result$input_name[u_rows]
    genus_names[u_idx] <- ifelse(
      !is.na(cleaned_u) & nzchar(cleaned_u),
      sub(" .*", "", cleaned_u),
      ifelse(!is.na(raw_u) & nzchar(raw_u),
             sub(" .*", "", trimws(raw_u)),
             NA_character_)
    )
  }

  reg_idx <- unname(reg_lookup[genus_names])
  found <- !is.na(reg_idx)

  if (any(found)) {
    f_rows <- active_rows[found]
    f_idx  <- reg_idx[found]
    result$life_form[f_rows] <- reg$life_form[f_idx]
    if (has_kingdom_group) result$kingdom_group[f_rows] <- reg$kingdom_group[f_idx]
    if (has_taxon_group)   result$taxon_group[f_rows]   <- reg$taxon_group[f_idx]
  }

  if (!is.null(covered_genera)) {
    none_mask <- !is.na(mt) & mt == "none" & found
    if (any(none_mask)) {
      none_genera <- genus_names[none_mask]
      not_covered <- !none_genera %in% covered_genera
      if (any(not_covered)) {
        oos_rows <- active_rows[which(none_mask)[not_covered]]
        result$match_type[oos_rows] <- "out_of_scope"
      }
    }
  }

  result
}


#' Attach the taxify_result class and metadata attribute
#'
#' @param result A data.frame with the standard 16+ column schema.
#' @param backend Character vector of backend name(s) that were tried.
#' @return The same data.frame, classed as `c("taxify_result", "data.frame")`.
#' @noRd
as_taxify_result <- function(result, backend) {
  n_input <- nrow(result)

  mt <- result$match_type
  tally <- list(
    exact            = sum(mt == "exact",       na.rm = TRUE),
    case_insensitive = sum(mt == "exact_ci",    na.rm = TRUE),
    fuzzy            = sum(mt == "fuzzy",        na.rm = TRUE),
    abbrev           = sum(mt == "abbrev",      na.rm = TRUE),
    hybrid_formula   = sum(mt == "hybrid_formula", na.rm = TRUE),
    out_of_scope     = sum(mt == "out_of_scope", na.rm = TRUE),
    unmatched        = sum(mt == "none",         na.rm = TRUE)
  )

  # Out-of-scope breakdown by taxon_group
  oos_rows <- result[!is.na(mt) & mt == "out_of_scope", , drop = FALSE]
  tg_col   <- if ("taxon_group" %in% names(oos_rows)) "taxon_group" else "life_form"
  if (nrow(oos_rows) > 0L && tg_col %in% names(oos_rows)) {
    oos_tg  <- oos_rows[[tg_col]]
    oos_be  <- if ("backend" %in% names(oos_rows)) {
      oos_rows$backend
    } else {
      rep(backend[1L], nrow(oos_rows))
    }
    oos_tg[is.na(oos_tg)] <- "unknown"
    oos_be[is.na(oos_be)]  <- backend[1L]
    oos_combo_df   <- data.frame(taxon_group = oos_tg, backend = oos_be,
                                 stringsAsFactors = FALSE)
    oos_tally_df   <- aggregate(
      rep(1L, nrow(oos_combo_df)) ~ taxon_group + backend,
      data = oos_combo_df,
      FUN  = sum
    )
    names(oos_tally_df)[names(oos_tally_df) ==
                          "rep(1L, nrow(oos_combo_df))"] <- "n"
    oos_tally_df   <- oos_tally_df[order(oos_tally_df$taxon_group), , drop = FALSE]
    rownames(oos_tally_df) <- NULL
  } else {
    oos_tally_df <- data.frame(
      taxon_group = character(0L),
      backend     = character(0L),
      n           = integer(0L),
      stringsAsFactors = FALSE
    )
  }

  # Full taxon_group breakdown
  tg_col_all <- if ("taxon_group" %in% names(result)) "taxon_group" else "life_form"
  lf_tally_df <- if (tg_col_all %in% names(result)) {
    tg_vals <- result[[tg_col_all]]
    tg_vals[is.na(tg_vals)] <- "unknown"
    tg_tbl <- sort(table(tg_vals), decreasing = TRUE)
    data.frame(
      taxon_group = names(tg_tbl),
      n           = as.integer(tg_tbl),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  } else {
    data.frame(taxon_group = character(0L), n = integer(0L),
               stringsAsFactors = FALSE)
  }

  # Unmatched rows' taxon_group breakdown
  none_rows   <- result[!is.na(mt) & mt == "none", , drop = FALSE]
  tg_col_none <- if ("taxon_group" %in% names(none_rows)) "taxon_group" else "life_form"
  none_lf_df  <- if (nrow(none_rows) > 0L && tg_col_none %in% names(none_rows)) {
    tg_vals <- none_rows[[tg_col_none]]
    tg_vals[is.na(tg_vals)] <- "unknown"
    tg_tbl <- sort(table(tg_vals), decreasing = TRUE)
    data.frame(
      taxon_group = names(tg_tbl),
      n           = as.integer(tg_tbl),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  } else {
    data.frame(taxon_group = character(0L), n = integer(0L),
               stringsAsFactors = FALSE)
  }

  version <- NA_character_
  if ("backbone_version" %in% names(result)) {
    bv <- result$backbone_version[!is.na(result$backbone_version)]
    if (length(bv) > 0L) {
      version <- sub("^[^:]+:([^ ]+).*$", "\\1", bv[1L])
    }
  }

  meta <- list(
    backend                   = backend,
    version                   = version,
    n_input                   = n_input,
    match_tally               = tally,
    out_of_scope_tally        = oos_tally_df,
    life_form_tally           = lf_tally_df,
    unmatched_life_form_tally = none_lf_df
  )

  attr(result, "taxify_meta") <- meta
  class(result) <- c("taxify_result", "data.frame")
  result
}

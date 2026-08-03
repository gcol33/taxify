#' Add a trait from every source that carries it
#'
#' Attaches a single harmonized trait (e.g. woodiness, plant height) to a
#' [taxify()] result, pulling from every enrichment source that provides it and
#' reconciling their differing vocabularies and units. Where the per-source
#' `add_*()` doors each join one dataset, `add_trait()` is the cross-source
#' verb: you name the trait, it gathers the sources.
#'
#' Each source keeps its provenance. The default `"coalesce"` mode reduces the
#' sources to one value per row plus the columns that document it -- its unit,
#' the sources that contributed, how many, and a caution when the sources
#' measure the trait by different methods. The opt-in `"wide"` mode instead
#' gives every source its own column (`<trait>_<source>`), so per-source
#' agreement and conflict stay fully visible.
#'
#' @param x A data.frame returned by [taxify()].
#' @param trait Character. A single trait name; see [list_traits()] for the
#'   available traits and [trait_info()] for a trait's sources and units.
#' @param sources Which sources to use. Either the string `"all"` (the default)
#'   for every source registered for the trait, or a character vector of source
#'   names (see [trait_info()]).
#' @param mode One of `"coalesce"` (default) or `"wide"`. `"coalesce"` reduces
#'   the sources to one value per row (see `combine`). `"wide"` attaches one
#'   harmonized column per source.
#' @param combine How `mode = "coalesce"` reduces the per-source values for a
#'   row. `NULL` (default) is method-aware: when the trait's sources agree in
#'   method it uses `"median"` for numeric traits and `"first"` for categorical
#'   traits; when sources measure the trait differently (a source carries a
#'   caution, e.g. maximum vs fine-root diameter) it uses `"complete"` instead of
#'   blending them. Numeric options: `"median"`, `"mean"`, `"first"`
#'   (highest-priority source that has a value), `"min"`, `"max"`, `"complete"`
#'   (the single most populated source, reported verbatim). Categorical options:
#'   `"first"`, `"vote"` (majority across sources, ties broken by priority), or
#'   `"complete"`. Median is the numeric default for concordant sources because
#'   trait values are skewed, so a single outlier should not decide the value;
#'   `"complete"` is the default for discordant sources because a median across
#'   methods matches no method. Passing `combine` explicitly overrides this and
#'   is applied to all sources.
#' @param priority Character vector of source names giving the priority order
#'   (highest priority first), used by `combine = "first"`, for tie-breaking
#'   `combine = "vote"`, and to break ties in `combine = "complete"`. Only used
#'   when `mode = "coalesce"`; defaults to the registered order for the trait
#'   (see [trait_info()]).
#' @param verbose Logical. Default `TRUE`.
#' @param aggregate_trait_fallback Logical. When an aggregate or hybrid name has
#'   no trait record of its own, fall back to the underlying binomial. Defaults
#'   to `getOption("taxify.aggregate_trait_fallback", TRUE)`, so it can be set
#'   per call or for the session. Grain-pinned sources are unaffected.
#' @return The same data.frame with added columns.
#'   \describe{
#'     \item{`mode = "coalesce"`}{`<trait>` (the reduced value); `<trait>_unit`
#'       (the canonical unit, numeric traits only); `<trait>_sources` (the source
#'       it came from, or the comma-separated contributing sources with an
#'       aggregating `combine`); `<trait>_n` (how many sources backed the value);
#'       for numeric traits, `<trait>_min` and `<trait>_max` (the range of
#'       values behind the headline -- across the contributing sources, and
#'       across a source's own records where that spread was recorded at build
#'       time, so a life-stage or population span stays visible); and, only when
#'       a source measured the trait differently, `<trait>_caution` explaining
#'       the method difference. To inspect every source, use `mode = "wide"`.}
#'     \item{`mode = "wide"`}{One column per source, `<trait>_<source>`, each
#'       harmonized to the trait's shared vocabulary (categorical) or unit
#'       (numeric); `<trait>_unit`; and `<trait>_caution` on rows where a
#'       cautioned source supplied a value.}
#'   }
#'   Numeric traits are returned in the trait's canonical unit (see
#'   [trait_info()]); rows absent from a source get `NA`.
#'
#' @details
#' Harmonization is per source: a categorical source is mapped to the trait's
#' shared vocabulary, and a numeric source is converted to the trait's canonical
#' unit. For example, GIFT seed mass (grams) and Diaz et al. seed mass
#' (milligrams) both arrive as milligrams. The mappings and units for a trait
#' are listed by [trait_info()].
#'
#' Some sources report the same trait in the right unit but under a different
#' definition (for example AusTraits root diameter is a maximum including coarse
#' roots, while GRooT is fine-root only). Such a source carries a caution in the
#' registry. In `mode = "coalesce"` with the default `combine`, a trait whose
#' sources disagree in method is not blended: the most complete source is
#' reported and `<trait>_caution` records the difference. [trait_info()] lists
#' each source's harmonization note and caution.
#'
#' A source enrichment that is not installed and cannot be downloaded or built
#' is skipped with a warning, and the trait is assembled from the sources that
#' are available.
#'
#' @seealso [list_traits()] to see available traits, [trait_info()] for a
#'   trait's sources and units. The per-source doors ([add_zanne()],
#'   [add_gift()], [add_diaz_traits()], [add_leda()]) join one dataset each.
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # One coalesced value plus its provenance (unit, sources, count):
#' taxify("Abies alba") |>
#'   add_trait("seed_mass")
#'
#' # One column per source, to inspect agreement and conflict:
#' taxify("Abies alba") |>
#'   add_trait("woodiness", mode = "wide")
#'
#' options(old)
#'
#' @export
add_trait <- function(x, trait, sources = "all",
                      mode = c("coalesce", "wide"),
                      combine = NULL, priority = NULL, verbose = TRUE,
                      aggregate_trait_fallback =
                        getOption("taxify.aggregate_trait_fallback", TRUE)) {
  if (!is.data.frame(x) || !"accepted_name" %in% names(x)) {
    stop("Input must be a taxify() result with an 'accepted_name' column.",
         call. = FALSE)
  }
  mode  <- match.arg(mode)
  reg   <- .trait_registry()
  trait <- .resolve_trait_name(trait, names(reg))
  spec  <- reg[[trait]]
  auto    <- is.null(combine)                     # combine left to the default?
  combine <- .resolve_combine(combine, spec$kind)

  all_src <- names(spec$sources)
  use_src <- .resolve_trait_sources(sources, all_src, trait)

  # Coalesce order: explicit priority first, then registered order.
  if (is.null(priority)) {
    ord <- intersect(all_src, use_src)
  } else {
    bad <- setdiff(priority, all_src)
    if (length(bad)) {
      stop(sprintf(
        "add_trait(): unknown source(s) in priority for '%s': %s. Available: %s.",
        trait, paste(bad, collapse = ", "), paste(all_src, collapse = ", ")),
        call. = FALSE)
    }
    ord <- c(intersect(priority, use_src), setdiff(use_src, priority))
  }

  na_scalar <- if (spec$kind == "numeric") NA_real_ else NA_character_
  numeric   <- spec$kind == "numeric"
  per_src <- list()
  per_min <- list()          # per-source lower extreme (numeric traits only)
  per_max <- list()          # per-source upper extreme
  for (s in ord) {
    sp <- spec$sources[[s]]
    jc <- sp$join_col %||% "accepted_name"
    if (numeric) {
      # Fetch the source's value plus its within-source min/max where the .vtr
      # stores them (built by taxifydb where a source has several records per
      # species); where it does not, min = max = value, so the spread reduces to
      # the cross-source range.
      tr <- .trait_join_spread(x, sp$enrichment, sp$col, jc, sp$map, verbose,
                               aggregate_trait_fallback = aggregate_trait_fallback)
      if (is.null(tr)) {
        na <- rep(NA_real_, nrow(x))
        per_src[[s]] <- na; per_min[[s]] <- na; per_max[[s]] <- na
      } else {
        per_src[[s]] <- tr$value; per_min[[s]] <- tr$min; per_max[[s]] <- tr$max
      }
    } else {
      raw <- .trait_join_one(x, sp$enrichment, sp$col, spec$kind,
                             join_col = jc, group = sp$group,
                             verbose = verbose,
                             aggregate_trait_fallback = aggregate_trait_fallback)
      per_src[[s]] <- if (is.null(raw)) rep(na_scalar, nrow(x)) else sp$map(raw)
    }
  }

  # Two kinds of caution. Static per-source cautions (`cvec`) flag a whole source
  # whose method/definition differs from the reference; they drive the coalesce's
  # complete-vs-median switch below. Per-record cautions (`perrec`) flag
  # individual species from a companion column in the same enrichment (e.g. a
  # model-imputed PHYLACINE body mass) and are provenance annotations only, so
  # they are kept out of `cvec` and the discordance test.
  is_perrec <- function(sp) {
    cc <- sp$caution_col
    !is.null(cc) && length(cc) && !is.na(cc) && nzchar(cc) && !is.null(sp$caution_fn)
  }
  cvec <- vapply(ord, function(s) {
    sp <- spec$sources[[s]]
    if (is_perrec(sp)) NA_character_ else sp$caution %||% NA_character_
  }, character(1L))
  names(cvec) <- ord
  perrec <- list()
  for (s in ord) {
    sp <- spec$sources[[s]]
    if (!is_perrec(sp)) next
    jc   <- sp$join_col %||% "accepted_name"
    comp <- .trait_join_one(x, sp$enrichment, sp$caution_col, "categorical",
                            join_col = jc, group = sp$group, verbose = FALSE,
                            aggregate_trait_fallback = aggregate_trait_fallback)
    if (is.null(comp)) next
    ctext <- sp$caution_fn(comp)
    ctext[is.na(per_src[[s]])] <- NA_character_   # only where the source has a value
    if (any(!is.na(ctext))) perrec[[s]] <- ctext
  }
  # Discordance is data-aware: it only matters when at least two sources actually
  # supply values here and one of them is cautioned. A single source that has
  # data is not a method conflict (its own caution is still surfaced per row).
  has_data     <- vapply(ord, function(s) any(!is.na(per_src[[s]])), logical(1L))
  contributing <- ord[has_data]
  disc <- length(contributing) >= 2L && any(!is.na(cvec[contributing]))
  unit <- if (!is.null(spec$unit) && !is.na(spec$unit)) spec$unit else NULL

  if (mode == "wide") {
    for (s in ord) x[[paste0(trait, "_", s)]] <- per_src[[s]]
    if (!is.null(unit)) x[[paste0(trait, "_unit")]] <- unit
    cr <- .trait_wide_caution(per_src, cvec, nrow(x))
    cr <- .merge_perrec_caution(cr, perrec, NULL, nrow(x))
    if (!is.null(cr)) x[[paste0(trait, "_caution")]] <- cr
  } else {
    # When sources measure the trait differently, do not blend: report the most
    # complete source and explain (unless the caller forced `combine`).
    use_combine <- if (auto && disc) "complete" else combine
    co <- .coalesce_sources(per_src[ord], ord, spec$kind, use_combine)
    x[[trait]] <- co$value
    if (!is.null(unit)) x[[paste0(trait, "_unit")]] <- unit
    x[[paste0(trait, "_sources")]] <- co$source
    x[[paste0(trait, "_n")]]       <- co$n
    # Numeric traits also report the spread: the smallest and largest observed
    # value across the contributing sources -- widened to each source's stored
    # within-source min/max where taxifydb recorded it. The coalesced value stays
    # the headline (median by default); min/max let a reader see the range and
    # decide whether to go back to a source (e.g. a life-stage span). `<trait>_n`
    # remains the number of contributing sources.
    if (numeric) {
      sp_range <- .coalesce_spread(per_min[ord], per_max[ord])
      x[[paste0(trait, "_min")]] <- sp_range$min
      x[[paste0(trait, "_max")]] <- sp_range$max
    }
    cr <- .trait_caution_col(co, cvec, disc, use_combine)
    cr <- .merge_perrec_caution(cr, perrec, co$source, nrow(x))
    if (!is.null(cr)) x[[paste0(trait, "_caution")]] <- cr
    if (auto && disc && verbose && any(!is.na(co$value))) {
      message(sprintf(
        paste0("add_trait('%s'): sources use different methods; reported the ",
               "most complete source ('%s'). See '%s_caution' or mode = \"wide\"."),
        trait, co$best, trait))
    }
  }

  attr(x, "taxify_traits") <- c(
    attr(x, "taxify_traits") %||% list(),
    stats::setNames(list(ord), trait)
  )

  # Record each source so cite() can credit it. A source is registered with the
  # number of rows it actually supplied a value for; sources that contributed
  # nothing get n_matched = 0 and are dropped by cite().
  for (s in ord) {
    sp <- spec$sources[[s]]
    x <- register_enrichment(
      x,
      name      = sp$enrichment,
      source_label = sp$citation %||% sp$enrichment,
      version   = NA_character_,
      n_matched = sum(!is.na(per_src[[s]]))
    )
  }
  x
}


#' List the traits available to add_trait()
#'
#' Returns the traits that [add_trait()] can attach across sources, with their
#' kind, canonical unit, and the number and names of contributing sources.
#'
#' @return A data.frame with one row per trait:
#' \describe{
#'   \item{trait}{The trait name to pass to [add_trait()].}
#'   \item{label}{Human-readable label.}
#'   \item{kind}{`"numeric"` or `"categorical"`.}
#'   \item{unit}{Canonical unit for numeric traits, `NA` for categorical.}
#'   \item{n_sources}{Number of sources providing the trait.}
#'   \item{sources}{Comma-separated source names.}
#' }
#' @seealso [add_trait()], [trait_info()]
#' @examples
#' list_traits()
#' @export
list_traits <- function() {
  reg <- .trait_registry()
  data.frame(
    trait     = names(reg),
    label     = vapply(reg, function(t) t$label, character(1L)),
    kind      = vapply(reg, function(t) t$kind, character(1L)),
    unit      = vapply(reg, function(t) t$unit %||% NA_character_, character(1L)),
    n_sources = vapply(reg, function(t) length(t$sources), integer(1L)),
    sources   = vapply(reg, function(t) paste(names(t$sources), collapse = ", "),
                       character(1L)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}


#' Describe a trait's sources and units
#'
#' Prints the kind, canonical unit, and (for categorical traits) the shared
#' vocabulary of a trait, and returns a data.frame of the sources
#' [add_trait()] draws from -- one row per source, with its enrichment, source
#' column, citation, and the harmonization note (unit conversion or vocabulary
#' mapping).
#'
#' @param trait Character. A single trait name; see [list_traits()].
#' @return A data.frame (invisibly-friendly) with columns `source`,
#'   `enrichment`, `column`, `citation`, `note` (unit or vocabulary
#'   harmonization), and `caution` (a method or definition difference from the
#'   reference source, or `NA`). The header line (label, kind, unit, default
#'   priority, vocabulary) is printed as a message.
#' @seealso [add_trait()], [list_traits()]
#' @examples
#' trait_info("woodiness")
#' @export
trait_info <- function(trait) {
  reg   <- .trait_registry()
  trait <- .resolve_trait_name(trait, names(reg))
  spec  <- reg[[trait]]
  srcs  <- spec$sources

  hdr <- sprintf(
    "%s (%s%s)  |  default priority: %s",
    spec$label, spec$kind,
    if (!is.na(spec$unit)) paste0(", ", spec$unit) else "",
    paste(names(srcs), collapse = " > ")
  )
  if (spec$kind == "categorical" && !is.null(spec$vocab)) {
    hdr <- paste0(hdr, "\nvocabulary: ", paste(spec$vocab, collapse = ", "))
  }
  message(hdr)

  data.frame(
    source     = names(srcs),
    enrichment = vapply(srcs, function(s) s$enrichment, character(1L)),
    column     = vapply(srcs, function(s) s$col, character(1L)),
    citation   = vapply(srcs, function(s) s$citation %||% NA_character_, character(1L)),
    note       = vapply(srcs, function(s) s$note %||% NA_character_, character(1L)),
    caution    = vapply(srcs, function(s) s$caution %||% NA_character_, character(1L)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

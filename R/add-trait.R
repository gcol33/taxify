#' Add a trait from every source that carries it
#'
#' Attaches a single harmonized trait (e.g. woodiness, plant height) to a
#' [taxify()] result, pulling from every enrichment source that provides it and
#' reconciling their differing vocabularies and units. Where the per-source
#' `add_*()` doors each join one dataset, `add_trait()` is the cross-source
#' verb: you name the trait, it gathers the sources.
#'
#' Each source keeps its provenance. In the default `"wide"` mode every source
#' becomes its own column (`<trait>_<source>`), so agreement and conflict stay
#' visible; sources are never silently collapsed. The opt-in `"coalesce"` mode
#' adds a single best-available value together with the source that supplied it.
#'
#' @param x A data.frame returned by [taxify()].
#' @param trait Character. A single trait name; see [list_traits()] for the
#'   available traits and [trait_info()] for a trait's sources and units.
#' @param sources Which sources to use. Either the string `"all"` (the default)
#'   for every source registered for the trait, or a character vector of source
#'   names (see [trait_info()]).
#' @param mode One of `"wide"` (default) or `"coalesce"`. `"wide"` attaches one
#'   harmonized column per source. `"coalesce"` attaches one value per row,
#'   taken from the highest-priority source that has one.
#' @param priority Character vector of source names giving the coalesce order
#'   (highest priority first). Only used when `mode = "coalesce"`; defaults to
#'   the registered order for the trait (see [trait_info()]).
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with added columns.
#'   \describe{
#'     \item{`mode = "wide"`}{One column per source, `<trait>_<source>`, each
#'       harmonized to the trait's shared vocabulary (categorical) or unit
#'       (numeric).}
#'     \item{`mode = "coalesce"`}{Three columns: `<trait>` (the coalesced
#'       value), `<trait>_source` (which source it came from), and `<trait>_n`
#'       (how many sources had any value for that row). To inspect conflicts
#'       between sources, use `mode = "wide"`.}
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
#' # One column per source, harmonized:
#' taxify("Abies alba") |>
#'   add_trait("woodiness")
#'
#' # Numeric trait, coalesced to one value plus its provenance:
#' taxify("Abies alba") |>
#'   add_trait("seed_mass", mode = "coalesce")
#'
#' options(old)
#'
#' @export
add_trait <- function(x, trait, sources = "all",
                      mode = c("wide", "coalesce"),
                      priority = NULL, verbose = TRUE) {
  if (!is.data.frame(x) || !"accepted_name" %in% names(x)) {
    stop("Input must be a taxify() result with an 'accepted_name' column.",
         call. = FALSE)
  }
  mode  <- match.arg(mode)
  reg   <- .trait_registry()
  trait <- .resolve_trait_name(trait, names(reg))
  spec  <- reg[[trait]]

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
  per_src <- list()
  for (s in ord) {
    sp  <- spec$sources[[s]]
    raw <- .trait_join_one(x, sp$enrichment, sp$col, spec$kind, verbose = verbose)
    per_src[[s]] <- if (is.null(raw)) rep(na_scalar, nrow(x)) else sp$map(raw)
  }

  if (mode == "wide") {
    for (s in ord) x[[paste0(trait, "_", s)]] <- per_src[[s]]
  } else {
    n    <- nrow(x)
    val  <- rep(na_scalar, n)
    src  <- rep(NA_character_, n)
    nsrc <- integer(n)
    for (s in ord) {
      v    <- per_src[[s]]
      nsrc <- nsrc + as.integer(!is.na(v))
      take <- is.na(val) & !is.na(v)
      val[take] <- v[take]
      src[take] <- s
    }
    x[[trait]]                    <- val
    x[[paste0(trait, "_source")]] <- src
    x[[paste0(trait, "_n")]]      <- nsrc
  }

  attr(x, "taxify_traits") <- c(
    attr(x, "taxify_traits") %||% list(),
    stats::setNames(list(ord), trait)
  )
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
#'   `enrichment`, `column`, `citation`, `note`. The header line (label, kind,
#'   unit, default priority, vocabulary) is printed as a message.
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
    stringsAsFactors = FALSE, row.names = NULL
  )
}

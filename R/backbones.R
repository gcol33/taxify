# ---- Canonical backbone registry + discovery verbs ----
#
# The set of supported taxonomic backbones is defined once, here. resolve_backend()
# (construction dispatch), installed_backbones() (local presence check), and
# list_backbones() / taxify_databases() (discovery) all read the names and scope
# labels from this registry, so the supported set can never drift between them.
# Dynamic fields (version, row count, download size) come from the manifest at
# call time; the manifest does not define membership.


#' Canonical registry of supported backbones
#'
#' The single source of truth for the supported-backbone set. Alongside the
#' display fields (`scope`, `source`) it carries the construction fields the
#' backbone factory reads: `label` (human name used in build/shim messages),
#' `version` (the static default the runtime falls back to when neither a
#' downloaded meta.json nor the manifest supplies one), and `prefix_fallback`
#' (whether the prefix-blocked fuzzy pass runs for this backbone).
#'
#' @return A data.frame with `name`, `scope`, `source` (homepage), `label`,
#'   `version`, and `prefix_fallback`, in canonical display order.
#' @noRd
.backbone_registry <- function() {
  data.frame(
    name = c(
      "wfo", "col", "colxr", "gbif", "itis", "ncbi", "ott", "worms", "euromed",
      "fungorum", "algaebase", "fishbase", "sealifebase", "reptiledb",
      "lcvp", "wcvp", "mdd", "avilist", "lpsn"
    ),
    scope = c(
      "Vascular plants", "All kingdoms", "All kingdoms", "All kingdoms",
      "US focus, freshwater/marine", "All life", "All life (synthetic)",
      "Marine/aquatic", "European/Mediterranean plants", "Fungi", "Algae",
      "Fishes", "Non-fish marine/aquatic", "Reptiles",
      "Vascular plants", "Vascular plants", "Mammals", "Birds",
      "Prokaryotes (Bacteria/Archaea)"
    ),
    source = c(
      "https://www.worldfloraonline.org/",
      "https://www.catalogueoflife.org/",
      "https://www.catalogueoflife.org/",
      "https://www.gbif.org/",
      "https://www.itis.gov",
      "https://www.ncbi.nlm.nih.gov/taxonomy",
      "https://opentreeoflife.github.io/",
      "https://www.marinespecies.org/",
      "https://europlusmed.org/",
      "https://www.speciesfungorum.org/",
      "https://www.algaebase.org/",
      "https://www.fishbase.org/",
      "https://www.sealifebase.org/",
      "http://www.reptile-database.org/",
      "https://github.com/idiv-biodiversity/LCVP",
      "https://powo.science.kew.org/",
      "https://www.mammaldiversity.org/",
      "https://www.avilist.org/",
      "https://lpsn.dsmz.de"
    ),
    label = c(
      "the WFO backbone", "the COL backbone",
      "the COL Extended Release backbone", "the GBIF backbone",
      "the ITIS backbone", "the NCBI backbone", "the OTT backbone",
      "the WoRMS backbone", "the Euro+Med backbone",
      "the Species Fungorum backbone", "the AlgaeBase backbone",
      "the FishBase backbone", "the SeaLifeBase backbone",
      "the Reptile Database backbone", "the LCVP backbone", "the WCVP backbone",
      "the Mammal Diversity Database backbone", "the AviList backbone",
      "the LPSN backbone"
    ),
    version = c(
      "2024-12", "2025", "2026-07-17", "2023-08-28", "2025.04", "2025.04",
      "3.7.3", "2025.04",
      "2026.07", "2025.04", "2025.04", "2026.06", "2026.06", "2026.06",
      "3.0.1", "2026.06", "2.5", "2025b", "2026.07"
    ),
    prefix_fallback = c(
      TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE
    ),
    stringsAsFactors = FALSE
  )
}


#' Names of all supported backbones, in canonical order
#' @noRd
backbone_names <- function() {
  .backbone_registry()$name
}


#' Human label for a backbone, for build/shim messages
#'
#' @param name Backbone name.
#' @return The registry `label` string (e.g. `"the WFO backbone"`).
#' @noRd
backbone_label <- function(name) {
  reg <- .backbone_registry()
  reg$label[match(name, reg$name)]
}


# ---- Default-backbone resolution (all installed, priority-ordered) ----
#
# taxify(backbone = NULL) matches against every installed backbone as a
# first-match fallback chain: accepted_name comes from the first backbone (in
# the priority order below) that matched each name. The order is the editorial
# call behind that pick -- it trusts the most current, authoritative treatment
# first. It is not a consensus/vote (that would regress toward the stalest
# treatment across backbones that copy each other); disagreement is surfaced
# instead via mode = "agreement" / "wide".


#' Backbone priority order for the first-match fallback pick
#'
#' The modern multi-kingdom syntheses (COL Extended Release, then COL) first,
#' then the domain authorities (marine, vascular plants, fungi, algae, fishes,
#' reptiles, mammals, birds, prokaryotes), then the broad but more conservative
#' aggregators (GBIF, ITIS, NCBI, OTT). Override with
#' `options(taxify.backbone_priority = c(...))`; any omitted known backbone is
#' appended so the order stays total over the registry.
#'
#' @return Character vector of every backbone name, in priority order.
#' @noRd
.backbone_priority <- function() {
  default <- c(
    "colxr", "col", "worms", "wcvp", "euromed", "lcvp", "wfo",
    "fungorum", "algaebase", "fishbase", "sealifebase", "reptiledb", "mdd", "avilist",
    "lpsn",
    "gbif", "itis", "ncbi", "ott"
  )
  known <- backbone_names()
  # Guard against a registry change leaving a name out of the default list.
  default <- c(intersect(default, known), setdiff(known, default))

  opt <- getOption("taxify.backbone_priority")
  if (is.null(opt)) return(default)
  opt <- as.character(opt)
  opt <- opt[opt %in% known]
  c(opt, setdiff(default, opt))
}


#' Order a set of backbone names by the fallback priority
#'
#' @param names Character vector of backbone names.
#' @return `names`, reordered by `.backbone_priority()`. Unknown names sort last
#'   in their original order.
#' @noRd
order_by_priority <- function(names) {
  pr <- .backbone_priority()
  names[order(match(names, pr, nomatch = length(pr) + 1L),
              seq_along(names))]
}


#' The set installed on first run when no backbone is present yet
#'
#' Two multi-kingdom authorities plus a third cross-check: COL (modern
#' synthesis, priority 1), GBIF (broad, conservative), ITIS (an independent
#' third opinion). Enough for cross-kingdom coverage and a meaningful
#' cross-backbone agreement signal from the first call. Override with
#' `options(taxify.default_backbones = c(...))`.
#'
#' @return Character vector of backbone names, in priority order.
#' @noRd
.default_backbone_set <- function() {
  opt <- getOption("taxify.default_backbones")
  set <- if (!is.null(opt) && is.character(opt) && length(opt)) {
    intersect(opt, backbone_names())
  } else {
    c("col", "gbif", "itis")
  }
  order_by_priority(set)
}


#' Human-readable total download size for a set of backbones
#'
#' @param set Character vector of backbone names.
#' @return A string like `" (~4.0 GB total)"`, or `""` when the manifest is
#'   unreachable or a size is missing (so the message never shows a wrong total).
#' @noRd
default_set_size_note <- function(set) {
  bb <- tryCatch(fetch_manifest()$backends, error = function(e) NULL)
  if (is.null(bb)) return("")
  total <- 0
  for (nm in set) {
    s <- tryCatch(bb[[nm]]$full_size, error = function(e) NULL)
    if (is.null(s) || length(s) != 1L || is.na(s)) return("")
    total <- total + as.numeric(s)
  }
  sprintf(" (~%.1f GB total)", total / 1073741824)
}


#' Resolve the default backbone when `taxify(backbone = NULL)` is called
#'
#' Every installed backbone, in priority order. On a fresh setup with none
#' installed, downloads the default set (`.default_backbone_set()`) first.
#'
#' @param verbose Logical.
#' @return Character vector of backbone names in priority order.
#' @noRd
resolve_default_backend <- function(verbose = TRUE) {
  inst <- installed_backbones()
  if (length(inst) > 0L) return(order_by_priority(inst))

  set <- .default_backbone_set()
  if (verbose) {
    message(sprintf(paste0(
      "No taxonomic backbone installed yet -- downloading the default set: ",
      "%s%s.\nThis runs once; files are cached in %s. Pre-install a different ",
      "set with install_backbones(), or set it via ",
      "options(taxify.default_backbones = ...)."),
      paste(toupper(set), collapse = ", "),
      default_set_size_note(set), taxify_data_dir()))
  }
  install_backbones(set, verbose = verbose)

  inst <- order_by_priority(intersect(set, installed_backbones()))
  if (length(inst) == 0L) {
    stop("Could not install any default backbone. Check your internet ",
         "connection, or install one manually with install_backbones().",
         call. = FALSE)
  }
  inst
}


#' Resolve a single default backbone for the reverse/browse verbs
#'
#' The browse and lookup verbs ([synonyms()], [children()], [downstream()],
#' [upstream()], [id2name()]) read one backbone directly rather than running the
#' whole fallback chain, so `backbone = NULL` resolves to the highest-priority
#' installed backbone -- installing the default set on a fresh machine exactly as
#' [taxify()] does, never a specific backbone the user did not ask for. A name or
#' a `taxify_backend` object is returned unchanged.
#'
#' @param backbone `NULL`, a backbone name, or a `taxify_backend` object.
#' @param verbose Logical.
#' @return A single backbone name, or the `taxify_backend` object passed in.
#' @noRd
resolve_single_backend <- function(backbone, verbose = TRUE) {
  if (is.null(backbone)) return(resolve_default_backend(verbose = verbose)[[1L]])
  backbone
}


#' Install taxonomic backbones for offline matching
#'
#' Downloads the pre-built `.vtr` for each named backbone into the taxify data
#' directory ([taxify_data_dir()]), so subsequent [taxify()] calls match against
#' them offline. taxify installs its default set automatically on first use
#' (COL, GBIF, ITIS); call this to pre-install a specific set, add a backbone to
#' the default, or refresh to the latest release. Already-current backbones are
#' skipped.
#'
#' @param backbones Character vector of backbone names (see [list_backbones()]).
#'   `NULL` (default) installs taxify's first-run set: COL, GBIF, and ITIS.
#' @param verbose Logical. Default `TRUE`.
#' @return Invisibly, the backbones now installed (those that downloaded
#'   successfully), in priority order.
#' @seealso [list_backbones()] for the full set with sizes, [taxify()].
#' @examples
#' \dontrun{
#' # Pre-install a marine-focused set before matching:
#' install_backbones(c("col", "worms"))
#' }
#' @export
install_backbones <- function(backbones = NULL, verbose = TRUE) {
  if (is.null(backbones)) backbones <- .default_backbone_set()
  backbones <- as.character(backbones)
  unknown  <- setdiff(backbones, backbone_names())
  if (length(unknown)) {
    stop(sprintf("Unknown backbone(s): %s. See list_backbones().",
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }

  ok <- character(0)
  for (nm in order_by_priority(unique(backbones))) {
    installed <- tryCatch({
      ensure_backbone(resolve_backend(nm), verbose = verbose)
      TRUE
    }, error = function(e) {
      warning(sprintf("Could not install backbone '%s': %s", nm,
                      conditionMessage(e)), call. = FALSE)
      FALSE
    })
    if (isTRUE(installed)) ok <- c(ok, nm)
  }
  invisible(order_by_priority(ok))
}


#' List supported taxonomic backbones
#'
#' Returns every taxonomic backbone `taxify()` can match against, its taxonomic
#' scope, and (once the manifest is reachable) its current version, name count,
#' download size, and whether it is already installed locally. The counterpart to
#' [list_enrichments()] for the backbone side.
#'
#' @param verbose Logical. Default `TRUE`.
#' @return A data.frame with columns: `name`, `scope`, `n_names`, `size_mb`,
#'   `version`, `source_date`, `installed`, `source`. `n_names`, `size_mb`, and
#'   `version` are `NA` for any backbone the manifest does not yet describe or
#'   when the manifest cannot be fetched offline.
#'
#'   `version` is the release that packaged the backbone; `source_date` is the
#'   date of the upstream data, which can be much earlier. The GBIF backbone is
#'   the case that matters: GBIF froze it at 2023-08-28 and has said it will not
#'   be updated again, so a current release tag there carries a treatment three
#'   years older than the tag suggests. `source_date` is `NA` for a backbone
#'   whose upstream date has not been recorded.
#'
#' @seealso [list_enrichments()], [list_traits()], [taxify_databases()].
#'
#' @examples
#' \dontrun{
#' list_backbones()
#' }
#'
#' @export
list_backbones <- function(verbose = TRUE) {
  reg <- .backbone_registry()
  manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)
  bb <- if (!is.null(manifest)) manifest$backends else NULL
  inst <- installed_backbones()

  field <- function(nm, key, default) {
    if (is.null(bb) || is.null(bb[[nm]])) return(default)
    bb[[nm]][[key]] %||% default
  }

  data.frame(
    name    = reg$name,
    scope   = reg$scope,
    n_names = vapply(reg$name, function(n) {
      as.integer(field(n, "nrow", NA_integer_))
    }, integer(1L)),
    size_mb = vapply(reg$name, function(n) {
      s <- field(n, "full_size", NA_real_)
      if (is.na(s)) NA_real_ else round(as.numeric(s) / 1048576)
    }, numeric(1L)),
    version = vapply(reg$name, function(n) {
      as.character(field(n, "latest", NA_character_))
    }, character(1L)),
    # The date of the upstream data, which is not the date of the build that
    # packaged it: the GBIF backbone is frozen at 2023-08-28 but is packaged
    # under a current release tag, so `version` alone reads as more recent
    # than the treatment actually is. Absent for a backbone whose upstream
    # date has not been recorded.
    source_date = vapply(reg$name, function(n) {
      as.character(field(n, "source_date", NA_character_))
    }, character(1L)),
    installed = reg$name %in% inst,
    source    = reg$source,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}


#' One overview of every database taxify knows about
#'
#' Stacks the taxonomic backbones (from [list_backbones()]) and the trait/status
#' enrichments (from [list_enrichments()]) into a single frame with a `type`
#' column, so a new user can see the full breadth in one call rather than needing
#' to know three separate discovery verbs. The cross-source trait vocabulary is
#' summarised in the message footer; browse it with [list_traits()].
#'
#' @param verbose Logical. When `TRUE` (default), prints a one-line count of
#'   backbones, enrichments, and registered traits.
#' @return A data.frame with columns: `type` (`"backbone"` or `"enrichment"`),
#'   `name`, `scope` (taxonomic scope for backbones; provided trait columns for
#'   enrichments), `n_rows`, `version`, `source_date` (the date of the upstream
#'   data, where recorded, which can be much earlier than the release `version`
#'   that packaged it), `installed`, `source`.
#'
#' @seealso [list_backbones()], [list_enrichments()], [list_traits()].
#'
#' @examples
#' \dontrun{
#' taxify_databases()
#' }
#'
#' @export
taxify_databases <- function(verbose = TRUE) {
  bb <- list_backbones(verbose = FALSE)
  en <- list_enrichments(verbose = FALSE)

  bb2 <- data.frame(
    type = "backbone", name = bb$name, scope = bb$scope,
    n_rows = bb$n_names, version = bb$version,
    source_date = bb$source_date, installed = bb$installed,
    source = bb$source, stringsAsFactors = FALSE
  )
  en2 <- data.frame(
    type = "enrichment", name = en$name, scope = en$trait_cols,
    n_rows = en$nrow, version = en$version,
    source_date = NA_character_, installed = NA,
    source = en$source_url, stringsAsFactors = FALSE
  )
  out <- rbind(bb2, en2)
  rownames(out) <- NULL

  if (verbose) {
    n_traits <- tryCatch(nrow(list_traits()), error = function(e) NA_integer_)
    message(sprintf(
      "%d backbones, %d enrichments%s. Browse: list_backbones(), list_enrichments(), list_traits().",
      nrow(bb2), nrow(en2),
      if (is.na(n_traits)) "" else sprintf(", %d cross-source traits", n_traits)
    ))
  }
  out
}

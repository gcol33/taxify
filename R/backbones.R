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
#' @return A data.frame with `name`, `scope`, and `source` (homepage), in
#'   canonical display order.
#' @noRd
.backbone_registry <- function() {
  data.frame(
    name = c(
      "wfo", "col", "gbif", "itis", "ncbi", "ott", "worms", "euromed",
      "fungorum", "algaebase", "fishbase", "sealifebase", "reptiledb",
      "lcvp", "wcvp"
    ),
    scope = c(
      "Vascular plants", "All kingdoms", "All kingdoms",
      "US focus, freshwater/marine", "All life", "All life (synthetic)",
      "Marine/aquatic", "European/Mediterranean plants", "Fungi", "Algae",
      "Fishes", "Non-fish marine/aquatic", "Reptiles",
      "Vascular plants", "Vascular plants"
    ),
    source = c(
      "https://www.worldfloraonline.org/",
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
      "https://www.idiv.de/en/lcvp.html",
      "https://powo.science.kew.org/"
    ),
    stringsAsFactors = FALSE
  )
}


#' Names of all supported backbones, in canonical order
#' @noRd
backbone_names <- function() {
  .backbone_registry()$name
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
#'   `version`, `installed`, `source`. `n_names`, `size_mb`, and `version` are
#'   `NA` for any backbone the manifest does not yet describe or when the manifest
#'   cannot be fetched offline.
#'
#' @seealso [list_enrichments()], [list_traits()], [taxify_databases()].
#'
#' @examples
#' \donttest{
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
#'   enrichments), `n_rows`, `version`, `installed`, `source`.
#'
#' @seealso [list_backbones()], [list_enrichments()], [list_traits()].
#'
#' @examples
#' \donttest{
#' taxify_databases()
#' }
#'
#' @export
taxify_databases <- function(verbose = TRUE) {
  bb <- list_backbones(verbose = FALSE)
  en <- list_enrichments(verbose = FALSE)

  bb2 <- data.frame(
    type = "backbone", name = bb$name, scope = bb$scope,
    n_rows = bb$n_names, version = bb$version, installed = bb$installed,
    source = bb$source, stringsAsFactors = FALSE
  )
  en2 <- data.frame(
    type = "enrichment", name = en$name, scope = en$trait_cols,
    n_rows = en$nrow, version = en$version, installed = NA,
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

# ---- Upstream: the higher classification of a taxon ----
#
# downstream() walks the classification down (every species in an order).
# upstream() walks it up: the lineage of ancestors above a taxon (its genus,
# family, order, ... up to kingdom). Where add_classification() attaches those
# ranks to a taxify() result as columns, upstream() takes a bare name and
# returns the lineage as a tidy long frame, one row per ancestor rank. A
# synonym or misspelling is resolved to its accepted taxon first, so the lineage
# is the accepted taxon's.


# Linnaean rank ordering (coarse -> fine). Only the six ranks the backbones
# store as denormalized columns can be returned as ancestors; the ordering also
# places the query's own rank so ancestors are the ranks strictly above it.
.upstream_rank_order <- c(
  kingdom = 1L, phylum = 2L, class = 3L, order = 4L, family = 5L,
  genus = 6L, species = 7L, subspecies = 8L, variety = 8L, form = 8L,
  infraspecies = 8L
)

# The six ancestor columns, coarse -> fine.
.upstream_cols <- c("kingdom", "phylum", "class", "order", "family", "genus")


#' List the higher classification (ancestors) of a taxon
#'
#' Returns the lineage above `taxon` -- its genus, family, order, class, phylum,
#' and kingdom, for whichever of those ranks the backbone stores -- as a tidy
#' frame with one row per ancestor rank. Where [downstream()] reaches down to
#' descendants, `upstream()` reaches up to ancestors; where [add_classification()]
#' attaches the ranks to an existing [taxify()] result, `upstream()` takes a bare
#' name. A synonym or misspelling is resolved to its accepted taxon first, so the
#' lineage returned is the accepted taxon's.
#'
#' @param taxon A single taxonomic name (a species, genus, or higher taxon;
#'   synonyms and typos are resolved first).
#' @param backbone A single backbone name or a `taxify_backend` object. `NULL`
#'   (default) uses the highest-priority installed backbone; name one that
#'   stores the higher ranks (e.g. `"col"`) for a full lineage.
#' @param to Optional rank (or ranks) to restrict the output to -- e.g.
#'   `to = "family"` answers "what family is this in?" with a single row.
#'   `NULL` (default) returns the whole lineage.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per ancestor rank, columns: `input_name` (the
#'   name as supplied), `accepted_name` (what it resolved to), `rank`, `name`,
#'   `backbone`, ordered kingdom -> genus. Empty when `taxon` does not resolve or
#'   the backbone stores no ranks above it.
#'
#' @seealso [downstream()] for descendants, [add_classification()] to attach the
#'   ranks to a [taxify()] result, [lowest_common()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # The lineage above a species (reptiledb carries the full higher hierarchy)
#' upstream("Naja naja", backbone = "reptiledb")
#'
#' # Just the family
#' upstream("Naja naja", backbone = "reptiledb", to = "family")
#'
#' options(old)
#'
#' @export
upstream <- function(taxon, backbone = NULL, to = NULL, verbose = TRUE) {
  if (!is.character(taxon) || length(taxon) != 1L || is.na(taxon) ||
      !nzchar(trimws(taxon))) {
    stop("taxon must be a single non-empty name.", call. = FALSE)
  }
  backbone <- resolve_single_backend(backbone, verbose = verbose)
  bb_name <- if (inherits(backbone, "taxify_backend")) backbone$name else backbone
  bb <- backbone_path(backbone, verbose = verbose)

  empty <- data.frame(
    input_name = character(0L), accepted_name = character(0L),
    rank = character(0L), name = character(0L), backbone = character(0L),
    stringsAsFactors = FALSE
  )

  # Resolve the query (handles synonyms / typos) to its accepted taxon.
  res <- taxify(taxon, backbone = backbone, fuzzy = TRUE, verbose = FALSE)
  if (nrow(res) == 0L || is.na(res$accepted_id[1L])) {
    if (verbose) message(sprintf("upstream(): '%s' did not resolve against '%s'.",
                                 taxon, bb_name))
    return(empty)
  }
  acc_id   <- res$accepted_id[1L]
  acc_name <- res$accepted_name[1L]
  own_rank <- tolower(res$rank[1L] %||% NA_character_)

  # Read the denormalized ancestor columns the backbone stores.
  schema <- tryCatch(
    names(vectra::collect(utils::head(vectra::tbl(bb), 1L))),
    error = function(e) character(0L))
  avail <- intersect(.upstream_cols, schema)
  if (length(avail) == 0L) {
    if (verbose) message(sprintf(
      "upstream(): backbone '%s' stores no classification columns.", bb_name))
    return(empty)
  }

  joined <- backbone_join(bb, acc_id, bb_key = "taxon_id",
                          select_cols = c("taxon_id", avail))
  if (is.null(joined) || nrow(joined) == 0L) return(empty)
  joined <- joined[!duplicated(joined$lookup), , drop = FALSE]
  row <- joined[match(acc_id, joined$lookup), , drop = FALSE]

  # Keep only the ranks strictly above the query's own rank. An unknown or
  # below-genus rank is treated as species-level, so all six are ancestors.
  own_idx <- unname(.upstream_rank_order[own_rank])
  if (length(own_idx) == 0L || is.na(own_idx)) own_idx <- 7L

  lineage <- lapply(avail, function(col) {
    if (unname(.upstream_rank_order[col]) >= own_idx) return(NULL)
    val <- row[[col]]
    if (is.na(val) || !nzchar(val)) return(NULL)
    data.frame(input_name = taxon, accepted_name = acc_name, rank = col,
               name = val, backbone = bb_name, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, lineage)
  if (is.null(out) || nrow(out) == 0L) return(empty)

  if (!is.null(to)) {
    to <- tolower(as.character(to))
    out <- out[out$rank %in% to, , drop = FALSE]
  }
  out <- out[order(match(out$rank, .upstream_cols)), , drop = FALSE]
  rownames(out) <- NULL
  out
}

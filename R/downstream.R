# ---- Downstream: all descendants of a taxon at a target rank ----
#
# children() lists the accepted taxa one level inside a genus or family.
# downstream() goes the whole way down: every accepted taxon at a chosen rank
# (species by default) beneath a higher taxon -- every species in an order, say.
# The backbones store classification denormalized (a species row carries its
# order/class/phylum/kingdom text where the backbone has them), so this is a
# single filter on the ancestor column, not a recursive parent-key walk.


#' Rank name -> the backbone column that stores it
#' @noRd
.rank_to_column <- c(
  KINGDOM = "kingdom", PHYLUM = "phylum", CLASS = "class",
  ORDER = "order", FAMILY = "family", GENUS = "genus"
)


#' Collect accepted rows whose ancestor column equals a value
#'
#' Uses an explicit bare-column filter per rank (the pattern [children()] uses),
#' so no dynamic NSE injection is needed. `col` is one of the six columns in
#' `.rank_to_column`; `value` is compared against it.
#'
#' @param bb Backbone `.vtr` path.
#' @param col Ancestor column name.
#' @param value The ancestor name to match.
#' @param sel_cols Columns to return.
#' @return Collected data.frame, or `NULL` on error / no such column path.
#' @noRd
collect_by_ancestor <- function(bb, col, value, sel_cols) {
  node <- vectra::tbl(bb)
  filtered <- switch(
    col,
    kingdom = vectra::filter(node, kingdom == value & is_synonym == FALSE),
    phylum  = vectra::filter(node, phylum  == value & is_synonym == FALSE),
    class   = vectra::filter(node, class   == value & is_synonym == FALSE),
    order   = vectra::filter(node, order   == value & is_synonym == FALSE),
    family  = vectra::filter(node, family  == value & is_synonym == FALSE),
    genus   = vectra::filter(node, genus   == value & is_synonym == FALSE),
    NULL
  )
  if (is.null(filtered)) return(NULL)
  tryCatch(
    filtered |>
      vectra::select(!!!lapply(sel_cols, as.name)) |>
      vectra::collect(),
    error = function(e) NULL)
}


#' List all descendants of a taxon down to a target rank
#'
#' Returns every accepted taxon at `downto` rank that sits beneath `taxon` --
#' for example every species in an order or family. The parent's rank is
#' detected from the backbone, then descendants are read from the denormalized
#' classification the backbone stores. Where [children()] gives the immediate
#' contents of a genus or family, `downstream()` reaches an arbitrary depth.
#'
#' @param taxon A single higher-taxon name (a genus, family, order, class,
#'   phylum, or kingdom).
#' @param backbone A single backbone name or a `taxify_backend` object. `NULL`
#'   (default) uses the highest-priority installed backbone; name one that
#'   stores the higher ranks (e.g. `"col"`) to reach above genus.
#' @param downto Target rank of the descendants to return (`"species"` by
#'   default), or `"any"` for every accepted taxon beneath `taxon` regardless of
#'   rank.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame of accepted descendants, columns: `name`, `authorship`,
#'   `rank`, `family`, `genus`, `taxon_id`, `parent`, `parent_rank`, `backbone`.
#'   Empty when `taxon` is not found, its rank is one the backbone does not store
#'   as a column (e.g. subfamily, tribe), or it has no descendants at `downto`.
#'
#' @seealso [children()] for the immediate level, [taxify()], [synonyms()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Every species the backbone places in the genus
#' downstream("Quercus", backbone = "col")
#'
#' options(old)
#'
#' @export
downstream <- function(taxon, backbone = NULL, downto = "species",
                       verbose = TRUE) {
  if (!is.character(taxon) || length(taxon) != 1L || is.na(taxon) ||
      !nzchar(trimws(taxon))) {
    stop("taxon must be a single non-empty name.", call. = FALSE)
  }
  backbone <- resolve_single_backend(backbone, verbose = verbose)
  bb_name <- if (inherits(backbone, "taxify_backend")) backbone$name else backbone
  bb <- backbone_path(backbone, verbose = verbose)
  taxon <- title_case_taxon(taxon)
  any_rank <- identical(downto, "any")
  downto_u <- toupper(downto)

  schema <- tryCatch(
    names(vectra::collect(utils::head(vectra::tbl(bb), 1L))),
    error = function(e) character(0L))

  empty <- data.frame(
    name = character(0L), authorship = character(0L), rank = character(0L),
    family = character(0L), genus = character(0L), taxon_id = character(0L),
    parent = character(0L), parent_rank = character(0L),
    backbone = character(0L), stringsAsFactors = FALSE
  )

  # 1. The taxon's own rank -> the column its descendants are filtered on.
  parent_rank <- NA_character_
  self <- tryCatch(
    vectra::tbl(bb) |>
      vectra::filter(canonical_name == taxon & is_synonym == FALSE) |>
      vectra::select(canonical_name, taxon_rank) |>
      vectra::collect(),
    error = function(e) NULL)
  if (!is.null(self) && nrow(self) > 0L) {
    rk <- toupper(self$taxon_rank[!is.na(self$taxon_rank)])
    if (length(rk) > 0L) parent_rank <- names(sort(table(rk), decreasing = TRUE))[1L]
  }

  anc_col <- if (!is.na(parent_rank)) unname(.rank_to_column[parent_rank]) else NA
  anc_col <- if (!is.na(anc_col) && anc_col %in% schema) anc_col else NA_character_

  # 2. Fallback probe: the taxon was not a stored node (or its rank has no
  #    column). Try each classification column present, finest first, and take
  #    the one that actually contains it as an ancestor.
  if (is.na(anc_col)) {
    for (col in intersect(c("genus", "family", "order", "class", "phylum",
                            "kingdom"), schema)) {
      n <- collect_by_ancestor(bb, col, taxon, "canonical_name")
      if (!is.null(n) && nrow(n) > 0L) {
        anc_col <- col
        if (is.na(parent_rank)) {
          parent_rank <- names(.rank_to_column)[match(col, .rank_to_column)]
        }
        break
      }
    }
  }
  if (is.na(anc_col)) {
    if (verbose) message(sprintf(
      "downstream(): '%s' not found beneath a rank stored by backbone '%s'.",
      taxon, bb_name))
    return(empty)
  }

  sel_cols <- intersect(
    c("canonical_name", "authorship", "taxon_rank", "family", "genus",
      "taxon_id"), schema)
  hits <- collect_by_ancestor(bb, anc_col, taxon, sel_cols)
  if (is.null(hits) || nrow(hits) == 0L) return(empty)

  # Drop the taxon itself; keep true descendants.
  hits <- hits[is.na(hits$canonical_name) | hits$canonical_name != taxon, ,
               drop = FALSE]
  if (!any_rank) {
    hits <- hits[!is.na(hits$taxon_rank) &
                   toupper(hits$taxon_rank) == downto_u, , drop = FALSE]
  }
  if (nrow(hits) == 0L) return(empty)

  col <- function(nm) if (nm %in% names(hits)) hits[[nm]] else
    rep(NA_character_, nrow(hits))
  out <- data.frame(
    name        = col("canonical_name"),
    authorship  = col("authorship"),
    rank        = col("taxon_rank"),
    family      = col("family"),
    genus       = col("genus"),
    taxon_id    = col("taxon_id"),
    parent      = taxon,
    parent_rank = tolower(parent_rank %||% NA_character_),
    backbone     = bb_name,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$name), , drop = FALSE]
  rownames(out) <- NULL
  out
}

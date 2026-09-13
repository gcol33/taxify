# ---- Downstream: all descendants of a taxon at a target rank ----
#
# children() lists the accepted taxa inside a genus or family. downstream() goes
# the whole way down: every accepted taxon at a chosen rank (species by default)
# beneath a higher taxon -- every species in an order, say. Both read through
# collect_descendants(), which differs between them only in which ranks the
# parent may hold. The backbones store classification denormalized (a species
# row carries its order/class/phylum/kingdom text where the backbone has them),
# so this is a single filter on the ancestor column, not a recursive parent-key
# walk.


#' Rank name -> the backbone column that stores it
#' @noRd
.rank_to_column <- c(
  KINGDOM = "kingdom", PHYLUM = "phylum", CLASS = "class",
  ORDER = "order", FAMILY = "family", GENUS = "genus"
)


#' Collect accepted rows whose ancestor column equals a value
#'
#' Uses an explicit bare-column filter per rank, so no dynamic NSE injection is
#' needed. `col` is one of the six columns in `.rank_to_column`; `value` is
#' compared against it.
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


#' Accepted descendants of a taxon: the engine behind children() and downstream()
#'
#' Detects the parent's rank from its own accepted row(s), restricted to the
#' ranks in `parent_cols`; when the parent is not a stored node, probes each of
#' those classification columns finest first. Rows are resolved to a coarse
#' kingdom group in the order the `kingdom =` filter of [taxify()] uses
#' (`row_kingdom_groups()`), so a homonymous parent is split by `kingdom`, and
#' a result that mixes kingdoms without it warns.
#'
#' @param taxon Single parent name.
#' @param backbone Backbone name, `taxify_backend`, or `NULL`.
#' @param target_rank Rank of the descendants, or `"any"` / `NULL` for every
#'   rank. The parent itself is never returned.
#' @param kingdom `NULL` or kingdom names, as in [taxify()].
#' @param parent_cols Classification columns the parent may be held in, finest
#'   first.
#' @param caller Name of the exported verb, for messages.
#' @param verbose Logical.
#' @return The descendant data.frame (see [downstream()]).
#' @noRd
collect_descendants <- function(taxon, backbone, target_rank, kingdom,
                                parent_cols, caller, verbose) {
  if (!is.character(taxon) || length(taxon) != 1L || is.na(taxon) ||
      !nzchar(trimws(taxon))) {
    stop("taxon must be a single non-empty name.", call. = FALSE)
  }
  kingdom_set <- resolve_kingdom_filter(kingdom)
  backbone <- resolve_single_backend(backbone, verbose = verbose)
  bb_name <- backbone_name_of(backbone)
  bb <- backbone_path(backbone, verbose = verbose)
  taxon <- title_case_taxon(taxon)
  any_rank <- is.null(target_rank) || identical(target_rank, "any")

  schema <- vtr_schema(bb)
  parent_cols <- intersect(parent_cols, schema)
  has_kingdom <- "kingdom" %in% schema
  has_genus <- "genus" %in% schema

  empty <- data.frame(
    name = character(0L), authorship = character(0L), rank = character(0L),
    kingdom_group = character(0L), family = character(0L),
    genus = character(0L), taxon_id = character(0L), parent = character(0L),
    parent_rank = character(0L), backbone = character(0L),
    stringsAsFactors = FALSE
  )

  # Coarse kingdom of each row, and whether the row is in the requested set. A
  # row whose kingdom is unknown is kept, as the taxify() filter keeps it.
  kingdom_of <- function(df) {
    row_kingdom_groups(bb_name,
                       kingdom = if (has_kingdom) df$kingdom else NULL,
                       genus = if (has_genus) df$genus else NULL,
                       n = nrow(df))
  }
  in_set <- function(kg) {
    if (is.null(kingdom_set)) rep(TRUE, length(kg)) else
      is.na(kg) | kg %in% kingdom_set
  }

  # 1. The parent's own rank -> the column its descendants are filtered on.
  parent_rank <- NA_character_
  self_cols <- c("canonical_name", "taxon_rank",
                 if (has_kingdom) "kingdom", if (has_genus) "genus")
  self <- tryCatch(
    vectra::tbl(bb) |>
      vectra::filter(canonical_name == taxon & is_synonym == FALSE) |>
      vectra::select(!!!lapply(self_cols, as.name)) |>
      vectra::collect(),
    error = function(e) NULL)
  if (!is.null(self) && nrow(self) > 0L) {
    self <- self[in_set(kingdom_of(self)), , drop = FALSE]
    rk <- toupper(self$taxon_rank[!is.na(self$taxon_rank)])
    rk <- rk[rk %in% names(.rank_to_column) &
               .rank_to_column[rk] %in% parent_cols]
    if (length(rk) > 0L) {
      parent_rank <- names(sort(table(rk), decreasing = TRUE))[1L]
    }
  }

  sel_cols <- intersect(
    c("canonical_name", "authorship", "taxon_rank", "kingdom", "family",
      "genus", "taxon_id"), schema)
  descendants <- function(col) {
    h <- collect_by_ancestor(bb, col, taxon, sel_cols)
    if (is.null(h) || nrow(h) == 0L) return(NULL)
    h$kingdom_group <- kingdom_of(h)
    h <- h[in_set(h$kingdom_group), , drop = FALSE]
    if (nrow(h) == 0L) NULL else h
  }

  anc_col <- if (!is.na(parent_rank)) unname(.rank_to_column[parent_rank]) else
    NA_character_
  hits <- if (!is.na(anc_col)) descendants(anc_col) else NULL

  # 2. Fallback probe: the parent is not a stored node (or not at an allowed
  #    rank). Take the finest allowed column that holds it as an ancestor.
  if (is.null(hits)) {
    for (col in setdiff(parent_cols, anc_col)) {
      hits <- descendants(col)
      if (!is.null(hits)) {
        anc_col <- col
        parent_rank <- names(.rank_to_column)[match(col, .rank_to_column)]
        break
      }
    }
  }
  if (is.null(hits)) {
    if (verbose) message(sprintf(
      "%s(): '%s' not found beneath a rank stored by backbone '%s'.",
      caller, taxon, bb_name))
    return(empty)
  }

  hits <- hits[is.na(hits$canonical_name) | hits$canonical_name != taxon, ,
               drop = FALSE]

  if (is.null(kingdom_set)) {
    kg <- sort(unique(hits$kingdom_group[!is.na(hits$kingdom_group)]))
    if (length(kg) > 1L) {
      warning(sprintf(paste0(
        "%s(): '%s' names taxa in more than one kingdom in backbone '%s' ",
        "(%s); the result mixes them. Pass `kingdom =` to choose one."),
        caller, taxon, bb_name, paste(kg, collapse = ", ")), call. = FALSE)
    }
  }

  if (!any_rank) {
    hits <- hits[!is.na(hits$taxon_rank) &
                   toupper(hits$taxon_rank) == toupper(target_rank), ,
                 drop = FALSE]
  }
  if (nrow(hits) == 0L) return(empty)

  col <- function(nm) if (nm %in% names(hits)) hits[[nm]] else
    rep(NA_character_, nrow(hits))
  out <- data.frame(
    name          = col("canonical_name"),
    authorship    = col("authorship"),
    rank          = col("taxon_rank"),
    kingdom_group = hits$kingdom_group,
    family        = col("family"),
    genus         = col("genus"),
    taxon_id      = col("taxon_id"),
    parent        = taxon,
    parent_rank   = tolower(parent_rank),
    backbone      = bb_name,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$name), , drop = FALSE]
  rownames(out) <- NULL
  out
}


#' List all descendants of a taxon down to a target rank
#'
#' Returns every accepted taxon at `downto` rank that sits beneath `taxon` --
#' for example every species in an order or family. The parent's rank is
#' detected from the backbone, then descendants are read from the denormalized
#' classification the backbone stores. [children()] is the same query for a
#' genus or family parent.
#'
#' @param taxon A single higher-taxon name (a genus, family, order, class,
#'   phylum, or kingdom).
#' @param backbone A single backbone name or a `taxify_backend` object. `NULL`
#'   (default) uses the highest-priority installed backbone; name one that
#'   stores the higher ranks (e.g. `"col"`) to reach above genus.
#' @param downto Target rank of the descendants to return (`"species"` by
#'   default), or `"any"` (or `NULL`) for every accepted taxon beneath `taxon`
#'   regardless of rank. The parent itself is never returned.
#' @param kingdom Optional kingdom (or kingdoms) the parent belongs to, as in
#'   [taxify()] (`"plantae"`, `"animals"`, ...). A name can be used in more than
#'   one kingdom (*Morus* is both mulberries and gannets); `kingdom` picks one,
#'   and also decides the parent's rank when the homonyms sit at different
#'   ranks. Without it such a result mixes the kingdoms, with a warning.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame of accepted descendants, columns: `name`, `authorship`,
#'   `rank`, `kingdom_group` (the coarse kingdom, as in [taxify()] output),
#'   `family`, `genus`, `taxon_id`, `parent`, `parent_rank`, `backbone`. Empty
#'   when `taxon` is not found, its rank is one the backbone does not store as a
#'   column (e.g. subfamily, tribe), or it has no descendants at `downto`.
#'
#' @seealso [children()] for a genus or family parent, [upstream()] for the
#'   ancestors, [taxify()], [synonyms()].
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
                       kingdom = NULL, verbose = TRUE) {
  collect_descendants(taxon, backbone = backbone, target_rank = downto,
                      kingdom = kingdom,
                      parent_cols = c("genus", "family", "order", "class",
                                      "phylum", "kingdom"),
                      caller = "downstream", verbose = verbose)
}

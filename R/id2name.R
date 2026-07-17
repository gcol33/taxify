# ---- Backend ID -> name ----
#
# taxify() returns backend IDs (taxon_id, accepted_id) alongside the names.
# id2name() is the reverse: given an ID from a backbone, return the name it
# belongs to, its rank and classification, and -- for a synonym ID -- the
# accepted name it resolves to. The round-trip for a dataset that stored GBIF
# keys / TSNs / AphiaIDs and now needs the current names back.


#' Resolve backend IDs to names
#'
#' Looks up one or more backend taxon IDs in a backbone and returns the name,
#' rank, classification, and accepted-name resolution for each. The inverse of
#' the `taxon_id` / `accepted_id` columns [taxify()] emits.
#'
#' @param id A vector of backend IDs (e.g. GBIF keys, ITIS TSNs, WoRMS
#'   AphiaIDs). Coerced to character, matched against the backbone's `taxon_id`.
#' @param backend A single backend name (e.g. `"col"`, `"gbif"`) or a
#'   `taxify_backend` object. Default `"col"`.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A data.frame with one row per input ID (in input order), columns:
#' \describe{
#'   \item{id}{The queried ID.}
#'   \item{name}{Canonical name for that ID (`NA` if the ID is not in the
#'     backbone).}
#'   \item{authorship}{Authorship of the name.}
#'   \item{rank}{Taxonomic rank.}
#'   \item{is_synonym}{Logical. Is this ID a synonym?}
#'   \item{accepted_name}{The accepted name the ID resolves to (equals `name`
#'     when the ID is itself accepted).}
#'   \item{family}{Family.}
#'   \item{genus}{Genus.}
#'   \item{backend}{Backend used.}
#' }
#' IDs not found in the backbone yield a row with `NA` name columns, so the
#' output stays aligned one-to-one with the input.
#'
#' @seealso [taxify()] for name -> ID, [synonyms()], [add_classification()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' # Round-trip: resolve a name, then look its ID back up
#' r <- taxify("Quercus robur", backend = "col")
#' id2name(r$taxon_id, backend = "col")
#'
#' options(old)
#'
#' @export
id2name <- function(id, backend = "col", verbose = TRUE) {
  if (length(id) == 0L) {
    stop("id must have at least one element.", call. = FALSE)
  }
  be_name <- if (inherits(backend, "taxify_backend")) backend$name else backend
  bb <- backbone_path(backend, verbose = verbose)

  ids <- as.character(id)

  base_cols <- c("taxon_id", "canonical_name", "authorship", "taxon_rank",
                 "family", "genus", "is_synonym", "accepted_taxon_id")
  schema <- tryCatch(
    names(vectra::collect(utils::head(vectra::tbl(bb), 1L))),
    error = function(e) character(0L))
  sel <- intersect(base_cols, schema)

  hit <- backbone_join(bb, ids, bb_key = "taxon_id", select_cols = sel)

  out <- data.frame(
    id            = ids,
    name          = NA_character_,
    authorship    = NA_character_,
    rank          = NA_character_,
    is_synonym    = NA,
    accepted_name = NA_character_,
    family        = NA_character_,
    genus         = NA_character_,
    backend       = be_name,
    stringsAsFactors = FALSE
  )

  if (is.null(hit) || nrow(hit) == 0L) return(out)
  hit <- hit[!duplicated(hit$lookup), , drop = FALSE]
  m   <- match(ids, hit$lookup)
  found <- which(!is.na(m))
  if (length(found) == 0L) return(out)

  hf <- m[found]
  get <- function(col) if (col %in% names(hit)) hit[[col]][hf] else NA
  out$name[found]       <- get("canonical_name")
  out$authorship[found] <- get("authorship")
  out$rank[found]       <- get("taxon_rank")
  out$family[found]     <- get("family")
  out$genus[found]      <- get("genus")
  syn <- get("is_synonym")
  out$is_synonym[found] <- if (length(syn) == 1L && all(is.na(syn))) NA else syn

  # Accepted-name resolution: an accepted ID is its own accepted name; a synonym
  # points at accepted_taxon_id, which we look up in a second pass.
  out$accepted_name[found] <- out$name[found]
  if ("accepted_taxon_id" %in% names(hit) && "canonical_name" %in% schema) {
    acc_id <- hit$accepted_taxon_id[hf]
    need <- which(!is.na(acc_id) & nzchar(acc_id))
    if (length(need) > 0L) {
      acc <- backbone_join(bb, acc_id[need], bb_key = "taxon_id",
                           select_cols = c("taxon_id", "canonical_name"))
      if (!is.null(acc) && nrow(acc) > 0L) {
        acc <- acc[!duplicated(acc$lookup), , drop = FALSE]
        ai  <- match(acc_id[need], acc$lookup)
        ok  <- which(!is.na(ai))
        if (length(ok) > 0L) {
          out$accepted_name[found[need[ok]]] <- acc$canonical_name[ai[ok]]
        }
      }
    }
  }
  out
}

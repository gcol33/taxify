# ---- Classification tree and lowest common ancestor ----
#
# Two verbs built on the higher classification: class2tree() turns a set of
# resolved names into a taxonomy tree (Newick, and an ape phylo when ape is
# installed), and lowest_common() reports the deepest rank at which a set of
# names shares a common ancestor. Both read the Linnaean ranks a taxify()
# result carries once add_classification() has filled the ranks above family.


#' Rank columns, finest to coarsest
#' @noRd
.tree_ranks <- c("species", "genus", "family", "order", "class", "phylum",
                 "kingdom")


#' Resolve names to a classification frame (species .. kingdom)
#'
#' Accepts either raw names (run through [taxify()]) or an existing `taxify()`
#' result, then fills the ranks above family with [add_classification()]. Keeps
#' only rows that resolved to an accepted name.
#'
#' @param x Character vector of names, or a `taxify()` result.
#' @param backend Backend passed to [taxify()] when `x` is raw names.
#' @param verbose Logical.
#' @return A data.frame with `input_name`, `species` (the accepted name), and
#'   `genus`/`family`/`order`/`class`/`phylum`/`kingdom`. Rows with no accepted
#'   name are dropped.
#' @noRd
resolve_classification_frame <- function(x, backend = NULL, verbose = TRUE) {
  res <- if (is.data.frame(x) && "accepted_name" %in% names(x)) {
    x
  } else if (is.character(x)) {
    taxify(x, backend = backend, verbose = verbose)
  } else {
    stop("x must be a character vector of names or a taxify() result.",
         call. = FALSE)
  }

  res <- add_classification(res, ranks = c("kingdom", "phylum", "class",
                                           "order"), verbose = FALSE)

  keep <- !is.na(res$accepted_name) & nzchar(res$accepted_name)
  res  <- res[keep, , drop = FALSE]

  col <- function(nm) if (nm %in% names(res)) as.character(res[[nm]]) else
    rep(NA_character_, nrow(res))
  data.frame(
    input_name = if ("input_name" %in% names(res)) res$input_name else col("accepted_name"),
    species    = col("accepted_name"),
    genus      = col("genus"),
    family     = col("family"),
    order      = col("order"),
    class      = col("class"),
    phylum     = col("phylum"),
    kingdom    = col("kingdom"),
    stringsAsFactors = FALSE
  )
}


#' Lowest common taxon of a set of names
#'
#' Resolves the names and reports the deepest Linnaean rank at which they all
#' share one classification value -- their most recent common ancestor in the
#' backbone's hierarchy. Two congeners return their shared genus; two plants in
#' different families return a shared order or class; unrelated taxa share only a
#' kingdom (or nothing).
#'
#' @param x Character vector of names (two or more), or a [taxify()] result.
#' @param backend Backend passed to [taxify()] when `x` is raw names. `NULL`
#'   (default) uses every installed backbone. Ignored when `x` is a result.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return A one-row data.frame with columns `rank`, `name` (the shared taxon),
#'   and `n_taxa` (how many resolved names went into the comparison). `rank` and
#'   `name` are `NA` when the taxa share nothing (e.g. different kingdoms, or
#'   only one resolved).
#'
#' @seealso [class2tree()], [add_classification()], [taxify()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' lowest_common(c("Quercus robur", "Quercus petraea"))
#'
#' options(old)
#'
#' @export
lowest_common <- function(x, backend = NULL, verbose = TRUE) {
  cf <- resolve_classification_frame(x, backend = backend, verbose = verbose)
  out <- data.frame(rank = NA_character_, name = NA_character_,
                    n_taxa = nrow(cf), stringsAsFactors = FALSE)
  if (nrow(cf) < 2L) {
    if (verbose && nrow(cf) < 2L) {
      message("lowest_common(): need >= 2 resolved names to compare.")
    }
    return(out)
  }
  # Finest rank first: the deepest rank where every taxon carries the same
  # non-NA value is the lowest common ancestor.
  for (r in .tree_ranks) {
    v <- cf[[r]]
    if (anyNA(v)) next
    u <- unique(v)
    if (length(u) == 1L) {
      out$rank <- r
      out$name <- u
      return(out)
    }
  }
  out
}


#' Newick subtree from a set of root-to-tip lineages
#'
#' @param paths List of character vectors, each a lineage from the current level
#'   down to a tip. Internal nodes are labelled by their rank value; tips are the
#'   species names (with Newick-unsafe characters replaced by `_`).
#' @return A Newick string for the subtree (no trailing `;`).
#' @noRd
newick_from_paths <- function(paths) {
  safe  <- function(s) gsub("[ (),;:'\"]", "_", s)
  heads <- vapply(paths, function(p) p[[1L]], character(1L))
  parts <- character(0L)
  for (h in unique(heads)) {
    grp   <- paths[heads == h]
    rests <- lapply(grp, function(p) p[-1L])
    rests <- rests[vapply(rests, length, integer(1L)) > 0L]
    lab   <- safe(h)
    if (length(rests) == 0L) {
      parts <- c(parts, lab)                                   # leaf
    } else {
      parts <- c(parts, paste0(newick_from_paths(rests), lab)) # internal node
    }
  }
  paste0("(", paste(parts, collapse = ","), ")")
}


#' Build a taxonomy tree from resolved names
#'
#' Resolves the names, attaches their full higher classification, and assembles a
#' taxonomy tree (kingdom -> phylum -> class -> order -> family -> genus ->
#' species) from the shared lineages. Returns the tree as a Newick string and the
#' underlying classification table; when the \pkg{ape} package is installed, an
#' `ape` `phylo` object is included too.
#'
#' @param x Character vector of names, or a [taxify()] result.
#' @param backend Backend passed to [taxify()] when `x` is raw names. `NULL`
#'   (default) uses every installed backbone. Ignored when `x` is a result.
#' @param verbose Logical. Default `TRUE`.
#'
#' @return An object of class `taxify_tree`: a list with
#' \describe{
#'   \item{newick}{The Newick string (internal nodes labelled by rank value,
#'     tips by species name).}
#'   \item{classification}{The classification data.frame the tree was built
#'     from.}
#'   \item{tip_labels}{The species at the tips.}
#'   \item{phylo}{An \pkg{ape} `phylo` object, or `NULL` if \pkg{ape} is not
#'     installed / the string could not be parsed.}
#' }
#'
#' @seealso [lowest_common()], [add_classification()], [taxify()].
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' tr <- class2tree(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica"))
#' tr$newick
#'
#' options(old)
#'
#' @export
class2tree <- function(x, backend = NULL, verbose = TRUE) {
  cf <- resolve_classification_frame(x, backend = backend, verbose = verbose)
  if (nrow(cf) == 0L) {
    stop("class2tree(): no names resolved to an accepted taxon.", call. = FALSE)
  }

  # One lineage per tip, coarsest -> finest, dropping missing ranks so the path
  # stays contiguous. Duplicate lineages (same species twice) collapse.
  lin_ranks <- rev(.tree_ranks)            # kingdom .. species
  paths <- lapply(seq_len(nrow(cf)), function(i) {
    v <- vapply(lin_ranks, function(r) cf[[r]][i], character(1L))
    v <- v[!is.na(v) & nzchar(v)]
    unname(v)
  })
  paths <- paths[vapply(paths, length, integer(1L)) > 0L]
  paths <- paths[!duplicated(vapply(paths, paste, character(1L),
                                    collapse = "\r"))]
  if (length(paths) == 0L) {
    stop("class2tree(): resolved names carry no classification to build a tree.",
         call. = FALSE)
  }

  newick <- paste0(newick_from_paths(paths), "root;")

  phylo <- NULL
  if (requireNamespace("ape", quietly = TRUE)) {
    phylo <- tryCatch(ape::read.tree(text = newick), error = function(e) NULL)
  }

  structure(
    list(
      newick         = newick,
      classification = cf,
      tip_labels     = cf$species,
      phylo          = phylo
    ),
    class = "taxify_tree"
  )
}


#' @export
print.taxify_tree <- function(x, ...) {
  n_tip <- length(x$tip_labels)
  cat(sprintf("<taxify_tree> %d tip%s\n", n_tip, if (n_tip == 1L) "" else "s"))
  show <- utils::head(x$tip_labels, 6L)
  cat("  tips: ", paste(show, collapse = ", "),
      if (n_tip > length(show)) sprintf(", ... (+%d)", n_tip - length(show))
      else "", "\n", sep = "")
  nw <- x$newick
  if (nchar(nw) > 200L) nw <- paste0(substr(nw, 1L, 197L), "...")
  cat("  newick: ", nw, "\n", sep = "")
  if (is.null(x$phylo)) {
    cat("  (install 'ape' for an as.phylo object in $phylo)\n")
  } else {
    cat("  phylo:  ape object in $phylo\n")
  }
  invisible(x)
}

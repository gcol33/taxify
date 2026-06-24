# On-demand enrichment backed by the TR8 package.
#
# taxify does not ship a pre-built .vtr for Pignatti: its values are from a
# copyrighted publication and cannot be redistributed. They are read from the
# copy bundled in TR8 (which TR8 redistributes under its GPL with attribution;
# taxify ships none of it) and joined into a taxify() result on the user's own
# machine. If the source is unreachable the call errors rather than attaching
# silent NA. taxify itself redistributes nothing.
#
# (Ecoflora and BiolFlor were previously fetched live here too. Both are now
# bundled .vtr enrichments -- see add_ecoflora() and add_floraweb() -- built by
# taxifydb from frozen scrape snapshots, so they work offline.)


#' Join a TR8-backed trait source on demand (no redistribution)
#'
#' @param x A taxify() result.
#' @param db Character. TR8 database name (currently "Pignatti").
#' @param col_map Named character vector: output column -> TR8 short_code.
#' @param source_label,license Character. Provenance recorded on the result.
#' @param na_types Named list of NA prototypes per output column (controls
#'   the output column type). Defaults to character.
#' @param verbose Logical.
#' @return `x` with the trait columns added (NA where the source has no data
#'   or could not be reached).
#' @noRd
enrich_via_tr8 <- function(x, db, col_map, source_label, license,
                           na_types = NULL, verbose = TRUE) {
  if (!requireNamespace("TR8", quietly = TRUE)) {
    stop(sprintf(paste0(
      "Package 'TR8' is required for add_%s(): it fetches %s data on demand ",
      "(taxify does not redistribute this source). ",
      "Install with: install.packages('TR8')"),
      tolower(db), db), call. = FALSE)
  }
  if (!"accepted_name" %in% names(x)) {
    stop("Input must be a taxify() result with an 'accepted_name' column.",
         call. = FALSE)
  }

  # TR8::tr8() loads its internal datasets via data(column_list) with no
  # package= argument, which only resolves when TR8 is on the search path.
  # Attach it for the duration of this call if the user has not already.
  if (!"package:TR8" %in% search()) {
    attached <- tryCatch({ suppressMessages(attachNamespace("TR8")); TRUE },
                         error = function(e) FALSE)
    if (isTRUE(attached)) {
      on.exit(try(detach("package:TR8"), silent = TRUE), add = TRUE)
    }
  }

  na_for <- function(out_col) {
    if (!is.null(na_types) && out_col %in% names(na_types)) {
      na_types[[out_col]]
    } else {
      NA_character_
    }
  }
  for (out_col in names(col_map)) x[[out_col]] <- na_for(out_col)

  sp <- unique(x$accepted_name[!is.na(x$accepted_name)])
  if (length(sp) == 0L) {
    return(register_enrichment(x, tolower(db), source_label, NA_character_,
                               0L, license))
  }
  if (verbose) {
    message(sprintf("Fetching %s traits via TR8 for %d species...",
                    db, length(sp)))
  }

  traits <- tryCatch({
    obj <- TR8::tr8(sp, download_list = unname(col_map),
                    allow_persistent = FALSE, gui_config = FALSE)
    TR8::extract_traits(obj)
  }, error = function(e) {
    stop(sprintf(
      "add_%s(): could not reach the %s data source (%s). It is fetched live via TR8; the server may be offline. Try again later.",
      tolower(db), db, conditionMessage(e)), call. = FALSE)
  })
  if (is.null(traits) || nrow(traits) == 0L) {
    stop(sprintf(
      "add_%s(): the %s data source returned nothing. It is fetched live via TR8; the server may be offline. Try again later.",
      tolower(db), db), call. = FALSE)
  }

  idx <- match(x$accepted_name, rownames(traits))
  matched <- which(!is.na(idx))
  for (out_col in names(col_map)) {
    src <- col_map[[out_col]]
    if (!src %in% names(traits)) next
    vals <- as.character(traits[[src]][idx[matched]])
    vals[vals %in% c("", "NA", "na", "NaN")] <- NA_character_
    proto <- na_for(out_col)
    x[[out_col]][matched] <- if (is.integer(proto)) {
      suppressWarnings(as.integer(vals))
    } else if (is.numeric(proto)) {
      suppressWarnings(as.numeric(vals))
    } else {
      vals
    }
  }

  n_enriched <- sum(rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L)
  if (n_enriched == 0L) {
    # A reachable source returns data for at least some real species; zero hits
    # across every queried species means the live source returned only empty
    # rows -- almost always the server being down (TR8 swallows the failed
    # fetch and hands back NA). Fail loudly rather than attach silent NA.
    stop(sprintf(
      "add_%s(): no values returned for any of the %d queried species. The %s source is fetched live via TR8 and appears to be offline (or none of these names are present there).",
      tolower(db), length(sp), db), call. = FALSE)
  }
  register_enrichment(x, tolower(db), source_label, NA_character_, n_enriched,
                      license)
}


#' Add Italian plant traits from Pignatti (on demand, via TR8)
#'
#' Fetches Italian Ellenberg-type indicator values, life form, and chorotype
#' from Pignatti's Flora d'Italia (Pignatti, Menegoni & Pietrosanti 2005) for
#' the species in a [taxify()] result, using the TR8 package, and joins them by
#' `accepted_name`. TR8 ships these values bundled, so this works offline.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{light_it, temperature_it, continentality_it, moisture_it,
#'     reaction_it, nutrients_it, salinity_it}{Ellenberg-type indicator values
#'     calibrated for the Italian flora (codes; `X` = indifferent, `0` = not
#'     applicable).}
#'   \item{life_form_it}{Life form for the Italian flora.}
#'   \item{chorotype_it}{Chorological type (distribution).}
#' }
#'
#' @details
#' These values originate in a copyrighted publication, so taxify does not
#' redistribute them. This function reads the copy bundled in the suggested
#' package TR8 (which redistributes it under TR8's GPL, with attribution);
#' taxify ships none of it and no internet access is required. For
#' European-calibration indicator values see [add_eive()].
#'
#' @references
#' Pignatti S, Menegoni P, Pietrosanti S (2005) Bioindicazione attraverso le
#' piante vascolari. Braun-Blanquetia 39. Bocci G (2015) TR8: an R package for
#' easily retrieving plant species traits. Methods in Ecology and Evolution
#' 6:347-350.
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' \donttest{
#' # add_pignatti() fetches Italian trait data on demand via the TR8 package.
#' taxify("Abies alba") |>
#'   add_pignatti()
#' }
#'
#' options(old)
#'
#' @export
add_pignatti <- function(x, verbose = TRUE) {
  enrich_via_tr8(
    x, db = "Pignatti",
    col_map = c(
      light_it          = "ell_L_it",
      temperature_it    = "ell_T_it",
      continentality_it = "ell_C_it",
      moisture_it       = "ell_U_it",
      reaction_it       = "ell_R_it",
      nutrients_it      = "ell_N_it",
      salinity_it       = "ell_S_it",
      life_form_it      = "life_form_P",
      chorotype_it      = "distribution_p"
    ),
    source_label = "Pignatti Flora d'Italia (Pignatti et al. 2005)",
    license  = "copyrighted (not redistributed)",
    verbose  = verbose
  )
}

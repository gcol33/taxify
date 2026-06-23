# On-demand enrichments backed by the TR8 package.
#
# taxify does not ship a pre-built .vtr for these three, for two different
# reasons:
#   * BiolFlor (permission-gated, no open license) and Pignatti (from a
#     copyrighted publication) cannot be redistributed at all.
#   * Ecoflora's licence (CC BY-NC-SA 4.0) WOULD permit a redistributed .vtr,
#     but ecoflora.org.uk offers no bulk download -- data is only reachable one
#     species at a time -- so per-species fetch is the natural access mode and
#     a wholesale site scrape is avoided.
# Each source is therefore accessed on the user's own machine through TR8
# (Bocci 2015): BiolFlor and Ecoflora by live per-species query, Pignatti by
# reading the copy bundled in TR8 (which TR8 redistributes under its GPL with
# attribution; taxify ships none of it). The result is joined into a taxify()
# result. taxify itself redistributes nothing.


#' Join a TR8-backed trait source on demand (no redistribution)
#'
#' @param x A taxify() result.
#' @param db Character. TR8 database name ("Ecoflora", "BiolFlor", "Pignatti").
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
    warning(sprintf(
      "Could not fetch %s via TR8 (%s). Returning input with NA columns.",
      db, conditionMessage(e)), call. = FALSE)
    NULL
  })
  if (is.null(traits) || nrow(traits) == 0L) {
    return(register_enrichment(x, tolower(db), source_label, NA_character_,
                               0L, license))
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
  register_enrichment(x, tolower(db), source_label, NA_character_, n_enriched,
                      license)
}


#' Add British plant traits from Ecoflora (on demand, via TR8)
#'
#' Fetches traits from the Ecological Flora of the British Isles (Fitter & Peat
#' 1994) for the species in a [taxify()] result, using the TR8 package, and
#' joins them by `accepted_name`. Complements [add_baseflor()] (French flora)
#' with British flowering phenology and life form.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{flower_begin_month_uk}{Earliest flowering month (1-12).}
#'   \item{flower_end_month_uk}{Latest flowering month (1-12).}
#'   \item{pollination_vector_uk}{Pollen vector (e.g. insect, wind, self).}
#'   \item{life_form_uk}{Raunkiaer life form.}
#'   \item{leaf_longevity_uk}{Leaf longevity (e.g. evergreen, deciduous).}
#' }
#'
#' @details
#' Ecoflora's licence (CC BY-NC-SA 4.0) would permit a redistributed dataset,
#' but ecoflora.org.uk offers no bulk download: data is only reachable one
#' species at a time. This function therefore fetches it live, per species,
#' from ecoflora.org.uk through TR8 on your machine; it needs internet access
#' and the suggested package TR8 (`install.packages("TR8")`). taxify
#' redistributes nothing.
#'
#' @references
#' Fitter AH, Peat HJ (1994) The Ecological Flora Database. Journal of Ecology
#' 82:415-425. Bocci G (2015) TR8: an R package for easily retrieving plant
#' species traits. Methods in Ecology and Evolution 6:347-350.
#'
#' @examples
#' \dontrun{
#' taxify("Bellis perennis") |>
#'   add_ecoflora()
#' }
#'
#' @export
add_ecoflora <- function(x, verbose = TRUE) {
  enrich_via_tr8(
    x, db = "Ecoflora",
    col_map = c(
      flower_begin_month_uk = "flw_early",
      flower_end_month_uk   = "flw_late",
      pollination_vector_uk = "poll_vect",
      life_form_uk          = "li_form",
      leaf_longevity_uk     = "le_long"
    ),
    source_label = "Ecoflora (Ecological Flora of the British Isles)",
    license  = "CC BY-NC-SA 4.0",
    na_types = list(flower_begin_month_uk = NA_integer_,
                    flower_end_month_uk   = NA_integer_),
    verbose  = verbose
  )
}


#' Add German plant traits from BiolFlor (on demand, via TR8)
#'
#' Fetches biological-ecological traits from BiolFlor (Klotz, Kuehn & Durka
#' 2002) for the species in a [taxify()] result, using the TR8 package, and
#' joins them by `accepted_name`. BiolFlor supplies traits not found in the
#' bundled enrichments, notably Grime CSR strategy type, breeding system, and
#' apomixis.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{strategy_type_de}{Grime CSR strategy type.}
#'   \item{breeding_system_de}{Breeding system.}
#'   \item{pollination_vector_de}{Pollen vector.}
#'   \item{life_form_de}{Life form.}
#'   \item{life_span_de}{Life span.}
#'   \item{apomixis_de}{Type of apomixis.}
#' }
#'
#' @details
#' BiolFlor is permission-gated with no open redistribution license, so taxify
#' does not redistribute it. This function fetches data live from the UFZ
#' BiolFlor server through TR8 on your machine; it needs internet access and
#' the suggested package TR8 (`install.packages("TR8")`). The BiolFlor service
#' is occasionally offline, in which case the columns are returned as NA.
#'
#' @references
#' Klotz S, Kuehn I, Durka W (2002) BIOLFLOR. Schriftenreihe fuer
#' Vegetationskunde 38. Bocci G (2015) TR8: an R package for easily retrieving
#' plant species traits. Methods in Ecology and Evolution 6:347-350.
#'
#' @examples
#' \dontrun{
#' taxify("Bellis perennis") |>
#'   add_biolflor()
#' }
#'
#' @export
add_biolflor <- function(x, verbose = TRUE) {
  enrich_via_tr8(
    x, db = "BiolFlor",
    col_map = c(
      strategy_type_de      = "strategy",
      breeding_system_de    = "Breeding_sys",
      pollination_vector_de = "poll_vect_B",
      life_form_de          = "li_form_B",
      life_span_de          = "li_span",
      apomixis_de           = "apomixis"
    ),
    source_label = "BiolFlor (Klotz, Kuehn & Durka 2002)",
    license  = "permission-gated (not redistributed)",
    verbose  = verbose
  )
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
#' \dontrun{
#' taxify("Abies alba") |>
#'   add_pignatti()
#' }
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

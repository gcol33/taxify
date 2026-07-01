# On-demand enrichment backed by the GIFT package.
#
# taxify does not ship a pre-built .vtr for GIFT. GIFT aggregates trait values
# from many source references, each with its own licence, and is served from a
# live API rather than a single openly-licensed dump, so its values are not
# redistributable as a bundled database. Instead they are fetched live via the
# GIFT package on the user's own machine and joined into a taxify() result by
# accepted name. If the source is unreachable the call errors rather than
# attaching silent NA. taxify itself redistributes nothing.
#
# GIFT_traits() returns the full species-level trait table for the requested
# traits (one row per GIFT-standardised species), so a single fetch serves any
# query. The fetched table is cached per session in .taxify_env.


# Curated set of well-populated, broadly useful GIFT species-level traits.
# Each entry maps an output column to a GIFT trait ID (Lvl3) and a type that
# controls the output column class ("num" or "chr").
.gift_trait_catalog <- list(
  gift_woodiness              = list(id = "1.1.1", type = "chr"),
  gift_growth_form            = list(id = "1.2.1", type = "chr"),
  gift_lifecycle              = list(id = "2.1.1", type = "chr"),
  gift_life_form              = list(id = "2.3.1", type = "chr"),
  gift_climber                = list(id = "1.4.1", type = "chr"),
  gift_epiphyte               = list(id = "1.3.1", type = "chr"),
  gift_parasite               = list(id = "1.5.1", type = "chr"),
  gift_aquatic                = list(id = "1.7.1", type = "chr"),
  gift_plant_height_max       = list(id = "1.6.2", type = "num"),
  gift_photosynthetic_pathway = list(id = "4.2.1", type = "chr"),
  gift_seed_mass_mean         = list(id = "3.2.3", type = "num"),
  gift_dispersal_syndrome     = list(id = "3.3.1", type = "chr"),
  gift_flowering_start        = list(id = "3.7.1", type = "chr"),
  gift_flowering_end          = list(id = "3.7.2", type = "chr"),
  gift_deciduousness          = list(id = "2.4.1", type = "chr"),
  gift_sla_mean               = list(id = "4.1.3", type = "num")
)


# Fetch the curated GIFT trait table, cached for the session.
.gift_fetch <- function(trait_ids, agreement, verbose) {
  key <- paste0("gift_", paste(sort(trait_ids), collapse = "_"),
                "_a", agreement)
  cached <- .taxify_env[[key]]
  if (!is.null(cached)) return(cached)

  if (verbose) {
    message("Fetching GIFT trait table via the GIFT package ",
            "(one download per session)...")
  }
  traits <- tryCatch(
    GIFT::GIFT_traits(trait_IDs = trait_ids, agreement = agreement,
                      bias_ref = FALSE, bias_deriv = FALSE),
    error = function(e) {
      stop(sprintf(paste0(
        "add_gift(): could not reach the GIFT API (%s). Trait values are ",
        "fetched live via the GIFT package; the server may be offline. ",
        "Try again later."), conditionMessage(e)), call. = FALSE)
    }
  )
  if (is.null(traits) || nrow(traits) == 0L ||
      !"work_species" %in% names(traits)) {
    stop("add_gift(): the GIFT API returned no usable trait table. ",
         "It is fetched live via the GIFT package; the server may be offline.",
         call. = FALSE)
  }
  .taxify_env[[key]] <- traits
  traits
}


#' Add global plant traits from GIFT (on demand, via the GIFT package)
#'
#' Fetches species-level trait values from the Global Inventory of Floras and
#' Traits (GIFT) for the species in a [taxify()] result, using the GIFT
#' package, and joins them by `accepted_name`. GIFT aggregates published trait
#' records to one value per species (mean for numeric traits, most frequent
#' entry for categorical ones). This layer carries a curated set of the
#' best-populated traits.
#'
#' @param x A data.frame returned by [taxify()].
#' @param agreement Numeric in `[0, 1]`. Minimum agreement among source records
#'   for a categorical trait value to be reported. Passed to
#'   `GIFT::GIFT_traits()`. Default `0.66`.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{gift_woodiness}{Woody, non-woody, or variable.}
#'   \item{gift_growth_form}{Growth form (herb, shrub, tree, other).}
#'   \item{gift_lifecycle}{Life cycle (annual, biennial, perennial, variable).}
#'   \item{gift_life_form}{Raunkiaer life form.}
#'   \item{gift_climber}{Climbing habit.}
#'   \item{gift_epiphyte}{Epiphytic habit.}
#'   \item{gift_parasite}{Parasitic habit.}
#'   \item{gift_aquatic}{Aquatic habit.}
#'   \item{gift_plant_height_max}{Maximum plant height (m).}
#'   \item{gift_photosynthetic_pathway}{Photosynthetic pathway (C3, C4, CAM).}
#'   \item{gift_seed_mass_mean}{Mean seed mass (g).}
#'   \item{gift_dispersal_syndrome}{Primary dispersal syndrome.}
#'   \item{gift_flowering_start}{Month flowering starts.}
#'   \item{gift_flowering_end}{Month flowering ends.}
#'   \item{gift_deciduousness}{Deciduous, evergreen, or variable.}
#'   \item{gift_sla_mean}{Mean specific leaf area (cm2/g).}
#' }
#'
#' @details
#' GIFT trait values are aggregated from many source references, each with its
#' own licence, and are served from a live API, so taxify does not redistribute
#' them. This function fetches them on demand via the suggested package GIFT;
#' the full trait table is downloaded once per session and cached. You are
#' responsible for citing GIFT and the underlying references (see
#' `GIFT::GIFT_references()`) when you use the values. The first call requires
#' internet access.
#'
#' @references
#' Weigelt P, Konig C, Kreft H (2020) GIFT - A Global Inventory of Floras and
#' Traits for macroecology and biogeography. Journal of Biogeography
#' 47:16-43. \doi{10.1111/jbi.13623}
#' Denelle P, Weigelt P, Kreft H (2023) GIFT: an R package to access the Global
#' Inventory of Floras and Traits. Methods in Ecology and Evolution
#' 14:2738-2748. \doi{10.1111/2041-210X.14213}
#'
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' \donttest{
#' # add_gift() fetches global trait data on demand via the GIFT package.
#' taxify("Abies alba") |>
#'   add_gift()
#' }
#'
#' options(old)
#'
#' @export
add_gift <- function(x, agreement = 0.66, verbose = TRUE) {
  if (!requireNamespace("GIFT", quietly = TRUE)) {
    stop(paste0(
      "Package 'GIFT' is required for add_gift(): it fetches GIFT trait data ",
      "on demand (taxify does not redistribute this source). ",
      "Install with: install.packages('GIFT')"), call. = FALSE)
  }
  if (!"accepted_name" %in% names(x)) {
    stop("Input must be a taxify() result with an 'accepted_name' column.",
         call. = FALSE)
  }

  catalog   <- .gift_trait_catalog
  out_cols  <- names(catalog)
  trait_ids <- vapply(catalog, function(e) e$id, character(1))

  na_for <- function(out_col) {
    if (identical(catalog[[out_col]]$type, "num")) NA_real_ else NA_character_
  }
  for (out_col in out_cols) x[[out_col]] <- na_for(out_col)

  sp <- unique(x$accepted_name[!is.na(x$accepted_name)])
  if (length(sp) == 0L) {
    return(register_enrichment(
      x, "gift", "GIFT (Weigelt et al. 2020)", NA_character_, 0L,
      "per-reference (not redistributed)"))
  }

  traits <- .gift_fetch(trait_ids, agreement, verbose)

  idx     <- match(x$accepted_name, traits$work_species)
  matched <- which(!is.na(idx))
  for (out_col in out_cols) {
    src <- paste0("trait_value_", catalog[[out_col]]$id)
    if (!src %in% names(traits)) next
    vals <- traits[[src]][idx[matched]]
    if (identical(catalog[[out_col]]$type, "num")) {
      x[[out_col]][matched] <- suppressWarnings(as.numeric(vals))
    } else {
      vals <- as.character(vals)
      vals[vals %in% c("", "NA", "NaN")] <- NA_character_
      x[[out_col]][matched] <- vals
    }
  }

  n_enriched <- sum(rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L)
  register_enrichment(
    x, "gift", "GIFT (Weigelt et al. 2020)", NA_character_, n_enriched,
    "per-reference (not redistributed)")
}

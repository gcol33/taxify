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
# query. The fetched table and the trait catalogue are cached per session in
# .taxify_env.


# A convenience default: well-populated, broadly useful traits spanning growth
# form, life history, size, reproduction, and leaf economics. Not a ceiling --
# pass traits = "all" for every GIFT trait, or any trait IDs / names. Browse the
# full catalogue with gift_traits().
.gift_default_ids <- c(
  "1.1.1",  # woodiness
  "1.2.1",  # growth form
  "2.1.1",  # life cycle
  "2.3.1",  # life form (Raunkiaer)
  "1.4.1",  # climber
  "1.3.1",  # epiphyte
  "1.5.1",  # parasite
  "1.7.1",  # aquatic
  "1.6.2",  # plant height max
  "4.2.1",  # photosynthetic pathway
  "3.2.3",  # seed mass mean
  "3.3.1",  # dispersal syndrome
  "3.7.1",  # flowering start
  "3.7.2",  # flowering end
  "2.4.1",  # deciduousness
  "4.1.3"   # SLA mean
)


# Turn a GIFT trait label (e.g. "Plant_height_max") into an output column name
# (e.g. "gift_plant_height_max").
.gift_colname <- function(trait_label) {
  x <- tolower(trait_label)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  paste0("gift_", x)
}


# The GIFT trait catalogue as a data.frame, cached for the session. One row per
# trait, with the GIFT trait ID, the taxify output column name, category, value
# type, units, and how many species carry the trait.
.gift_catalog <- function(verbose = TRUE) {
  cached <- .taxify_env[["gift_catalog"]]
  if (!is.null(cached)) return(cached)

  meta <- tryCatch(
    GIFT::GIFT_traits_meta(),
    error = function(e) {
      stop(sprintf(paste0(
        "add_gift()/gift_traits(): could not reach the GIFT API (%s). The ",
        "trait catalogue is fetched live via the GIFT package; the server ",
        "may be offline. Try again later."), conditionMessage(e)),
        call. = FALSE)
    }
  )
  if (is.null(meta) || nrow(meta) == 0L || !"Lvl3" %in% names(meta)) {
    stop("add_gift()/gift_traits(): the GIFT API returned no usable trait ",
         "catalogue. It is fetched live via the GIFT package; the server may ",
         "be offline.", call. = FALSE)
  }

  cat <- data.frame(
    trait_id  = as.character(meta$Lvl3),
    column    = .gift_colname(meta$Trait2),
    category  = as.character(meta$Category),
    type      = as.character(meta$type),
    units     = as.character(meta$Units),
    n_species = suppressWarnings(as.integer(meta$count)),
    stringsAsFactors = FALSE
  )
  cat <- cat[!is.na(cat$trait_id) & nzchar(cat$trait_id), , drop = FALSE]
  cat$column <- make.unique(cat$column, sep = "_")
  cat <- cat[order(-cat$n_species), , drop = FALSE]
  rownames(cat) <- NULL

  .taxify_env[["gift_catalog"]] <- cat
  cat
}


# Resolve the user's `traits` argument to a set of catalogue rows. Accepts
# "all", NULL (the default set), or a vector of trait IDs and/or column names
# (with or without the gift_ prefix; case-insensitive on names).
.gift_resolve_traits <- function(traits, catalog) {
  if (is.null(traits)) {
    return(catalog[catalog$trait_id %in% .gift_default_ids, , drop = FALSE])
  }
  if (length(traits) == 1L && identical(tolower(traits), "all")) {
    return(catalog)
  }

  want    <- as.character(traits)
  by_id   <- match(want, catalog$trait_id)
  norm    <- tolower(ifelse(grepl("^gift_", want), want, paste0("gift_", want)))
  by_name <- match(norm, tolower(catalog$column))
  idx     <- ifelse(is.na(by_id), by_name, by_id)

  if (anyNA(idx)) {
    bad <- want[is.na(idx)]
    stop(sprintf(paste0(
      "add_gift(): unknown trait(s): %s. Pass GIFT trait IDs (e.g. \"1.6.2\") ",
      "or column names (e.g. \"plant_height_max\"), \"all\", or NULL for the ",
      "default set. See gift_traits() for the full catalogue."),
      paste(bad, collapse = ", ")), call. = FALSE)
  }
  catalog[idx, , drop = FALSE]
}


# Fetch the requested GIFT trait table, cached per (trait set, agreement).
.gift_fetch <- function(trait_ids, agreement, verbose) {
  key <- paste0("gift_traits_", paste(sort(trait_ids), collapse = "_"),
                "_a", agreement)
  cached <- .taxify_env[[key]]
  if (!is.null(cached)) return(cached)

  if (verbose) {
    message(sprintf(paste0(
      "Fetching GIFT trait table for %d trait(s) via the GIFT package ",
      "(one download per trait set per session)..."), length(trait_ids)))
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


#' Browse the GIFT trait catalogue
#'
#' Returns the full catalogue of species-level traits available from GIFT, the
#' Global Inventory of Floras and Traits (Weigelt et al. 2020), so you can pick
#' which to request in [add_gift()]. The catalogue is fetched live via the
#' suggested GIFT package (once per session) and needs internet access on the
#' first call.
#'
#' @return A data.frame, one row per trait, ordered by coverage, with columns:
#' \describe{
#'   \item{trait_id}{GIFT trait ID (pass to [add_gift()] via `traits`).}
#'   \item{column}{The output column name [add_gift()] would create.}
#'   \item{category}{GIFT trait category.}
#'   \item{type}{Value type (`numeric`, `categorical`, or `text`).}
#'   \item{units}{Units or the categorical value set.}
#'   \item{n_species}{Number of species GIFT has this trait for.}
#' }
#'
#' @seealso [add_gift()]
#' @examples
#' \donttest{
#' # Fetches the catalogue live via the GIFT package.
#' head(gift_traits(), 20)
#' }
#' @export
gift_traits <- function() {
  if (!requireNamespace("GIFT", quietly = TRUE)) {
    stop(paste0(
      "Package 'GIFT' is required for gift_traits(): it fetches the GIFT trait ",
      "catalogue on demand. Install with: install.packages('GIFT')"),
      call. = FALSE)
  }
  .gift_catalog()
}


#' Add plant traits from GIFT (on demand, via the GIFT package)
#'
#' Fetches species-level trait values from GIFT, the Global Inventory of Floras
#' and Traits (Weigelt et al. 2020), for the species in a [taxify()] result and
#' joins them by `accepted_name`. GIFT aggregates published trait records to one
#' value per species (mean for numeric traits, most frequent entry for
#' categorical ones). You choose which of GIFT's traits to attach; browse the
#' full catalogue with [gift_traits()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param traits Which GIFT traits to attach. One of: `NULL` (the default) for a
#'   convenient set of well-populated, broadly useful traits; the string
#'   `"all"` for every trait in the catalogue; or a character vector of GIFT
#'   trait IDs (e.g. `"1.6.2"`) and/or column names (e.g. `"plant_height_max"`,
#'   with or without the `gift_` prefix). See [gift_traits()].
#' @param agreement Numeric in `[0, 1]`. Minimum agreement among source records
#'   for a categorical trait value to be reported. Passed to
#'   `GIFT::GIFT_traits()`. Default `0.66`.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with one added column per requested trait, named
#'   `gift_<trait>`. Numeric traits (heights, masses, areas) are returned as
#'   doubles, categorical and text traits as character. Rows with no value in
#'   GIFT get `NA`. With the default `traits`, the added columns are
#'   `gift_woodiness_1`, `gift_growth_form_1`, `gift_lifecycle_1`,
#'   `gift_life_form_1`, `gift_climber_1`, `gift_epiphyte_1`, `gift_parasite_1`,
#'   `gift_aquatic_1`, `gift_plant_height_max`, `gift_photosynthetic_pathway`,
#'   `gift_seed_mass_mean`, `gift_dispersal_syndrome_1`, `gift_flowering_start`,
#'   `gift_flowering_end`, `gift_deciduousness_1`, and `gift_sla_mean`.
#'
#' @details
#' GIFT trait values are aggregated from many source references, each with its
#' own licence, and are served from a live API, so taxify does not redistribute
#' them. This function fetches them on demand via the suggested package GIFT;
#' the requested trait table is downloaded once per session (per trait set) and
#' cached. You are responsible for citing GIFT and the underlying references
#' (see `GIFT::GIFT_references()`) when you use the values. The first call
#' requires internet access.
#'
#' @references
#' Weigelt P, Konig C, Kreft H (2020) GIFT - A Global Inventory of Floras and
#' Traits for macroecology and biogeography. Journal of Biogeography
#' 47:16-43. \doi{10.1111/jbi.13623}
#' Denelle P, Weigelt P, Kreft H (2023) GIFT: an R package to access the Global
#' Inventory of Floras and Traits. Methods in Ecology and Evolution
#' 14:2738-2748. \doi{10.1111/2041-210X.14213}
#'
#' @seealso [gift_traits()] to browse the catalogue.
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' \donttest{
#' # add_gift() fetches trait data on demand via the GIFT package.
#' taxify("Abies alba") |>
#'   add_gift()
#'
#' # Pick specific traits by ID or name:
#' taxify("Abies alba") |>
#'   add_gift(traits = c("plant_height_max", "seed_mass_mean"))
#' }
#'
#' options(old)
#'
#' @export
add_gift <- function(x, traits = NULL, agreement = 0.66, verbose = TRUE) {
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

  catalog <- .gift_catalog(verbose)
  sel     <- .gift_resolve_traits(traits, catalog)
  is_num  <- sel$type == "numeric"

  for (i in seq_len(nrow(sel))) {
    x[[sel$column[i]]] <- if (is_num[i]) NA_real_ else NA_character_
  }

  sp <- unique(x$accepted_name[!is.na(x$accepted_name)])
  if (length(sp) == 0L) {
    return(register_enrichment(
      x, "gift", "GIFT (Weigelt et al. 2020)", NA_character_, 0L,
      "per-reference (not redistributed)"))
  }

  fetched <- .gift_fetch(sel$trait_id, agreement, verbose)

  idx     <- match(x$accepted_name, fetched$work_species)
  matched <- which(!is.na(idx))
  for (i in seq_len(nrow(sel))) {
    src <- paste0("trait_value_", sel$trait_id[i])
    if (!src %in% names(fetched)) next
    vals <- fetched[[src]][idx[matched]]
    if (is_num[i]) {
      x[[sel$column[i]]][matched] <- suppressWarnings(as.numeric(vals))
    } else {
      vals <- as.character(vals)
      vals[vals %in% c("", "NA", "NaN")] <- NA_character_
      x[[sel$column[i]]][matched] <- vals
    }
  }

  n_enriched <- sum(rowSums(!is.na(x[, sel$column, drop = FALSE])) > 0L)
  register_enrichment(
    x, "gift", "GIFT (Weigelt et al. 2020)", NA_character_, n_enriched,
    "per-reference (not redistributed)")
}

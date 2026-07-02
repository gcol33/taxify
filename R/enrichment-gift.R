# GIFT enrichment: bundled, offline, joined by accepted name.
#
# GIFT (Global Inventory of Floras and Traits) is served from a live REST API,
# but taxify never calls it at runtime. taxifydb fetches the redistributable
# subset the API returns (CC BY 4.0; restricted references excluded) once at
# build time and writes it to a `.vtr`; add_gift() joins that pre-built table
# offline, exactly like every other enrichment. The GIFT trait columns are named
# gift_<label> from GIFT's own trait labels.


# The default subset attached when `cols` is not given: well-populated, broadly
# useful traits spanning growth form, life history, size, reproduction, and leaf
# economics. Not a ceiling -- pass cols = "all" for every bundled trait, or any
# column names. Browse them with gift_traits(). Column names follow GIFT's
# labels (verbatim, including GIFT's own numeric coding suffixes).
.gift_default_cols <- c(
  "gift_woodiness_1", "gift_growth_form_1", "gift_lifecycle_1",
  "gift_life_form_1", "gift_climber_1", "gift_epiphyte_1", "gift_parasite_1",
  "gift_aquatic_1", "gift_plant_height_max", "gift_photosynthetic_pathway",
  "gift_seed_mass_mean", "gift_dispersal_syndrome_1", "gift_flowering_start",
  "gift_flowering_end", "gift_deciduousness_1", "gift_sla_mean"
)


#' Browse the bundled GIFT trait columns
#'
#' Returns the species-level trait columns available from the bundled GIFT
#' enrichment, so you can pick which to attach in [add_gift()]. Read offline
#' from the local `.vtr` (downloaded or built once); the first call may trigger
#' that one-time download.
#'
#' @return A data.frame with one row per trait column:
#' \describe{
#'   \item{column}{The `gift_<trait>` column name.}
#'   \item{type}{`"numeric"` or `"character"`.}
#' }
#' @seealso [add_gift()], [enrichment_cols()] for the same listing on any
#'   enrichment.
#' @examples
#' \donttest{
#' old <- options(taxify.data_dir = taxify_example_data())
#' gift_traits()
#' options(old)
#' }
#' @export
gift_traits <- function() {
  enrichment_cols("gift")
}


#' Add plant traits from GIFT
#'
#' Joins species-level plant traits from GIFT, the Global Inventory of Floras
#' and Traits (Weigelt et al. 2020), to a [taxify()] result by `accepted_name`.
#' GIFT aggregates published trait records to one value per species (mean for
#' numeric traits, most frequent entry for categorical ones). You choose which
#' traits to attach with `cols`; browse the available columns with
#' [gift_traits()].
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which GIFT trait columns to attach. One of: `NULL` (the default)
#'   for a convenient set of well-populated traits; the string `"all"` for every
#'   bundled trait; or a character vector of `gift_` column names (e.g.
#'   `"plant_height_max"`, with or without the `gift_` prefix). See
#'   [gift_traits()]. When left `NULL`, a one-time message notes the default set
#'   and how to request all traits.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with one added column per requested trait, named
#'   `gift_<trait>`. Numeric traits (heights, masses, areas) are doubles, the
#'   rest character. Rows with no value in GIFT get `NA`. With the default
#'   `cols`, the added columns are `gift_woodiness_1`, `gift_growth_form_1`,
#'   `gift_lifecycle_1`, `gift_life_form_1`, `gift_climber_1`, `gift_epiphyte_1`,
#'   `gift_parasite_1`, `gift_aquatic_1`, `gift_plant_height_max`,
#'   `gift_photosynthetic_pathway`, `gift_seed_mass_mean`,
#'   `gift_dispersal_syndrome_1`, `gift_flowering_start`, `gift_flowering_end`,
#'   `gift_deciduousness_1`, and `gift_sla_mean`.
#'
#' @details
#' The GIFT trait table is bundled as a pre-built `.vtr` and joined offline, so
#' no internet access is needed once it is present (the first use downloads it,
#' or builds it from source if `taxifydb` is installed). GIFT's API exposes only
#' the redistributable subset of its data (CC BY 4.0; references whose
#' underlying source is restricted are excluded), and that subset is what is
#' bundled here. Cite GIFT and, where applicable, the underlying references
#' (`GIFT::GIFT_references()`) when you use the values.
#'
#' @references
#' Weigelt P, Konig C, Kreft H (2020) GIFT - A Global Inventory of Floras and
#' Traits for macroecology and biogeography. Journal of Biogeography
#' 47:16-43. \doi{10.1111/jbi.13623}
#' Denelle P, Weigelt P, Kreft H (2023) GIFT: an R package to access the Global
#' Inventory of Floras and Traits. Methods in Ecology and Evolution
#' 14:2738-2748. \doi{10.1111/2041-210X.14213}
#'
#' @seealso [gift_traits()] to browse the available columns.
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Abies alba") |>
#'   add_gift()
#'
#' options(old)
#'
#' @export
add_gift <- function(x, cols = NULL, verbose = TRUE) {
  if (!"accepted_name" %in% names(x)) {
    stop("Input must be a taxify() result with an 'accepted_name' column.",
         call. = FALSE)
  }

  available <- .enrichment_available_cols("gift", prefix = "gift_",
                                          verbose = verbose)
  if (is.null(available)) {
    stop(paste0(
      "add_gift(): the GIFT enrichment is not available. It downloads on ",
      "first use; install 'taxifydb' to build it from source, or check your ",
      "internet connection."), call. = FALSE)
  }

  # Full col_map over every bundled gift_ column (identity: .vtr name = output).
  # The engine applies the cols selection, defaulting to .gift_default_cols.
  col_map  <- stats::setNames(available$column, available$column)
  na_types <- stats::setNames(
    lapply(available$type, function(t) if (t == "numeric") NA_real_ else NA_character_),
    available$column)

  enrich_simple(
    x,
    enrichment_name = "gift",
    col_map         = col_map,
    source_label    = "GIFT (Weigelt et al. 2020)",
    na_types        = na_types,
    cols            = cols,
    default_cols    = .gift_default_cols,
    col_prefix      = "gift_",
    verbose         = verbose
  )
}

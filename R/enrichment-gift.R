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


# Resolve the gift .vtr and read its trait columns + types, offline. Returns a
# data.frame(column, type) over the gift_ columns, or NULL if the enrichment is
# unavailable (no pre-built download and no taxifydb to build it).
.gift_available_cols <- function(verbose = TRUE) {
  vtr_path <- ensure_enrichment("gift", verbose = verbose)
  if (is.null(vtr_path)) return(NULL)
  head1 <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  gcols <- grep("^gift_", names(head1), value = TRUE)
  if (length(gcols) == 0L) return(NULL)
  types <- vapply(gcols, function(cc) {
    if (is.numeric(head1[[cc]])) "numeric" else "character"
  }, character(1))
  data.frame(column = gcols, type = unname(types), stringsAsFactors = FALSE)
}


# Resolve the user's `cols` argument to a vector of available column names.
.gift_resolve_cols <- function(cols, available) {
  if (is.null(cols)) {
    return(intersect(.gift_default_cols, available))
  }
  if (length(cols) == 1L && identical(tolower(cols), "all")) {
    return(available)
  }
  want <- as.character(cols)
  norm <- tolower(ifelse(grepl("^gift_", want), want, paste0("gift_", want)))
  idx  <- match(norm, tolower(available))
  if (anyNA(idx)) {
    bad <- want[is.na(idx)]
    stop(sprintf(paste0(
      "add_gift(): unknown trait column(s): %s. Pass gift_ column names ",
      "(e.g. \"plant_height_max\"), \"all\", or NULL for the default set. ",
      "See gift_traits() for what is available."),
      paste(bad, collapse = ", ")), call. = FALSE)
  }
  available[idx]
}


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
#' @seealso [add_gift()]
#' @examples
#' \donttest{
#' old <- options(taxify.data_dir = taxify_example_data())
#' gift_traits()
#' options(old)
#' }
#' @export
gift_traits <- function() {
  cols <- .gift_available_cols(verbose = FALSE)
  if (is.null(cols)) {
    stop(paste0(
      "gift_traits(): the GIFT enrichment is not available. It downloads on ",
      "first use; install 'taxifydb' to build it from source, or check your ",
      "internet connection."), call. = FALSE)
  }
  cols
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

  available <- .gift_available_cols(verbose = verbose)
  if (is.null(available)) {
    stop(paste0(
      "add_gift(): the GIFT enrichment is not available. It downloads on ",
      "first use; install 'taxifydb' to build it from source, or check your ",
      "internet connection."), call. = FALSE)
  }
  avail_cols <- available$column
  is_num     <- stats::setNames(available$type == "numeric", avail_cols)

  sel <- .gift_resolve_cols(cols, avail_cols)

  if (is.null(cols) && verbose &&
      is.null(.taxify_env[[".gift_default_notice_shown"]])) {
    message(sprintf(paste0(
      "add_gift(): attaching a default set of %d well-populated GIFT traits. ",
      "Pass cols = \"all\" for all %d bundled traits, or see gift_traits() ",
      "to choose."), length(sel), length(avail_cols)))
    .taxify_env[[".gift_default_notice_shown"]] <- TRUE
  }

  col_map  <- stats::setNames(sel, sel)
  na_types <- stats::setNames(
    lapply(sel, function(cc) if (isTRUE(is_num[[cc]])) NA_real_ else NA_character_),
    sel
  )

  enrich_simple(
    x,
    enrichment_name = "gift",
    col_map         = col_map,
    source_label    = "GIFT (Weigelt et al. 2020)",
    na_types        = na_types,
    verbose         = verbose
  )
}

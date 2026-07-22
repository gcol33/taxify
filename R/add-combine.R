#' Add mammal traits from COMBINE (reported values)
#'
#' Joins the COMBINE mammal trait database to a [taxify()] result by looking up
#' `accepted_name`, attaching the **reported** (directly measured or
#' literature-compiled) trait values. COMBINE ships two parallel tables over the
#' same ~6.2k mammal species: the reported table used here, and a
#' phylogenetically imputed table with the missing cells filled in by a model
#' ([add_combine_imputed()]). They are offered as two separate sources so the
#' distinction between a measured value and a model estimate stays explicit.
#'
#' @param x A data.frame returned by [taxify()].
#' @param cols Which columns to attach: \code{NULL} (default) the curated set,
#'   \code{"all"} every column the source carries, or a character vector of
#'   names. See \code{\link{enrichment_cols}}.
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns (reported values):
#' \describe{
#'   \item{combine_adult_mass_g}{Adult body mass (g).}
#'   \item{combine_adult_body_length_mm}{Adult head-body length (mm).}
#'   \item{combine_litter_size_n}{Litter size (count).}
#'   \item{combine_litters_per_year_n}{Litters per year (count).}
#'   \item{combine_max_longevity_d}{Maximum longevity (days).}
#'   \item{combine_gestation_length_d}{Gestation length (days).}
#'   \item{combine_weaning_age_d}{Weaning age (days).}
#'   \item{combine_generation_length_d}{Generation length (days).}
#'   \item{combine_dispersal_km}{Natal dispersal distance (km).}
#'   \item{combine_habitat_breadth_n}{Number of IUCN habitats (count).}
#'   \item{combine_diet_breadth_n}{Number of diet categories (count).}
#'   \item{combine_trophic_level}{Trophic level (1 herbivore, 2 omnivore,
#'     3 carnivore).}
#'   \item{combine_activity_cycle}{Activity cycle (1 nocturnal, 2 cathemeral,
#'     3 diurnal).}
#'   \item{combine_foraging_stratum}{Foraging stratum (G/Ar/A/S/M).}
#'   \item{combine_biogeographical_realm}{Biogeographical realm(s).}
#' }
#'
#' @details
#' Source: COMBINE (Soria et al. 2021, Ecology, CC0), reported table. Coverage:
#' ~6.2k mammal species, keyed on the IUCN 2020 binomial. The reported table
#' leaves a cell missing when no source measured that trait for a species; use
#' [add_combine_imputed()] for the higher-coverage phylogenetically imputed
#' values.
#'
#' @references
#' Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic and
#' extrinsic traits. Ecology 102:e03344. \doi{10.1002/ecy.3344}
#'
#' @seealso [add_combine()] for reported values with imputed gaps filled and
#'   per-trait provenance; [add_combine_imputed()] for the imputed values;
#'   [add_pantheria()], [add_anage()] for other mammal trait sources.
#'
#' @examples
#' \dontrun{
#' taxify("Vulpes vulpes", backend = "gbif") |>
#'   add_combine_reported()
#' }
#'
#' @export
add_combine_reported <- function(x, cols = NULL, verbose = TRUE) {
  enrich_simple(
    x,
    enrichment_name = "combine",
    col_map         = .combine_col_map(),
    source_label    = "COMBINE (reported)",
    cols            = cols,
    # Namespace auto-exposed extras as combine_* too, so the whole reported
    # output lives in one namespace and never collides with combine_imputed_*.
    col_prefix      = "combine_",
    out_prefix      = "combine_",
    verbose         = verbose
  )
}


#' Add mammal traits from COMBINE (phylogenetically imputed values)
#'
#' Joins the phylogenetically imputed COMBINE table to a [taxify()] result by
#' looking up `accepted_name`. This is the companion to [add_combine_reported()]:
#' the same ~6.2k mammal species, but with the cells the reported table leaves
#' missing filled in by COMBINE's phylogenetic multiple-imputation model, giving
#' near-complete coverage for the life-history traits. Imputed values are model
#' estimates, not measurements, so they are attached under their own
#' `combine_imputed_*` columns rather than replacing the reported values.
#'
#' @inheritParams add_combine_reported
#' @return The same data.frame with additional columns, mirroring
#'   [add_combine_reported()] but named `combine_imputed_*` (e.g.
#'   `combine_imputed_adult_mass_g`, `combine_imputed_gestation_length_d`).
#'   Traits COMBINE does not impute (for example `biogeographical_realm` and
#'   `habitat_breadth_n`) carry the reported coverage; the life-history traits
#'   (gestation, weaning, longevity, litter size, generation length, ...) are
#'   near-complete.
#'
#' @details
#' Source: COMBINE (Soria et al. 2021, Ecology, CC0), imputed table
#' (`trait_data_imputed.csv`). Same species set and column meanings as
#' [add_combine_reported()]; the difference is coverage. Because imputation only
#' fills gaps, applying both doors and comparing `combine_*` with
#' `combine_imputed_*` shows which values are measured versus estimated.
#'
#' @references
#' Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic and
#' extrinsic traits. Ecology 102:e03344. \doi{10.1002/ecy.3344}
#'
#' @seealso [add_combine_reported()] for the measured values; [add_combine()]
#'   for the two coalesced with per-trait provenance.
#'
#' @examples
#' \dontrun{
#' # Compare reported vs imputed gestation length for a mammal:
#' taxify("Vulpes vulpes", backend = "gbif") |>
#'   add_combine_reported() |>
#'   add_combine_imputed()
#' }
#'
#' @export
add_combine_imputed <- function(x, cols = NULL, verbose = TRUE) {
  # Namespace every exposed column with combine_imputed_ so applying both this
  # and add_combine_reported() in one pipeline never collides on a shared column.
  col_map <- stats::setNames(
    unname(.combine_col_map()),
    paste0("combine_imputed_", sub("^combine_", "", names(.combine_col_map())))
  )
  enrich_simple(
    x,
    enrichment_name = "combine_imputed",
    col_map         = col_map,
    source_label    = "COMBINE (imputed)",
    cols            = cols,
    col_prefix      = "combine_imputed_",
    out_prefix      = "combine_imputed_",
    verbose         = verbose
  )
}


#' Add mammal traits (COMBINE)
#'
#' The default COMBINE door. Attaches the reported (measured or literature
#' compiled) trait values and fills each still-missing cell from COMBINE's
#' phylogenetically imputed table, so a single call reaches the fullest coverage
#' COMBINE offers. A measurement is never overwritten: the reported value wins
#' wherever it exists and the imputed model only fills gaps. Beside every trait
#' sits a `<trait>_src` column recording where that cell came from -- `"reported"`,
#' `"imputed"`, or `NA` when neither table has it -- so a model estimate is
#' always distinguishable from a measurement.
#'
#' For a single-table view use [add_combine_reported()] (measured values only)
#' or [add_combine_imputed()] (the imputed table on its own).
#'
#' @inheritParams add_combine_reported
#' @return The same data.frame with the `combine_*` trait columns (reported
#'   values, gaps filled from the imputed table) and, beside each, a
#'   `combine_*_src` column tagging that cell as `"reported"`, `"imputed"`, or
#'   `NA`. Traits COMBINE does not impute (for example
#'   `combine_biogeographical_realm`) come out `"reported"` wherever present. If
#'   the imputed table is unavailable, the reported values are returned with
#'   every `_src` tag `"reported"` or `NA`.
#' @seealso [add_combine_reported()], [add_combine_imputed()]
#' @examples
#' \dontrun{
#' # Coverage-filled values with per-trait provenance:
#' res <- taxify("Osphranter rufus", backend = "col") |>
#'   add_combine()
#' res[, c("combine_gestation_length_d", "combine_gestation_length_d_src")]
#' }
#' @export
add_combine <- function(x, cols = NULL, verbose = TRUE) {
  # The reported door (no prefix) selects on combine_* names; the imputed door
  # (combine_imputed_ prefix) selects on bare trait tokens. Translate a cols
  # request into each vocabulary so both joins pick the same traits.
  is_all <- is.character(cols) && length(cols) == 1L && tolower(cols) == "all"
  if (is.null(cols) || is_all) {
    cols_rep <- cols
    cols_bare <- cols
  } else {
    cols_bare <- sub("^combine_(imputed_)?", "", as.character(cols))
    cols_rep  <- paste0("combine_", cols_bare)
  }

  out <- add_combine_reported(x, cols = cols_rep, verbose = verbose)
  # The imputed table may be missing (offline, taxifydb absent); degrade to
  # reported-only rather than fail the whole join.
  imp <- tryCatch(
    add_combine_imputed(x, cols = cols_bare, verbose = FALSE),
    error = function(e) NULL
  )
  # out and imp are both column-fills on the same x, so they share row order and
  # count; the imputed columns align to out row-for-row without a re-join.

  # Coalesce only the reported door's own value columns: the curated combine_*
  # col_map names plus any combine_-prefixed extras it auto-exposed. A
  # combine_imputed_* column already on the input -- from an earlier
  # add_combine_imputed() in the pipeline -- must never be swept in here, or its
  # imputed value would be re-tagged "reported". Selecting by the known reported
  # namespace (never a bare "^combine_" grep) keeps the imputed namespace out.
  reported_names <- names(.combine_col_map())
  extra_names    <- grep("^combine_(?!imputed_)", names(out),
                         value = TRUE, perl = TRUE)
  val_cols <- intersect(names(out), union(reported_names, extra_names))
  val_cols <- val_cols[!grepl("_src$", val_cols)]
  for (vcol in val_cols) {
    icol  <- paste0("combine_imputed_", sub("^combine_", "", vcol))
    rep_v <- out[[vcol]]
    imp_v <- if (!is.null(imp) && icol %in% names(imp)) {
      imp[[icol]]
    } else {
      rep(NA, length(rep_v))
    }
    src <- rep(NA_character_, length(rep_v))
    src[!is.na(imp_v)] <- "imputed"   # provisional; a measurement overrides it
    src[!is.na(rep_v)] <- "reported"
    fill <- is.na(rep_v) & !is.na(imp_v)
    if (any(fill)) rep_v[fill] <- imp_v[fill]
    out[[vcol]] <- rep_v
    out[[paste0(vcol, "_src")]] <- src
  }

  # Place each provenance tag immediately after its value column.
  ordered <- character(0)
  for (nm in names(out)) {
    if (grepl("_src$", nm) && sub("_src$", "", nm) %in% val_cols) next
    ordered <- c(ordered, nm)
    tag <- paste0(nm, "_src")
    if (nm %in% val_cols && tag %in% names(out)) ordered <- c(ordered, tag)
  }
  out[, ordered, drop = FALSE]
}


# Curated reported/imputed COMBINE column map (output = .vtr source). Shared by
# add_combine_reported() and add_combine_imputed(); the imputed door renames the
# output side to combine_imputed_*.
.combine_col_map <- function() {
  c(
    combine_adult_mass_g          = "adult_mass_g",
    combine_adult_body_length_mm  = "adult_body_length_mm",
    combine_litter_size_n         = "litter_size_n",
    combine_litters_per_year_n    = "litters_per_year_n",
    combine_max_longevity_d       = "max_longevity_d",
    combine_gestation_length_d    = "gestation_length_d",
    combine_weaning_age_d         = "weaning_age_d",
    combine_generation_length_d   = "generation_length_d",
    combine_dispersal_km          = "dispersal_km",
    combine_habitat_breadth_n     = "habitat_breadth_n",
    combine_diet_breadth_n        = "diet_breadth_n",
    combine_trophic_level         = "trophic_level",
    combine_activity_cycle        = "activity_cycle",
    combine_foraging_stratum      = "foraging_stratum",
    combine_biogeographical_realm = "biogeographical_realm"
  )
}

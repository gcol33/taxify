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
#' @seealso [add_combine_imputed()] for the imputed values; [add_pantheria()],
#'   [add_anage()] for other mammal trait sources.
#'
#' @examples
#' \donttest{
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
#' @seealso [add_combine_reported()] for the measured values.
#'
#' @examples
#' \donttest{
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
#' A thin wrapper around [add_combine_reported()], kept so existing code keeps
#' working. New code should call [add_combine_reported()] (reported values) or
#' [add_combine_imputed()] (phylogenetically imputed values) explicitly.
#'
#' @inheritParams add_combine_reported
#' @return The same as [add_combine_reported()] (the `combine_*` reported
#'   columns).
#' @seealso [add_combine_reported()], [add_combine_imputed()]
#' @examples
#' \donttest{
#' taxify("Vulpes vulpes", backend = "gbif") |>
#'   add_combine()
#' }
#' @export
add_combine <- function(x, cols = NULL, verbose = TRUE) {
  add_combine_reported(x, cols = cols, verbose = verbose)
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

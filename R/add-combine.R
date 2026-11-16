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
#'   \item{combine_reported_adult_mass_g}{Adult body mass (g).}
#'   \item{combine_reported_adult_body_length_mm}{Adult head-body length (mm).}
#'   \item{combine_reported_litter_size_n}{Litter size (count).}
#'   \item{combine_reported_litters_per_year_n}{Litters per year (count).}
#'   \item{combine_reported_max_longevity_d}{Maximum longevity (days).}
#'   \item{combine_reported_gestation_length_d}{Gestation length (days).}
#'   \item{combine_reported_weaning_age_d}{Weaning age (days).}
#'   \item{combine_reported_generation_length_d}{Generation length (days).}
#'   \item{combine_reported_dispersal_km}{Natal dispersal distance (km).}
#'   \item{combine_reported_habitat_breadth_n}{Number of IUCN habitats (count).}
#'   \item{combine_reported_diet_breadth_n}{Number of diet categories (count).}
#'   \item{combine_reported_trophic_level}{Trophic level (1 herbivore, 2 omnivore,
#'     3 carnivore).}
#'   \item{combine_reported_activity_cycle}{Activity cycle (1 nocturnal, 2 cathemeral,
#'     3 diurnal).}
#'   \item{combine_reported_foraging_stratum}{Foraging stratum (G/Ar/A/S/M).}
#'   \item{combine_reported_biogeographical_realm}{Biogeographical realm(s).}
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
#' taxify("Vulpes vulpes", backbone = "gbif") |>
#'   add_combine_reported()
#' }
#'
#' @export
add_combine_reported <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_combine_reported, cols = cols, verbose = verbose)
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
#'   Traits COMBINE does not impute (for example `combine_imputed_biogeographical_realm` and
#'   `combine_imputed_habitat_breadth_n`) carry the reported coverage; the life-history traits
#'   (gestation, weaning, longevity, litter size, generation length, ...) are
#'   near-complete.
#'
#' @details
#' Source: COMBINE (Soria et al. 2021, Ecology, CC0), imputed table
#' (`trait_data_imputed.csv`). Same species set and column meanings as
#' [add_combine_reported()]; the difference is coverage. Because imputation only
#' fills gaps, applying both functions and comparing `combine_*` with
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
#' taxify("Vulpes vulpes", backbone = "gbif") |>
#'   add_combine_reported() |>
#'   add_combine_imputed()
#' }
#'
#' @export
add_combine_imputed <- function(x, cols = NULL, verbose = TRUE) {
  enrich_door(x, .door_combine_imputed, cols = cols, verbose = verbose)
}


#' Add mammal traits (COMBINE)
#'
#' The default COMBINE function. Attaches the reported (measured or literature
#' compiled) trait values and fills each still-missing cell from COMBINE's
#' phylogenetically imputed table, so a single call reaches the fullest coverage
#' COMBINE offers. A measurement is never overwritten: the reported value wins
#' wherever it exists and the imputed model only fills gaps. Beside every trait
#' sits a `<trait>_src` column recording where that cell came from (`"reported"`,
#' `"imputed"`, or `NA` when neither table has it), so a model estimate is
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
#' res <- taxify("Osphranter rufus", backbone = "col") |>
#'   add_combine()
#' res[, c("combine_gestation_length_d", "combine_gestation_length_d_src")]
#' }
#' @export
add_combine <- function(x, cols = NULL, verbose = TRUE) {
  selected <- cols
  if (!is.null(cols) && !identical(tolower(cols), "all")) {
    selected <- sub("^combine_(reported_|imputed_)?", "", cols)
  }
  join_input <- x[, !startsWith(names(x), "combine_reported_") &
                    !startsWith(names(x), "combine_imputed_"), drop = FALSE]
  reported <- add_combine_reported(join_input, cols = selected, verbose = verbose)
  imputed <- tryCatch(add_combine_imputed(join_input, cols = selected, verbose = FALSE),
                      error = function(e) NULL)
  out <- x
  imputed_used <- rep(FALSE, nrow(x))
  reported_cols <- setdiff(names(reported), names(join_input))
  val_cols <- character()
  for (rcol in reported_cols) {
    suffix <- substring(rcol, nchar("combine_reported_") + 1L)
    vcol <- paste0("combine_", suffix)
    icol <- paste0("combine_imputed_", suffix)
    value <- reported[[rcol]]
    estimate <- if (!is.null(imputed)) imputed[[icol]] else NULL
    src <- ifelse(is.na(value), NA_character_, "reported")
    if (!is.null(estimate)) {
      fill <- is.na(value) & !is.na(estimate)
      value[fill] <- estimate[fill]
      src[fill] <- "imputed"
      if (!grepl("_(refs|source|basis|parent1|parent2)$", vcol)) {
        imputed_used <- imputed_used | fill
      }
    }
    out[[vcol]] <- value
    if (!grepl("_(refs|source|basis|parent1|parent2)$", vcol)) {
      out[[paste0(vcol, "_src")]] <- src
      val_cols <- c(val_cols, vcol)
    }
  }
  meta <- attr(reported, "taxify_meta")
  if (!is.null(imputed)) {
    imeta <- utils::tail(attr(imputed, "taxify_meta")$enrichments, 1L)
    if (length(imeta)) {
      imeta[[1L]]$n_matched <- sum(imputed_used)
      meta$enrichments <- c(meta$enrichments, imeta)
    }
  }
  attr(out, "taxify_meta") <- meta

  # Place each provenance tag immediately after its value column.
  ordered <- character(0)
  for (nm in names(out)) {
    if (grepl("_src$", nm) && sub("_src$", "", nm) %in% val_cols) next
    ordered <- c(ordered, nm)
    tag <- paste0(nm, "_src")
    if (nm %in% val_cols && tag %in% names(out)) ordered <- c(ordered, tag)
  }
  out <- out[, ordered, drop = FALSE]
  attr(out, "taxify_meta") <- meta
  out
}


# Curated COMBINE source columns shared by the reported and imputed doors.
.combine_col_map <- c(
    adult_mass_g = "adult_mass_g",
    adult_body_length_mm = "adult_body_length_mm",
    litter_size_n = "litter_size_n",
    litters_per_year_n = "litters_per_year_n",
    max_longevity_d = "max_longevity_d",
    gestation_length_d = "gestation_length_d",
    weaning_age_d = "weaning_age_d",
    generation_length_d = "generation_length_d",
    dispersal_km = "dispersal_km",
    habitat_breadth_n = "habitat_breadth_n",
    diet_breadth_n = "diet_breadth_n",
    trophic_level = "trophic_level",
    activity_cycle = "activity_cycle",
    foraging_stratum = "foraging_stratum",
    biogeographical_realm = "biogeographical_realm"
  )


.door_combine_reported <- list(
  enrichment_name = "combine",
  col_map = .combine_col_map,
  prefix = "combine_reported_",
  source_label = "COMBINE (reported)"
)


.door_combine_imputed <- list(
  enrichment_name = "combine_imputed",
  col_map = .combine_col_map,
  source_label = "COMBINE (imputed)",
  prefix = "combine_imputed_"
)


.door_combine <- utils::modifyList(.door_combine_reported, list(prefix = "combine_"))

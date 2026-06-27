#' Add reptile ecological traits and distribution (ReptTraits)
#'
#' Joins species-level reptile traits from ReptTraits (Oskyrko et al. 2024) to a
#' [taxify()] result by looking up `accepted_name`. ReptTraits is built on the
#' Reptile Database taxonomy, so it joins cleanly against the `reptiledb`
#' backbone (and any backbone that resolves to Reptile Database accepted names).
#'
#' The layer carries a per-species distribution signal -- biogeographic realm,
#' elevation range and mean climate -- alongside body-size and life-history
#' traits, across all reptiles (snakes, lizards, amphisbaenians, turtles,
#' crocodiles and the tuatara), not lizards only.
#'
#' @param x A data.frame returned by [taxify()].
#' @param verbose Logical. Default `TRUE`.
#' @return The same data.frame with additional columns:
#' \describe{
#'   \item{biogeographic_realm}{Main biogeographic realm (e.g. Neotropic,
#'     Palearctic, Afrotropic, Australo-Pacific, Marine).}
#'   \item{microhabitat}{Microhabitat (e.g. Terrestrial, Saxicolous, Arboreal).}
#'   \item{habitat_type}{Habitat type(s) (e.g. Forest, Desert, Wetlands).}
#'   \item{elevation_min_m}{Minimum recorded elevation in metres.}
#'   \item{elevation_max_m}{Maximum recorded elevation in metres.}
#'   \item{mean_annual_temp_c}{Mean annual temperature across the range
#'     (degrees Celsius).}
#'   \item{insular_endemic}{Whether the species is insular/endemic
#'     (\code{"Yes"}/\code{"No"}).}
#'   \item{body_mass_g}{Maximum body mass in grams.}
#'   \item{svl_mm}{Maximum snout-vent length (straight carapace length for
#'     turtles) in mm.}
#'   \item{total_length_mm}{Maximum total length in mm.}
#'   \item{longevity_yr}{Maximum longevity in years.}
#'   \item{diet}{Diet category (e.g. Carnivorous, Herbivorous, Omnivorous).}
#'   \item{reproductive_mode}{Reproductive mode (oviparous/viviparous/...).}
#'   \item{clutch_size}{Mean clutch or litter size.}
#'   \item{active_time}{Activity time (Diurnal/Nocturnal/Cathemeral).}
#'   \item{foraging_mode}{Foraging mode (ACT active / AMB ambush / Mixed).}
#' }
#'
#' @details
#' Source: ReptTraits v1.2 (Oskyrko et al. 2024, Scientific Data, CC BY 4.0).
#' Coverage: 12,060 reptile species. The biogeographic realm and climate fields
#' give a coarse, realm-level range signal; they are not a fine-grained
#' (TDWG-level) range like the plant ranges used by the `region` constraint.
#'
#' @references
#' Oskyrko O, Mi C, Meiri S, Du W (2024) ReptTraits: a comprehensive dataset of
#' ecological traits in reptiles. Scientific Data 11:243.
#' \doi{10.1038/s41597-024-03079-5}
#'
#' @examples
#' # Runs offline against the bundled example database.
#' old <- options(taxify.data_dir = taxify_example_data())
#'
#' taxify("Pogona vitticeps", backend = "reptiledb") |>
#'   add_repttraits()
#'
#' options(old)
#'
#' @export
add_repttraits <- function(x, verbose = TRUE) {
  num_cols <- c("elevation_min_m", "elevation_max_m", "mean_annual_temp_c",
                "body_mass_g", "svl_mm", "total_length_mm", "longevity_yr",
                "clutch_size")
  chr_cols <- c("biogeographic_realm", "microhabitat", "habitat_type",
                "insular_endemic", "diet", "reproductive_mode", "active_time",
                "foraging_mode")
  cols <- c(chr_cols, num_cols)

  col_map  <- stats::setNames(cols, cols)
  na_types <- c(
    stats::setNames(rep(list(NA_character_), length(chr_cols)), chr_cols),
    stats::setNames(rep(list(NA_real_), length(num_cols)), num_cols)
  )

  enrich_simple(
    x,
    enrichment_name = "repttraits",
    col_map         = col_map,
    source_label    = "ReptTraits (Oskyrko et al. 2024)",
    na_types        = na_types,
    verbose         = verbose
  )
}

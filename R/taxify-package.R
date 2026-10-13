#' @description
#' taxify matches taxonomic names to their accepted names against local
#' copies of published backbones, such as the Catalogue of Life, World Flora
#' Online and WoRMS. It performs the name-resolution step of 'taxize' and
#' 'WorldFlora', run offline against local backbone files. Each backbone is
#' downloaded once and recorded by version on every result row.
#'
#' @section Functions by task:
#' \describe{
#'   \item{Matching}{[taxify()] matches a character vector of names and returns
#'     one row per name with its accepted name, how it was matched and the
#'     backbone version; [summary()][summary.taxify_result] counts how a batch
#'     resolved.}
#'   \item{Checking}{[inspect()] returns only the names that need a look;
#'     [reconcile()] reports how a checklist maps onto a backbone's current
#'     treatment.}
#'   \item{Joining data}{[add_data()] joins a table the user supplies on the
#'     accepted name; each published dataset has its own `add_<source>()`
#'     function, listed by [list_enrichments()]; [add_trait()] gathers one trait
#'     from every dataset that carries it.}
#'   \item{Exploring the backbone}{[synonyms()], [children()], [downstream()],
#'     [upstream()], [add_classification()], [class2tree()], [id2name()],
#'     [parse_name()], [comm2sci()] and [sci2comm()].}
#'   \item{Backbones and versions}{[list_backbones()], [install_backbones()],
#'     [taxify_download()], [taxify_lock()], [taxify_restore()] and [cite()].}
#' }
#'
#' @section Where to start:
#' `vignette("taxify")` goes from a messy list of names to accepted names with
#' traits attached. The articles at <https://gillescolling.com/taxify/> cover
#' each task in full.
#'
#' @section Citation:
#' `citation("taxify")` gives the reference of the package; [cite()] on a
#' result lists the references of every backbone and dataset it used.
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||%
#' @importFrom stats aggregate
#' @importFrom utils read.csv read.delim
NULL

# Column names referenced via non-standard evaluation in vectra filter/select
utils::globalVariables(c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus",
  "acceptedNameUsageID", "family", "genus", "specificEpithet",
  "scientificNameAuthorship", "dist", "join_key",
  "scientificNameID", "parentNameUsageID",
  "higherClassification", "taxonRemarks", "infraspecificEpithet",
  # Euro+Med area table column references (euromed_areas)
  "area_code", "area_name", "area_level", "iso2",
  # COL-specific column references
  "canonicalName", "genericName",
  # ITIS-specific column references (unified schema)
  "taxon_id", "taxon_rank", "taxonomic_status", "accepted_name_usage_id",
  # GBIF-specific column references
  "id", "canonical_name", "genus_or_above", "specific_epithet",
  "is_synonym_flag", "accepted_id", "status", "authorship", "parent_key",
  "notho_type", "nom_status", "bracket_authorship", "bracket_year",
  "name_published_in", "origin", "infra_specific_epithet",
  # Precomputed key columns (compiled backbone)
  "key_ci", "key_normalized", "key_species",
  "accepted_name", "accepted_family", "accepted_genus",
  "accepted_taxon_id", "accepted_authorship", "is_synonym",
  # vectra string distance functions (used in NSE mutate expressions)
  "dl_dist_norm", "levenshtein_norm", "jaro_winkler",
  # register column references. `backend` is the column name inside the
  # published backend_coverage.vtr, which taxifydb writes.
  "query_genus", "life_form", "kingdom_group", "taxon_group",
  "kingdom", "phylum", "class", "order", "backend",
  # enrichment column references (used in vectra NSE select/join)
  "canonical_name", "conservation_status",
  "country_code", "invasive_status",
  "woodiness",
  "tdwg_code", "native_status",
  "light", "temperature", "moisture", "reaction", "nutrients",
  "seed_mass_mg", "plant_height_m",
  "diet_inv", "diet_vend", "diet_vect", "diet_vfish", "diet_vunk",
  "diet_scav", "diet_fruit", "diet_nect", "diet_seed", "diet_plantother",
  "foraging_water", "foraging_ground", "foraging_understory",
  "foraging_midhigh", "foraging_canopy", "foraging_aerial",
  "body_mass_g", "nocturnal",
  "beak_length", "beak_depth", "wing_length", "tail_length",
  "tarsus_length", "hand_wing_index", "habitat", "trophic_level",
  "trophic_niche", "migration",
  "longevity_mo", "litter_size", "gestation_d", "weaning_d",
  "home_range_km2", "diet_breadth", "habitat_breadth",
  "lang", "common_name",
  # Alien first records enrichment column references
  "alien_first_record", "alien_first_record_source", "alien_first_record_reference",
  # AmphiBIO enrichment column references
  "body_size_mm", "age_maturity_d", "longevity_d", "reproductive_output",
  "offspring_size_mm", "direct_development", "larval", "aquatic",
  "fossorial", "arboreal", "diurnal", "nocturnal_amphibio",
  # LEDA enrichment column references
  "raunkiaer_life_form", "raunkiaer_variable", "dispersal_type",
  "terminal_velocity_ms", "leda_seed_mass_mg", "canopy_height_m",
  "leaf_mass_mg", "sla_mm2_mg", "clonal_growth_organ",
  "floating_capacity_1week_pct",
  # Baseflor (Catminat / Julve) enrichment column references
  "flower_begin_month", "flower_end_month", "pollination_vector",
  "dispersal_mode", "breeding_system", "flower_colour", "fruit_type",
  "woody_growth_form", "continentality", "salinity",
  # TR8-backed scrape-on-demand enrichment column references
  "flower_begin_month_uk", "flower_end_month_uk", "pollination_vector_uk",
  "life_form_uk", "leaf_longevity_uk",
  "strategy_type_de", "breeding_system_de", "pollination_vector_de",
  "life_form_de", "life_span_de", "apomixis_de",
  "light_it", "temperature_it", "continentality_it", "moisture_it",
  "reaction_it", "nutrients_it", "salinity_it", "life_form_it", "chorotype_it"
))

# Package-level backbone cache environment (paths to .vtr files)
.taxify_cache <- NULL

# Package-level session state (manifest cache, version-check flags)
.taxify_env <- NULL

.onLoad <- function(libname, pkgname) {
  .taxify_cache <<- new.env(parent = emptyenv())
  .taxify_env   <<- new.env(parent = emptyenv())
}

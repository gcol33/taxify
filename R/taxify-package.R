#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||%
#' @importFrom stats aggregate
#' @importFrom utils read.csv read.delim
NULL

# Suppress R CMD check NOTEs for vectra NSE column references
utils::globalVariables(c(
  "taxonID", "scientificName", "taxonRank", "taxonomicStatus",
  "acceptedNameUsageID", "family", "genus", "specificEpithet",
  "scientificNameAuthorship", "dist", "join_key",
  "scientificNameID", "parentNameUsageID", "namePublishedIn",
  "higherClassification", "taxonRemarks", "infraspecificEpithet",
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
  "accepted_taxon_id", "is_synonym",
  # vectra string distance functions (used in NSE mutate expressions)
  "dl_dist_norm", "levenshtein_norm", "jaro_winkler",
  # register column references
  "query_genus", "life_form", "kingdom_group", "taxon_group",
  "kingdom", "phylum", "class", "order",
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
  "leaf_mass_mg", "sla_mm2_mg", "clonal_growth", "buoyancy"
))

# Package-level backbone cache environment (paths to .vtr files)
.taxify_cache <- NULL

# Package-level session state (manifest cache, version-check flags)
.taxify_env <- NULL

.onLoad <- function(libname, pkgname) {
  .taxify_cache <<- new.env(parent = emptyenv())
  .taxify_env   <<- new.env(parent = emptyenv())
}

# Join grain of the bundled enrichments, in one place: both the door guard
# (test-enrichment-grain.R) and the trait-registry guard (test-trait-genus-join.R)
# read these, so the two cannot drift apart.

# Enrichments whose .vtr is keyed on genus, not species. Joining one of these on
# the accepted_name default matches nothing and yields an all-NA column.
genus_keyed_enrichments <- function() {
  c("fungalroot",               # FungalRoot mycorrhizal type, genus-level
    "fungal_traits",            # FungalTraits, genus-level
    "cefas_btrait",             # Cefas benthic traits, coded by genus
    "blanchard",                # ant traits, genus-level
    "disperse",                 # European freshwater-invert dispersal, genus-level
    "freshwater_insects_conus", # CONUS freshwater-insect genus traits
    "ramond",                   # marine protist traits, lineage/genus-level
    "noddb")                    # NodDB nodulation, recorded per plant genus
}

# Enrichments recorded at both species and genus level: matched on species
# first, with each still-empty trait cell filled from the genus row.
mixed_grain_enrichments <- function() {
  c("epa_freshwater",           # USEPA freshwater biological traits
    "faprotax")                 # annotated at whatever rank the evidence allows
}

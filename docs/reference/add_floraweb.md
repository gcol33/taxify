# Add German plant traits from FloraWeb

Joins traits from FloraWeb (Bundesamt fuer Naturschutz) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. FloraWeb is the live national
portal carrying the BiolFlor trait data (Klotz, Kuehn & Durka 2002)
together with Rothmaler morphology and Ellenberg indicator values. This
enrichment covers the full per-species trait profile scraped from the
four FloraWeb trait pages: morphology, reproductive biology, the nine
Ellenberg indicator values, ploidy and chromosome number, and
chorological distribution. Every column carries a `_de` suffix to mark
the German-flora calibration and to avoid collisions when chained with
other plant-trait enrichments (e.g.
[`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md)
for Britain,
[`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md)
for France).

## Usage

``` r
add_floraweb(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which FloraWeb columns to attach. `NULL` (the default) attaches all of
  them; a character vector of `_de` column names attaches just those
  (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md),
  or the columns listed below). Pass `"all"` for the full set
  explicitly.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with German trait columns (all suffixed `_de`),
grouped as:

- Morphology:

  `floraweb_height_de`, `floraweb_life_form_de`,
  `floraweb_leaf_shape_de`, `floraweb_leaf_anatomy_de`,
  `floraweb_leaf_persistence_de`, `floraweb_storage_organs_de`,
  `floraweb_flowering_months_de`,
  `floraweb_flowering_months_biolflor_de`,
  `floraweb_flowering_phase_de`, `floraweb_phenological_season_de`,
  `floraweb_description_de`.

- Reproductive biology:

  `floraweb_pollination_vector_de`, `floraweb_pollinator_de`,
  `floraweb_pollinator_reward_de`, `floraweb_flower_type_de`,
  `floraweb_flower_class_de`, `floraweb_dispersal_type_de`,
  `floraweb_diaspore_type_de`, `floraweb_germinule_type_de`,
  `floraweb_reproduction_type_de`, `floraweb_vegetative_spread_de`,
  `floraweb_fertilization_type_de`, `floraweb_apomixis_de`,
  `floraweb_dicliny_de`, `floraweb_dichogamy_de`,
  `floraweb_self_incompatibility_de`, `floraweb_si_mechanism_de`,
  `floraweb_ploidy_de`, `floraweb_chromosome_number_de`,
  `floraweb_chromosome_freq_de`, `floraweb_chromosomes_de`.

- Ecology:

  the nine Ellenberg indicator values `floraweb_ell_light_de`,
  `floraweb_ell_temperature_de`, `floraweb_ell_continentality_de`,
  `floraweb_ell_moisture_de`, `floraweb_ell_moisture_variability_de`,
  `floraweb_ell_reaction_de`, `floraweb_ell_nitrogen_de`,
  `floraweb_ell_salt_de`, `floraweb_heavy_metal_resistance_de`, plus
  `floraweb_strategy_type_de` (Grime CSR), `floraweb_habitat_site_de`,
  `floraweb_formation_de`, `floraweb_plant_community_de`,
  `floraweb_biotope_type_de`, `floraweb_forest_binding_de`,
  `floraweb_hemeroby_de`, `floraweb_urbanity_de`.

- Distribution:

  `floraweb_floristic_zones_de`, `floraweb_areal_formula_de`,
  `floraweb_areal_type_de`, `floraweb_oceanity_de`,
  `floraweb_range_centre_de`, `floraweb_world_range_size_de`,
  `floraweb_world_range_frequency_de`,
  `floraweb_world_range_position_de`, `floraweb_world_range_hazard_de`,
  `floraweb_germany_range_share_de`,
  `floraweb_germany_responsibility_de`.

Categorical traits with several applicable values are joined with "; ".
Trait values are German (as published by FloraWeb / BiolFlor).

## Details

Source: FloraWeb (<https://www.floraweb.de/>), Bundesamt fuer
Naturschutz, Bonn. FloraWeb has no bulk export or API; the bundled
dataset was scraped per species (accessed 2026-06-24) and that access
date is the dataset version. The trait data largely derive from
BiolFlor, which per the BioFresh metadata statement is publicly
available and may be used without restrictions provided it is
acknowledged and cited correctly. The `.vtr` is downloaded from the
taxify release on first use and cached.

For British-flora traits see
[`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md);
for French-flora traits see
[`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md);
for European-calibration indicator values see
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md).

## References

Klotz S, Kuehn I, Durka W (2002) BIOLFLOR - Eine Datenbank zu
biologisch-oekologischen Merkmalen der Gefaesspflanzen in Deutschland.
Schriftenreihe fuer Vegetationskunde 38. Bundesamt fuer Naturschutz,
Bonn.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bellis perennis") |>
  add_floraweb()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>        input_name    matched_name   accepted_name   taxon_id accepted_id
#> 1 Bellis perennis Bellis perennis Bellis perennis wfo-ex-009  wfo-ex-009
#>      rank     family  genus  epithet authorship accepted_authorship is_synonym
#> 1 species Asteraceae Bellis perennis         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae     unknown   unknown      <NA>
#>   qualifier_position aggregate_fallback hybrid_type floraweb_height_de
#> 1               <NA>                 NA        <NA>  example_height_de
#>   floraweb_life_form_de floraweb_leaf_shape_de floraweb_leaf_anatomy_de
#> 1  example_life_form_de  example_leaf_shape_de  example_leaf_anatomy_de
#>   floraweb_leaf_persistence_de floraweb_storage_organs_de
#> 1  example_leaf_persistence_de  example_storage_organs_de
#>   floraweb_flowering_months_de floraweb_flowering_months_biolflor_de
#> 1  example_flowering_months_de  example_flowering_months_biolflor_de
#>   floraweb_flowering_phase_de floraweb_phenological_season_de
#> 1  example_flowering_phase_de  example_phenological_season_de
#>   floraweb_description_de floraweb_pollination_vector_de floraweb_pollinator_de
#> 1  example_description_de  example_pollination_vector_de  example_pollinator_de
#>   floraweb_pollinator_reward_de floraweb_flower_type_de
#> 1  example_pollinator_reward_de  example_flower_type_de
#>   floraweb_flower_class_de floraweb_dispersal_type_de floraweb_diaspore_type_de
#> 1  example_flower_class_de  example_dispersal_type_de  example_diaspore_type_de
#>   floraweb_germinule_type_de floraweb_reproduction_type_de
#> 1  example_germinule_type_de  example_reproduction_type_de
#>   floraweb_vegetative_spread_de floraweb_fertilization_type_de
#> 1  example_vegetative_spread_de  example_fertilization_type_de
#>   floraweb_apomixis_de floraweb_dicliny_de floraweb_dichogamy_de
#> 1  example_apomixis_de  example_dicliny_de  example_dichogamy_de
#>   floraweb_self_incompatibility_de floraweb_si_mechanism_de floraweb_ploidy_de
#> 1  example_self_incompatibility_de  example_si_mechanism_de  example_ploidy_de
#>   floraweb_chromosome_number_de floraweb_chromosome_freq_de
#> 1  example_chromosome_number_de  example_chromosome_freq_de
#>   floraweb_chromosomes_de floraweb_ell_light_de floraweb_ell_temperature_de
#> 1  example_chromosomes_de  example_ell_light_de  example_ell_temperature_de
#>   floraweb_ell_continentality_de floraweb_ell_moisture_de
#> 1  example_ell_continentality_de  example_ell_moisture_de
#>   floraweb_ell_moisture_variability_de floraweb_ell_reaction_de
#> 1  example_ell_moisture_variability_de  example_ell_reaction_de
#>   floraweb_ell_nitrogen_de floraweb_ell_salt_de
#> 1  example_ell_nitrogen_de  example_ell_salt_de
#>   floraweb_heavy_metal_resistance_de floraweb_strategy_type_de
#> 1  example_heavy_metal_resistance_de  example_strategy_type_de
#>   floraweb_habitat_site_de floraweb_formation_de floraweb_plant_community_de
#> 1  example_habitat_site_de  example_formation_de  example_plant_community_de
#>   floraweb_biotope_type_de floraweb_forest_binding_de floraweb_hemeroby_de
#> 1  example_biotope_type_de  example_forest_binding_de  example_hemeroby_de
#>   floraweb_urbanity_de floraweb_floristic_zones_de floraweb_areal_formula_de
#> 1  example_urbanity_de  example_floristic_zones_de  example_areal_formula_de
#>   floraweb_areal_type_de floraweb_oceanity_de floraweb_range_centre_de
#> 1  example_areal_type_de  example_oceanity_de  example_range_centre_de
#>   floraweb_world_range_size_de floraweb_world_range_frequency_de
#> 1  example_world_range_size_de  example_world_range_frequency_de
#>   floraweb_world_range_position_de floraweb_world_range_hazard_de
#> 1  example_world_range_position_de  example_world_range_hazard_de
#>   floraweb_germany_range_share_de floraweb_germany_responsibility_de
#> 1  example_germany_range_share_de  example_germany_responsibility_de
#> Sources: WFO example, FloraWeb (BfN; BiolFlor data, Klotz, Kuehn & Durka 2002) example | cite() for full citations

options(old)
```

# Add fungal lifestyle and trait data (FungalTraits)

Joins FungalTraits (Polme et al. 2020) genus-level trait data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`. Unlike other enrichments that join on
species-level `accepted_name`, FungalTraits is a genus-level database
and joins on the `genus` column already present in taxify output.

## Usage

``` r
add_fungal_traits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- fungal_traits_primary_lifestyle:

  Primary ecological role (e.g., saprotroph, mycorrhizal, pathogen,
  endophyte, lichenized, parasite).

- fungal_traits_secondary_lifestyle:

  Secondary ecological role, if any.

- fungal_traits_growth_form:

  Morphological growth form (e.g., agaricoid, corticioid, polyporoid,
  yeast).

- fungal_traits_fruitbody_type:

  Fruiting body morphology (e.g., gasteroid, pileate, resupinate).

- fungal_traits_decay_substrate:

  Substrate type for saprotrophic genera (e.g., wood, litter, dung,
  soil).

- fungal_traits_plant_pathogenic_capacity:

  Capacity to cause plant disease (e.g., high, medium, low, none).

- fungal_traits_animal_biotrophic_capacity:

  Capacity for animal biotrophy.

- fungal_traits_endophytic_interaction_capability:

  Capacity for endophytic interactions with plants.

- fungal_traits_ectomycorrhiza_exploration_type:

  Exploration type for ectomycorrhizal genera (e.g., contact, short,
  medium, long).

## Details

Source: FungalTraits (Polme et al. 2020, Fungal Diversity, CC BY 4.0).
Coverage: ~10k fungal genera. Genus-level only (not species-level).

## References

Polme S et al. (2020) FungalTraits: a user-friendly traits database of
fungi and fungus-like stramenopiles. Fungal Diversity 105:1-16.
doi:10.1007/s13225-020-00466-2

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Amanita muscaria", backbone = "gbif") |>
  add_fungal_traits()
#> Matching 1 names...
#>         input_name     matched_name    accepted_name    taxon_id accepted_id
#> 1 Amanita muscaria Amanita muscaria Amanita muscaria gbif-ex-013 gbif-ex-013
#>      rank      family   genus  epithet authorship accepted_authorship
#> 1 species Amanitaceae Amanita muscaria  (L.) Lam.           (L.) Lam.
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)         fungi      fungus    fungus      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   fungal_traits_primary_lifestyle fungal_traits_secondary_lifestyle
#> 1                 ectomycorrhizal                              <NA>
#>   fungal_traits_growth_form fungal_traits_fruitbody_type
#> 1      filamentous_mycelium                    agaricoid
#>   fungal_traits_decay_substrate fungal_traits_plant_pathogenic_capacity
#> 1                          <NA>                                    <NA>
#>   fungal_traits_animal_biotrophic_capacity
#> 1                                     <NA>
#>   fungal_traits_endophytic_interaction_capability
#> 1                                            <NA>
#>   fungal_traits_ectomycorrhiza_exploration_type
#> 1                                       contact
#> Sources: GBIF example, FungalTraits example | cite() for full citations

options(old)
```

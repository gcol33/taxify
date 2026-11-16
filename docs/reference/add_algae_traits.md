# Add macroalgal functional traits (AlgaeTraits)

Joins AlgaeTraits (Vranken et al. 2023) macroalgal functional traits to
a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. AlgaeTraits provides
morphological, ecological, and life-history traits for European
seaweeds.

## Usage

``` r
add_algae_traits(x, cols = NULL, verbose = TRUE)
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

- algae_traits_algae_body_size_cm:

  Maximum body size in centimetres.

- algae_traits_algae_growth_form:

  Growth form / body shape (e.g., filamentous, foliose, crustose).

- algae_traits_algae_calcification:

  Calcification type (e.g., uncalcified, articulated, encrusting).

- algae_traits_algae_life_span:

  Life span category (annual, perennial, etc.).

- algae_traits_algae_tidal_zone:

  Tidal zonation (e.g., supralittoral, eulittoral, sublittoral).

- algae_traits_algae_wave_exposure:

  Wave exposure tolerance (sheltered, moderately exposed, exposed).

- algae_traits_algae_environment:

  Habitat environment (marine, brackish, freshwater).

- algae_traits_algae_substrate:

  Environmental position / substrate type.

## Details

Source: AlgaeTraits (Vranken et al. 2023, VLIZ Marine Data Archive, CC
BY 4.0). Coverage: ~1,745 European macroalgae species.

## References

Vranken S et al. (2023) AlgaeTraits: a trait database for (European)
seaweeds. Earth System Science Data 15:2711-2754.
doi:10.5194/essd-15-2711-2023

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Fucus vesiculosus", backbone = "gbif") |>
  add_algae_traits()
#> Matching 1 names...
#>          input_name      matched_name     accepted_name    taxon_id accepted_id
#> 1 Fucus vesiculosus Fucus vesiculosus Fucus vesiculosus gbif-ex-014 gbif-ex-014
#>      rank   family genus     epithet authorship accepted_authorship is_synonym
#> 1 species Fucaceae Fucus vesiculosus   Linnaeus            Linnaeus      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 gbif:example (2026-06-24)     chromista  brown_alga brown alga      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   algae_traits_algae_body_size_cm algae_traits_algae_growth_form
#> 1            example_body_size_cm            example_growth_form
#>   algae_traits_algae_calcification algae_traits_algae_life_span
#> 1            example_calcification            example_life_span
#>   algae_traits_algae_tidal_zone algae_traits_algae_wave_exposure
#> 1            example_tidal_zone            example_wave_exposure
#>   algae_traits_algae_environment algae_traits_algae_substrate
#> 1            example_environment            example_substrate
#> Sources: GBIF example, AlgaeTraits example | cite() for full citations

options(old)
```

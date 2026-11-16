# Add Australian plant traits (AusTraits)

Joins species-level plant functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Values are aggregated from the
long-format AusTraits database (numeric traits by median, categorical
traits by mode).

## Usage

``` r
add_austraits(x, cols = NULL, verbose = TRUE)
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

- austraits_plant_growth_form:

  Plant growth form.

- austraits_life_history:

  Life history (annual/perennial/...).

- austraits_woodiness:

  Woodiness.

- austraits_photosynthetic_pathway:

  Photosynthetic pathway (C3/C4/CAM).

- austraits_dispersal_syndrome:

  Dispersal syndrome.

- austraits_resprouting_capacity:

  Resprouting capacity (fire response).

- austraits_flowering_time:

  Flowering time.

- austraits_plant_height_m:

  Plant height (m).

- austraits_leaf_length_mm:

  Leaf length (mm).

- austraits_leaf_width_mm:

  Leaf width (mm).

- austraits_leaf_area_mm2:

  Leaf area (mm2).

- austraits_leaf_mass_per_area:

  Leaf mass per area (g/m2; SLA is its reciprocal).

- austraits_leaf_n_per_dry_mass:

  Leaf nitrogen per dry mass (mg/g).

- austraits_leaf_p_per_dry_mass:

  Leaf phosphorus per dry mass (mg/g).

- austraits_seed_dry_mass_mg:

  Seed dry mass (mg).

- austraits_wood_density_g_cm3:

  Wood density (g/cm3).

## Details

Source: AusTraits (Falster et al. 2021, Scientific Data, CC BY 4.0).
Coverage: ~33k Australian plant taxa.

## References

Falster D et al. (2021) AusTraits, a curated plant trait database for
the Australian flora. Scientific Data 8:254.
[doi:10.1038/s41597-021-01006-6](https://doi.org/10.1038/s41597-021-01006-6)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

taxify("Eucalyptus globulus", backbone = "gbif") |>
  add_austraits()
#> Matching 1 names...
#>   Fuzzy matching 1 unmatched...
#> add_austraits(): attaching 16 of 32 columns. Pass cols = "all" for all, or see enrichment_cols("austraits").
#>            input_name matched_name accepted_name taxon_id accepted_id rank
#> 1 Eucalyptus globulus         <NA>          <NA>     <NA>        <NA> <NA>
#>   family genus epithet authorship accepted_authorship is_synonym
#> 1   <NA>  <NA>    <NA>       <NA>                <NA>         NA
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone backbone_version
#> 1             <NA>     FALSE       none         NA     <NA>             <NA>
#>   kingdom_group taxon_group  life_form qualifier qualifier_position
#> 1       plantae  angiosperm angiosperm      <NA>               <NA>
#>   aggregate_fallback hybrid_type austraits_plant_growth_form
#> 1                 NA        <NA>                        <NA>
#>   austraits_life_history austraits_woodiness austraits_photosynthetic_pathway
#> 1                   <NA>                <NA>                             <NA>
#>   austraits_dispersal_syndrome austraits_resprouting_capacity
#> 1                         <NA>                           <NA>
#>   austraits_flowering_time austraits_plant_height_m austraits_leaf_length_mm
#> 1                     <NA>                       NA                       NA
#>   austraits_leaf_width_mm austraits_leaf_area_mm2 austraits_leaf_mass_per_area
#> 1                      NA                      NA                           NA
#>   austraits_leaf_n_per_dry_mass austraits_leaf_p_per_dry_mass
#> 1                            NA                            NA
#>   austraits_seed_dry_mass_mg austraits_wood_density_g_cm3
#> 1                         NA                           NA

options(old)
```

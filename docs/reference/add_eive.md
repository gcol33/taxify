# Add EIVE ecological indicator values

Joins EIVE 1.0 (Dengler et al. 2023) ecological indicator values to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. EIVE provides continuous indicator
values for European vascular plants, superseding the original ordinal
Ellenberg values.

## Usage

``` r
add_eive(x, cols = NULL, verbose = TRUE)
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

- eive_light:

  Light indicator value (continuous).

- eive_temperature:

  Temperature indicator value (continuous).

- eive_moisture:

  Moisture indicator value (continuous).

- eive_reaction:

  Soil reaction (pH) indicator value (continuous).

- eive_nutrients:

  Nutrient indicator value (continuous).

## Details

Source: EIVE 1.0 (Dengler et al. 2023, Zenodo, CC BY 4.0). Coverage:
~14.5k European vascular plant species.

## References

Dengler J et al. (2023) EIVE 1.0: a standardized set of Ecological
Indicator Values for Europe. Vegetation Classification and Survey
4:7-29. doi:10.3897/VCS.98324

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Arrhenatherum elatius") |>
  add_eive()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>              input_name          matched_name         accepted_name   taxon_id
#> 1 Arrhenatherum elatius Arrhenatherum elatius Arrhenatherum elatius wfo-ex-008
#>   accepted_id    rank  family         genus epithet
#> 1  wfo-ex-008 species Poaceae Arrhenatherum elatius
#>                           authorship                accepted_authorship
#> 1 (L.) P.Beauv. ex J.Presl & C.Presl (L.) P.Beauv. ex J.Presl & C.Presl
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type eive_light eive_temperature
#> 1               <NA>                 NA        <NA>         11               11
#>   eive_moisture eive_reaction eive_nutrients
#> 1            11            11             11
#> Sources: WFO example, EIVE 1.0 example | cite() for full citations

options(old)
```

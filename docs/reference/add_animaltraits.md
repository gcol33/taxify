# Add cross-taxon body mass and metabolic rate (AnimalTraits)

Joins AnimalTraits body mass and metabolic rate data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_animaltraits(x, cols = NULL, verbose = TRUE)
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

- animaltraits_body_mass_kg:

  Median body mass in kg.

- animaltraits_metabolic_rate_w:

  Median metabolic rate in watts.

## Details

Source: AnimalTraits (Herberstein et al. 2022, CC0). Coverage: ~2k
species across arthropods, vertebrates, molluscs, and annelids.
Individual-level observations aggregated to species medians.

## References

Herberstein ME et al. (2022) AnimalTraits: a curated animal trait
database for body mass, metabolic rate and brain size. Scientific Data
9:265.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Drosophila melanogaster", backbone = "gbif") |>
  add_animaltraits()
#> Matching 1 names...
#>                input_name            matched_name           accepted_name
#> 1 Drosophila melanogaster Drosophila melanogaster Drosophila melanogaster
#>      taxon_id accepted_id    rank        family      genus      epithet
#> 1 gbif-ex-005 gbif-ex-005 species Drosophilidae Drosophila melanogaster
#>     authorship accepted_authorship is_synonym taxonomic_status is_hybrid
#> 1 Meigen, 1830        Meigen, 1830      FALSE         ACCEPTED     FALSE
#>   match_type fuzzy_dist backbone          backbone_version kingdom_group
#> 1      exact         NA     gbif gbif:example (2026-06-24)      animalia
#>   taxon_group life_form qualifier qualifier_position aggregate_fallback
#> 1      animal    animal      <NA>               <NA>                 NA
#>   hybrid_type animaltraits_body_mass_kg animaltraits_metabolic_rate_w
#> 1        <NA>      example_body_mass_kg      example_metabolic_rate_w
#> Sources: GBIF example, AnimalTraits example | cite() for full citations

options(old)
```

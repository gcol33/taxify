# Add butterfly traits (LepTraits)

Joins LepTraits 1.0 butterfly life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_leptraits(x, cols = NULL, verbose = TRUE)
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

- leptraits_wingspan_mm:

  Wingspan in mm (midpoint of lower and upper bounds).

- leptraits_voltinism:

  Number of generations per year.

- leptraits_diapause_stage:

  Overwintering/diapause life stage.

- leptraits_canopy_affinity:

  Canopy association category.

- leptraits_edge_affinity:

  Edge/gap affinity category.

- leptraits_moisture_affinity:

  Moisture affinity category.

- leptraits_disturbance_affinity:

  Disturbance affinity category.

- leptraits_n_hostplant_families:

  Number of host plant families used.

- leptraits_flight_months:

  Number of months with adult flight activity.

## Details

Source: LepTraits 1.0 (Shirey et al. 2022, CC0). Coverage: ~12.4k
butterfly species globally (Papilionoidea).

## References

Shirey V et al. (2022) LepTraits 1.0: A globally comprehensive dataset
of butterfly traits. Scientific Data 9:398.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vanessa cardui", backbone = "gbif") |>
  add_leptraits()
#> Matching 1 names...
#>       input_name   matched_name  accepted_name    taxon_id accepted_id    rank
#> 1 Vanessa cardui Vanessa cardui Vanessa cardui gbif-ex-011 gbif-ex-011 species
#>        family   genus epithet       authorship accepted_authorship is_synonym
#> 1 Nymphalidae Vanessa  cardui (Linnaeus, 1758)    (Linnaeus, 1758)      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type leptraits_wingspan_mm
#> 1               <NA>                 NA        <NA>   example_wingspan_mm
#>   leptraits_voltinism leptraits_diapause_stage leptraits_canopy_affinity
#> 1   example_voltinism   example_diapause_stage   example_canopy_affinity
#>   leptraits_edge_affinity leptraits_moisture_affinity
#> 1   example_edge_affinity   example_moisture_affinity
#>   leptraits_disturbance_affinity leptraits_n_hostplant_families
#> 1   example_disturbance_affinity   example_n_hostplant_families
#>   leptraits_flight_months
#> 1   example_flight_months
#> Sources: GBIF example, LepTraits example | cite() for full citations

options(old)
```

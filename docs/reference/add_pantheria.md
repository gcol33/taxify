# Add mammal life-history traits (PanTHERIA)

Joins PanTHERIA mammal life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_pantheria(x, cols = NULL, verbose = TRUE)
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

- pantheria_body_mass_g:

  Adult body mass in grams.

- pantheria_longevity_mo:

  Maximum longevity in months.

- pantheria_litter_size:

  Litter size (mean).

- pantheria_gestation_d:

  Gestation length in days.

- pantheria_weaning_d:

  Weaning age in days.

- pantheria_home_range_km2:

  Home range size in km\\^2\\.

- pantheria_diet_breadth:

  Diet breadth (number of diet categories).

- pantheria_habitat_breadth:

  Habitat breadth (number of habitat types).

## Details

Source: PanTHERIA (Jones et al. 2009, Ecological Archives, CC0).
Coverage: ~5.4k mammal species. Mammals only.

## References

Jones KE et al. (2009) PanTHERIA: a species-level database of life
history, ecology, and geography of extant and recently extinct mammals.
Ecology 90:2648.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vulpes vulpes", backbone = "gbif") |>
  add_pantheria()
#> Matching 1 names...
#>      input_name  matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Vulpes vulpes Vulpes vulpes Vulpes vulpes gbif-ex-004 gbif-ex-004 species
#>    family  genus epithet       authorship accepted_authorship is_synonym
#> 1 Canidae Vulpes  vulpes (Linnaeus, 1758)    (Linnaeus, 1758)      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type pantheria_body_mass_g
#> 1               <NA>                 NA        <NA>                    11
#>   pantheria_longevity_mo pantheria_litter_size pantheria_gestation_d
#> 1   example_longevity_mo   example_litter_size   example_gestation_d
#>   pantheria_weaning_d pantheria_home_range_km2 pantheria_diet_breadth
#> 1   example_weaning_d   example_home_range_km2   example_diet_breadth
#>   pantheria_habitat_breadth
#> 1   example_habitat_breadth
#> Sources: GBIF example, PanTHERIA example | cite() for full citations

options(old)
```

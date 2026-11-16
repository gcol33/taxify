# Add longevity and life-history traits (AnAge)

Joins AnAge (Animal Ageing and Longevity Database) traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_anage(x, cols = NULL, verbose = TRUE)
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

- anage_max_longevity_yr:

  Maximum longevity in years.

- anage_body_mass_g:

  Adult body mass in grams.

- anage_metabolic_rate_w:

  Basal metabolic rate in watts.

- anage_female_maturity_d:

  Female age at sexual maturity in days.

- anage_male_maturity_d:

  Male age at sexual maturity in days.

- anage_gestation_incubation_d:

  Gestation or incubation length in days.

- anage_litter_size:

  Litter or clutch size.

- anage_birth_mass_g:

  Mass at birth in grams.

- anage_growth_rate:

  Growth rate (1/days).

- anage_temperature_k:

  Body temperature in Kelvin.

## Details

Source: AnAge (de Magalhaes & Costa 2009, CC BY). Coverage: ~4.7k
vertebrate species (mammals, birds, reptiles, amphibians, fish).

## References

de Magalhaes JP, Costa J (2009) A database of vertebrate longevity
records and their relation to other life-history traits. Journal of
Evolutionary Biology 22:1770-1774.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vulpes vulpes", backbone = "gbif") |>
  add_anage()
#> Matching 1 names...
#>      input_name  matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Vulpes vulpes Vulpes vulpes Vulpes vulpes gbif-ex-004 gbif-ex-004 species
#>    family  genus epithet       authorship accepted_authorship is_synonym
#> 1 Canidae Vulpes  vulpes (Linnaeus, 1758)    (Linnaeus, 1758)      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type   anage_max_longevity_yr
#> 1               <NA>                 NA        <NA> example_max_longevity_yr
#>   anage_body_mass_g   anage_metabolic_rate_w   anage_female_maturity_d
#> 1                11 example_metabolic_rate_w example_female_maturity_d
#>     anage_male_maturity_d   anage_gestation_incubation_d   anage_litter_size
#> 1 example_male_maturity_d example_gestation_incubation_d example_litter_size
#>     anage_birth_mass_g   anage_growth_rate   anage_temperature_k
#> 1 example_birth_mass_g example_growth_rate example_temperature_k
#> Sources: GBIF example, AnAge example | cite() for full citations

options(old)
```

# Add European pollinator traits (EuPollTrait)

Joins European bee and hoverfly morphological, biogeographic and
ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_eupolltrait(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `eupolltrait_` columns: numeric `itd_mm`,
`tongue_length_mm`, `species_temperature_index`,
`species_continentality_index`, `area_of_occupancy`,
`extent_of_occurrence`; categorical `sociality`, `nest`,
`larval_nutrition`, `body_length_category`.

## Details

Source: EuPollTrait (Milicic et al. 2025, Zenodo, CC-BY 4.0).

## References

Milicic M et al. (2025) EuPollTrait: a trait database for European bees
and hoverflies. Zenodo.
[doi:10.5281/zenodo.18032357](https://doi.org/10.5281/zenodo.18032357)

## Examples

``` r
# \donttest{
taxify("Bombus terrestris", backend = "gbif") |>
  add_eupolltrait()
# }
```

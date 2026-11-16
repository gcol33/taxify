# Add European pollinator traits (EuPollTrait)

Joins European bee and hoverfly morphological, biogeographic and
ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_eupolltrait(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `eupolltrait_` columns: numeric
`eupolltrait_itd_mm`, `eupolltrait_tongue_length_mm`,
`eupolltrait_species_temperature_index`,
`eupolltrait_species_continentality_index`,
`eupolltrait_area_of_occupancy`, `eupolltrait_extent_of_occurrence`;
categorical `eupolltrait_sociality`, `eupolltrait_nest`,
`eupolltrait_larval_nutrition`, `eupolltrait_body_length_category`.

## Details

Source: EuPollTrait (Milicic et al. 2025, Zenodo, CC-BY 4.0).

## References

Milicic M et al. (2025) EuPollTrait: a trait database for European bees
and hoverflies. Zenodo.
[doi:10.5281/zenodo.18032357](https://doi.org/10.5281/zenodo.18032357)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Bombus terrestris", backbone = "gbif") |>
  add_eupolltrait()
} # }
```

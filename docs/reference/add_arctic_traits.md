# Add Arctic marine benthos traits

Joins Arctic Traits Database functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Each fuzzy-coded trait is reduced to its
dominant category.

## Usage

``` r
add_arctic_traits(x, cols = NULL, verbose = TRUE)
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

The same data.frame with categorical `arctic_traits_` columns:
`arctic_traits_feeding_habit`, `arctic_traits_skeleton`,
`arctic_traits_reproduction`, `arctic_traits_larval_development`,
`arctic_traits_size`, `arctic_traits_living_habit`,
`arctic_traits_body_form`, `arctic_traits_mobility`,
`arctic_traits_bioturbation`, `arctic_traits_depth_range`,
`arctic_traits_trophic_level`, `arctic_traits_fragility`,
`arctic_traits_sociability`, `arctic_traits_longevity`.

## Details

Source: Arctic Traits Database (Degen & Faulwetter 2019, University of
Vienna PHAIDRA, CC-BY 4.0).

## References

Degen R, Faulwetter S (2019) The Arctic Traits Database. University of
Vienna. [doi:10.25365/phaidra.49](https://doi.org/10.25365/phaidra.49)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Astarte borealis", backbone = "gbif") |>
  add_arctic_traits()
} # }
```

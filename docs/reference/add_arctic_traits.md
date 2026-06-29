# Add Arctic marine benthos traits

Joins Arctic Traits Database functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Each fuzzy-coded trait is reduced to its
dominant category.

## Usage

``` r
add_arctic_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with categorical `arctic_traits_` columns:
`feeding_habit`, `skeleton`, `reproduction`, `larval_development`,
`size`, `living_habit`, `body_form`, `mobility`, `bioturbation`,
`depth_range`, `trophic_level`, `fragility`, `sociability`, `longevity`.

## Details

Source: Arctic Traits Database (Degen & Faulwetter 2019, University of
Vienna PHAIDRA, CC-BY 4.0).

## References

Degen R, Faulwetter S (2019) The Arctic Traits Database. University of
Vienna. [doi:10.25365/phaidra.49](https://doi.org/10.25365/phaidra.49)

## Examples

``` r
# \donttest{
taxify("Astarte borealis", backend = "gbif") |>
  add_arctic_traits()
# }
```

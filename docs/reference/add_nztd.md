# Add NZ marine benthos traits (NZTD)

Joins New Zealand marine benthic-invertebrate functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Each fuzzy-coded trait is reduced to its
dominant modality.

## Usage

``` r
add_nztd(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with categorical `nztd_` columns: `bioturbation`,
`body_size`, `degree_of_attachment`, `feeding_mode`, `living_habit`,
`mobility`, `morphology`, `movement_method`, `rigidity`.

## Details

Source: NZTD (Lam-Gordillo et al. 2023, figshare, CC-BY 4.0).

## References

Lam-Gordillo O et al. (2023) New Zealand Trait Database (NZTD) for
marine benthic invertebrates. figshare.
[doi:10.6084/m9.figshare.21939647](https://doi.org/10.6084/m9.figshare.21939647)

## Examples

``` r
# \donttest{
taxify("Macomona liliana", backend = "gbif") |>
  add_nztd()
# }
```

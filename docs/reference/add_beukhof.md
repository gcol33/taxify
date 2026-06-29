# Add marine fish traits (Beukhof)

Joins North Atlantic / NE Pacific shelf marine-fish life-history and
ecology traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name` (species-level summaries).

## Usage

``` r
add_beukhof(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `beukhof_` columns: numeric `trophic_level`,
`aspect_ratio`, `offspring_size`, `age_maturity`, `fecundity`,
`length_infinity_cm`, `growth_coefficient`, `length_max_cm`; categorical
`habitat`, `feeding_mode`, `body_shape`, `fin_shape`, `spawning_type`.

## Details

Source: Beukhof et al. (2019) marine fish trait collection (PANGAEA,
CC-BY 4.0).

## References

Beukhof E et al. (2019) A trait collection of marine fish species from
North Atlantic and Northeast Pacific continental shelf seas. PANGAEA.
[doi:10.1594/PANGAEA.900866](https://doi.org/10.1594/PANGAEA.900866)

## Examples

``` r
# \donttest{
taxify("Gadus morhua", backend = "gbif") |>
  add_beukhof()
# }
```

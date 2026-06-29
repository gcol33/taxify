# Add bird nest traits (NestTrait)

Joins bird nest-site, nest-structure and nest-attachment indicators to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Each trait is a 0/1 presence flag; a species
may carry several flags within a group.

## Usage

``` r
add_bird_nest(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with 20 additional 0/1 indicator columns prefixed
`bird_nest_`: `brood_parasite`, `mound_builder`, seven `nestsite_*`,
seven `neststr_*` and four `nestatt_*` flags.

## Details

Source: NestTrait v2 (Chia et al. 2023, Scientific Data, CC-BY 4.0).

## References

Chia SY et al. (2023) A global database of bird nest traits. Scientific
Data.
[doi:10.1038/s41597-023-02837-1](https://doi.org/10.1038/s41597-023-02837-1)

## Examples

``` r
# \donttest{
taxify("Turdus merula", backend = "gbif") |>
  add_bird_nest()
# }
```

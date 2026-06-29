# Add freshwater mussel traits (SHELD)

Joins US freshwater-mussel life-history and host traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_sheld(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `sheld_` columns: numeric `mean_length_mm`,
`max_length_mm`, `mature_age`, `max_age`, `growth_rate`, `fecundity`,
`n_host_species`, `n_host_family`; categorical `brood`,
`marsupial_gills`, `hermaphrodite`, `shell_sculpture`.

## Details

Source: SHELD (Hopper et al. 2023, Scientific Data, CC-BY 4.0).

## References

Hopper GW et al. (2023) A trait dataset for freshwater mussels of the
United States of America. Scientific Data 10:745.
[doi:10.1038/s41597-023-02635-9](https://doi.org/10.1038/s41597-023-02635-9)

## Examples

``` r
# \donttest{
taxify("Lampsilis cardium", backend = "gbif") |>
  add_sheld()
# }
```

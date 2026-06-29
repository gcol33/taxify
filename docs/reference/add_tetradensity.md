# Add population density (TetraDENSITY)

Joins species-median terrestrial-vertebrate population density to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Only `ind/km2` records are used.

## Usage

``` r
add_tetradensity(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric `tetradensity_density_ind_km2`.

## Details

Source: Santini et al. TetraDENSITY (figshare, CC-BY 4.0). Records in
other density units are excluded to avoid mixing.

## References

Santini L et al. TetraDENSITY: a database of population density
estimates in terrestrial vertebrates. figshare.
[doi:10.6084/m9.figshare.5371633](https://doi.org/10.6084/m9.figshare.5371633)

## Examples

``` r
# \donttest{
taxify("Capreolus capreolus", backend = "gbif") |>
  add_tetradensity()
# }
```

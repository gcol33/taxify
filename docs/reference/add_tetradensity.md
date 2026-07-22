# Add population density (TetraDENSITY)

Joins species-median terrestrial-vertebrate population density to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Only `ind/km2` records are used.

## Usage

``` r
add_tetradensity(x, cols = NULL, verbose = TRUE)
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
if (FALSE) { # \dontrun{
taxify("Capreolus capreolus", backbone = "gbif") |>
  add_tetradensity()
} # }
```

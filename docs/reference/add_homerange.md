# Add mammal home-range size (HomeRange)

Joins species-median home-range size and body mass to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_homerange(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric `homerange_home_range_km2` and
`homerange_body_mass_kg`.

## Details

Source: Broekman et al. (2023) HomeRange database (Dryad, CC0).
Per-individual records are reduced to species medians.

## References

Broekman MJE et al. (2023) HomeRange: a global database of mammalian
home ranges. Dryad.
[doi:10.5061/dryad.d2547d85x](https://doi.org/10.5061/dryad.d2547d85x)

## Examples

``` r
# \donttest{
taxify("Panthera leo", backend = "gbif") |>
  add_homerange()
# }
```

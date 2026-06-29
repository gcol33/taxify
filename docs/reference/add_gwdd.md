# Add wood density (Global Wood Density Database v2)

Joins species-level wood density to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Wood density is reported as wood
specific gravity (oven-dry mass / green volume), dimensionless and
numerically equal to g/cm3.

## Usage

``` r
add_gwdd(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- gwdd_wood_density_g_cm3:

  Species-mean wood density (g/cm3).

- gwdd_wood_density_trunk_g_cm3:

  Trunk wood density (g/cm3).

- gwdd_wood_density_branch_g_cm3:

  Branch wood density (g/cm3).

- gwdd_n_measurements:

  Number of underlying measurements.

## Details

Source: Global Wood Density Database v2 (Fischer et al. 2026, New
Phytologist, CC BY 4.0). Coverage: ~17.3k species. Bark density is not
part of the aggregated source and is not included.

## References

Fischer FJ et al. (2026) The Global Wood Density Database version 2. New
Phytologist. [doi:10.1111/nph.70860](https://doi.org/10.1111/nph.70860)

## Examples

``` r
# \donttest{
taxify("Quercus robur", backend = "gbif") |>
  add_gwdd()
# }
```

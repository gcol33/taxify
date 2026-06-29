# Add thermal tolerance limits (GlobTherm)

Joins GlobTherm upper and lower thermal tolerance limits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_globtherm(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- globtherm_thermal_max_c:

  Upper thermal limit (degrees Celsius).

- globtherm_thermal_max_metric:

  Definition of the upper limit (e.g. ctmax, LT50, UTNZ); the value is
  ambiguous without it.

- globtherm_thermal_min_c:

  Lower thermal limit (degrees Celsius).

- globtherm_thermal_min_metric:

  Definition of the lower limit (e.g. ctmin, LT50, LTNZ).

- globtherm_thermal_max_error:

  Reported error on the upper limit.

- globtherm_thermal_min_error:

  Reported error on the lower limit.

## Details

Source: GlobTherm (Bennett et al. 2018, Scientific Data, CC0). Coverage:
~2.1k species across aquatic and terrestrial groups.

## References

Bennett JM et al. (2018) GlobTherm, a database on the thermal tolerance
for aquatic and terrestrial organisms. Scientific Data 5:180022.
[doi:10.1038/sdata.2018.22](https://doi.org/10.1038/sdata.2018.22)

## Examples

``` r
# \donttest{
taxify("Lepomis gibbosus", backend = "gbif") |>
  add_globtherm()
# }
```

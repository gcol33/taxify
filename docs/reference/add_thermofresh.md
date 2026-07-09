# Add freshwater thermal-tolerance traits (ThermoFresh)

Joins species-level critical thermal limits for freshwater fish,
invertebrates and amphibians to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. All values are in degrees Celsius.

## Usage

``` r
add_thermofresh(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns:

- thermofresh_ctmax:

  Critical thermal maximum (degrees C).

- thermofresh_ctmin:

  Critical thermal minimum (degrees C).

- thermofresh_lt50:

  Median lethal temperature (degrees C).

- thermofresh_ltmax:

  Lethal thermal maximum (degrees C).

- thermofresh_ltmin:

  Lethal thermal minimum (degrees C).

## Details

Source: the Freshwater thermal-tolerance database (Helena Bayat and
contributors, Zenodo, CC BY 4.0). Each source record is one tolerance
test; values are reduced to species-level medians per metric.

## References

Freshwater thermal-tolerance database. Zenodo.
[doi:10.5281/zenodo.14056760](https://doi.org/10.5281/zenodo.14056760)

## Examples

``` r
# \donttest{
taxify("Salmo trutta", backend = "gbif") |>
  add_thermofresh()
# }
```

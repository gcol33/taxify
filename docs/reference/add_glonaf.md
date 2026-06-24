# Add naturalized alien flora status (GloNAF)

Joins GloNAF (Global Naturalized Alien Flora) data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by region.

## Usage

``` r
add_glonaf(x, region, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. GloNAF region identifier(s), or `"all"`. Regions use
  TDWG-compatible codes extended with dot notation for sub-national
  units (e.g., `"USA.CA"` for California).

  - Single region: adds `naturalized` column (no suffix).

  - Multiple regions: adds `naturalized_<region>` columns.

  - `"all"`: adds one column per region in the dataset.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- naturalized:

  Integer `1` if the species is recorded as naturalized in that region,
  `NA` otherwise.

## Details

Source: GloNAF v2.0 (van Kleunen et al. 2019, Davis et al. 2025, CC BY
4.0). Coverage: ~16k alien plant taxa across ~1,300 regions. Plants
only.

## References

van Kleunen M et al. (2019) The Global Naturalized Alien Flora (GloNAF)
database. Ecology 100:e02542.

Davis K et al. (2025) The updated Global Naturalized Alien Flora (GloNAF
2.0) database. Ecology, e70245.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_glonaf(region = "EUR")

taxify("Robinia pseudoacacia") |>
  add_glonaf(region = c("EUR", "NAM"))

options(old)
```

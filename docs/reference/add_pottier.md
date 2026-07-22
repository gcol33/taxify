# Add amphibian heat tolerance (Pottier)

Joins amphibian upper thermal-limit and body-size summaries to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Per-measurement records are reduced to
species medians; heat tolerance pools across metrics and acclimation
conditions, so it is an approximate species-level upper thermal limit.

## Usage

``` r
add_pottier(x, cols = NULL, verbose = TRUE)
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

The same data.frame with numeric columns `pottier_heat_tolerance_c`,
`pottier_acclimation_temp_c`, `pottier_svl_mm`, `pottier_body_mass_g`.

## Details

Source: Pottier et al. (2022) amphibian heat tolerance database
(Scientific Data, CC-BY 4.0).

## References

Pottier P et al. (2022) A comprehensive database of amphibian heat
tolerance. Scientific Data 9:600.
[doi:10.1038/s41597-022-01704-9](https://doi.org/10.1038/s41597-022-01704-9)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Rana temporaria", backbone = "gbif") |>
  add_pottier()
} # }
```

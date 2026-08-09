# Add Collembola body length (BETSI export)

Joins per-species springtail body length to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. The value is the median over the
BETSI compilation's per-source measurements, with the observed range and
the measurement and source counts behind it.

## Usage

``` r
add_betsi_collembola_body_length(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all, or a character vector
  of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- betsi_body_length_mm:

  Body length (mm), median of the per-source measurements.

- betsi_body_length_min_mm:

  Smallest measurement (mm).

- betsi_body_length_max_mm:

  Largest measurement (mm).

- betsi_body_length_n:

  Number of measurements aggregated.

- betsi_body_length_sources:

  Number of distinct literature sources.

## Details

Source: body length values from the BETSI database (Biological and
Ecological Traits of Soil Invertebrates), the 2017 all-Collembola export
requested by Bonfanti (2018), CC BY-NC 4.0. Coverage: 1,374 species. The
European-compendia body-length floor: it agrees with the Ellers et al.
body size at Pearson r = 0.96 over 262 shared species and with the Plazi
treatment values at r = 0.906. Body length is also available through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)`("body_length")`,
which coalesces it with the Plazi, monograph and other springtail
sources.

## References

Bonfanti J (2018) Body length trait values from the BETSI database, on
all Collembola species. Zenodo.
[doi:10.5281/zenodo.1292461](https://doi.org/10.5281/zenodo.1292461)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_betsi_collembola_body_length()
} # }
```

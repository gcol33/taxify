# Add amphibian life-history traits (AmphiBIO)

Joins AmphiBIO amphibian life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_amphibio(x, cols = NULL, verbose = TRUE)
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

- body_size_mm:

  Maximum body size in mm (snout-vent length).

- age_maturity_y:

  Age at maturity in years.

- longevity_yr:

  Maximum longevity in years.

- litter_size:

  Clutch/litter size.

- reproductive_output:

  Reproductive output per year.

- offspring_size_mm:

  Offspring size in mm.

- direct_development:

  Direct development (0/1).

- larval:

  Has larval stage (0/1).

- aquatic:

  Aquatic habitat (0/1).

- fossorial:

  Fossorial habitat (0/1).

- arboreal:

  Arboreal habitat (0/1).

- diurnal:

  Diurnal activity (0/1).

- nocturnal_amphibio:

  Nocturnal activity (0/1). Named `nocturnal_amphibio` to avoid
  collision with EltonTraits' `nocturnal` column.

## Details

Source: AmphiBIO (Oliveira et al. 2017, CC BY 4.0). Coverage: ~6,800
amphibian species. Amphibians only.

## References

Oliveira BF, Sao-Pedro VA, Santos-Barrera G, Penone C, Costa GC (2017)
AmphiBIO, a global database for amphibian ecological traits. Scientific
Data 4:170123.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bufo bufo", backend = "gbif") |>
  add_amphibio()

options(old)
```

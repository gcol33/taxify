# Add WCVP native range status

Joins WCVP (World Checklist of Vascular Plants, Kew) native range data
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by TDWG botanical region.

## Usage

``` r
add_wcvp(x, region, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. TDWG Level 3 region code(s), or `"all"`. See
  [`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
  for the full list of codes.

  - Single code (e.g., `"BGM"` for Belgium): adds `native_status` column
    (no suffix).

  - Multiple codes (e.g., `c("BGM", "GER")`): adds `native_status_BGM`,
    `native_status_GER`.

  - `"all"`: adds one column per region in the dataset.

  List the region codes WCVP covers with `enrichment_groups("wcvp")`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- native_status:

  One of `"native"`, `"introduced"`, `"extinct"`, or `NA` if not
  recorded for that region.

## Details

Source: WCVP (Kew, CC BY). Coverage: ~340k plant species. Plants only.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_wcvp(region = "EUR")

taxify("Quercus robur") |>
  add_wcvp(region = c("EUR", "NAM"))

options(old)
```

# Add WCVP native range status

Joins WCVP (World Checklist of Vascular Plants, Kew) native range data
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by TDWG botanical region.

## Usage

``` r
add_wcvp(x, region, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. TDWG Level 2 region code(s), or `"all"`.

  - Single code (e.g., `"EUR"`): adds `native_status` column (no
    suffix).

  - Multiple codes (e.g., `c("EUR", "NAM")`): adds `native_status_EUR`,
    `native_status_NAM`.

  - `"all"`: adds one column per region in the dataset.

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
if (FALSE) { # \dontrun{
taxify("Quercus robur") |>
  add_wcvp(region = "EUR")

taxify("Quercus robur") |>
  add_wcvp(region = c("EUR", "NAM"))
} # }
```

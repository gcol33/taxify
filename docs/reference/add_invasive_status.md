# Add invasive species status

Joins GRIIS (Global Register of Introduced and Invasive Species) data to
a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by country.

## Usage

``` r
add_invasive_status(x, country, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- country:

  Character. ISO 3166-1 alpha-2 country code(s), or `"all"`.

  - Single code (e.g., `"AT"`): adds `invasive_status` column (no
    suffix).

  - Multiple codes (e.g., `c("AT", "DE")`): adds `invasive_status_AT`,
    `invasive_status_DE`.

  - `"all"`: adds one column per country in the dataset.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- invasive_status:

  One of `"native"`, `"introduced"`, `"invasive"`, or `NA` if not
  recorded for that country.

## Details

Source: GRIIS (Zenodo combined CSV, CC BY 4.0, 196 countries). Coverage:
~23k name x country combinations.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Robinia pseudoacacia") |>
  add_invasive_status(country = "AT")

taxify("Robinia pseudoacacia") |>
  add_invasive_status(country = c("AT", "DE"))
} # }
```

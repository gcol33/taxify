# Add invasive species status (GRIIS)

Joins GRIIS (Global Register of Introduced and Invasive Species) status
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by country. This is the source-named door for GRIIS;
GloNAF
([`add_glonaf()`](https://gillescolling.com/taxify/reference/add_glonaf.md))
carries related naturalized-alien status.

## Usage

``` r
add_griis(x, country, verbose = TRUE)
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
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_griis(country = "AT")

taxify("Robinia pseudoacacia") |>
  add_griis(country = c("AT", "DE"))

options(old)
```

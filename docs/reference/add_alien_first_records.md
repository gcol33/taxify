# Add alien species first record years

Joins alien species first record data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by country. Data from the Global Alien Species First
Record Database (Seebens et al. 2017).

## Usage

``` r
add_alien_first_records(x, country, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- country:

  Character. ISO 3166-1 alpha-2 country code(s), or `"all"`.

  - Single code (e.g., `"AT"`): adds columns without suffix.

  - Multiple codes (e.g., `c("AT", "DE")`): adds columns with country
    suffix (e.g., `alien_first_record_AT`).

  - `"all"`: adds one column set per country in the dataset.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- alien_first_record:

  Year of the first record (integer), or `NA` if not recorded for that
  country.

- alien_first_record_source:

  Database that contributed the record (e.g., `"GAVIA"`, `"CABI ISC"`).

- alien_first_record_reference:

  Original citation or reference for the record.

## Details

Source: Global Alien Species First Record Database v3.1 (Seebens et al.
2017, Nature Communications 8, 14435). CC BY 4.0. Coverage: ~77k species
x country combinations across all taxa.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_alien_first_records(country = "AT")

taxify(c("Robinia pseudoacacia", "Ailanthus altissima")) |>
  add_alien_first_records(country = c("AT", "DE"))

options(old)
```

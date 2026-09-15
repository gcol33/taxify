# Add alien species first record years

Joins alien species first record data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by location. Data from the FirstRecords dataset
(Seebens & Renard Truong 2026; Seebens et al. 2017).

## Usage

``` r
add_alien_first_records(x, location, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- location:

  Character. Location key(s), or `"all"`. A location that is a whole
  country is given by its ISO 3166-1 alpha-2 code (e.g. `"AT"`, `"US"`);
  an island or other part of a country that the source records as a
  region of its own is given by its name (e.g. `"Hawaii"`,
  `"Canary Islands"`).

  - Single location (e.g., `"AT"`): adds columns without suffix.

  - Multiple locations (e.g., `c("AT", "DE")`): adds columns with a
    location suffix (e.g., `alien_first_record_AT`).

  - `"all"`: adds one column set per location in the dataset.

  List the locations covered with
  `enrichment_groups("alien_first_records")`.

- cols:

  Character vector of value columns to attach (from
  `alien_first_record`, `alien_first_record_source`,
  `alien_first_record_reference`, plus the dataset's further columns
  such as `country_code` and `alien_first_record_status`), or `"all"`.
  `NULL` (default) attaches the first three.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- alien_first_record:

  Year of the first record (integer), or `NA` if not recorded for that
  location.

- alien_first_record_source:

  Database that contributed the record (e.g., `"GAVIA"`, `"CABI ISC"`).

- alien_first_record_reference:

  Original citation or reference for the record.

## Details

The source's locations do not overlap: a country's location excludes the
islands and other parts recorded separately, so `location = "US"` is the
first record for the United States without Hawaii and Alaska, and a
species first recorded on Hawaii has no `"US"` record unless the source
holds one for the country itself. Seebens et al. (2017) define the set
as "282 non-overlapping regions (countries and sub-national regions such
as islands)". Every row carries `country_code`, the ISO 3166-1 alpha-2
code of the country the location lies in, so a country-wide first record
is an explicit roll-up: request the country's locations and take the
earliest year.

Source: FirstRecords v4.0 (Seebens & Renard Truong 2026,
doi:10.5281/zenodo.18759840), CC BY 4.0, one row per species x location.

## References

Seebens H, Blackburn TM, Dyer EE, et al. (2017) No saturation in the
accumulation of alien species worldwide. Nature Communications 8:14435.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_alien_first_records(location = "AT")

taxify(c("Robinia pseudoacacia", "Ailanthus altissima")) |>
  add_alien_first_records(location = c("AT", "DE", "Hawaii"))

options(old)
```

# Add WFO-specific columns

Joins extra World Flora Online columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the WFO backbone.

## Usage

``` r
add_wfo_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backbone == "wfo"`.

## Value

The same data.frame with additional columns:

- scientificNameID:

  WFO scientificNameID.

- parentNameUsageID:

  WFO parentNameUsageID.

- name_published_in:

  Publication reference, under the name every backbone's `.vtr` and
  [`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
  use.

- higherClassification:

  Higher classification string.

- taxonRemarks:

  Taxonomic remarks.

- infraspecificEpithet:

  Infraspecific epithet (for subspecies, varieties, forms).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_wfo_info()

options(old)
```

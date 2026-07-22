# Browse the group values a grouped enrichment can filter on

Some enrichment doors attach data per group: GRIIS invasive status by
country
([`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md)),
WCVP native ranges by TDWG region
([`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md)),
vernacular names by language
([`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)),
alien first records by country
([`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md)).
This lists the valid group values for such a door, the way
[`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)
lists a door's columns, so a country, region, or language code need not
be guessed. Read offline from the local `.vtr` metadata (falling back to
the manifest, then a scan of the `.vtr`); the first call may trigger the
one-time download.

## Usage

``` r
enrichment_groups(source, verbose = TRUE)
```

## Arguments

- source:

  Character. A grouped enrichment name (see
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)).

- verbose:

  Logical. Print the group column and count. Default `TRUE`.

## Value

A character vector of the available group values, sorted. Stops with a
pointer to
[`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)
when `source` is a flat (non-grouped) enrichment, which has no group
values.

## See also

[`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md),
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md),
[`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())
enrichment_groups("griis")   # ISO country codes GRIIS covers
options(old)
```

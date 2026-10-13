# Browse the columns a published dataset can attach

Lists the columns available from a published dataset's pre-built `.vtr`,
for choosing which to attach through the functions that accept a `cols`
argument (such as
[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)
and
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md)).
Read offline from the local `.vtr`; the first call may trigger the
one-time download.

## Usage

``` r
enrichment_cols(source)
```

## Arguments

- source:

  Character. An enrichment name (see
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)).

## Value

A data.frame with one row per column: `column` (the name) and `type`
(`"numeric"` or `"character"`).

## See also

[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md),
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())
enrichment_cols("gift")
options(old)
```

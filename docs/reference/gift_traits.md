# Browse the bundled GIFT trait columns

Returns the species-level trait columns available from the bundled GIFT
enrichment, so you can pick which to attach in
[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md).
Read offline from the local `.vtr` (downloaded or built once); the first
call may trigger that one-time download.

## Usage

``` r
gift_traits()
```

## Value

A data.frame with one row per trait column:

- column:

  The `gift_<trait>` column name.

- type:

  `"numeric"` or `"character"`.

## See also

[`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md)

## Examples

``` r
# \donttest{
old <- options(taxify.data_dir = taxify_example_data())
gift_traits()
options(old)
# }
```

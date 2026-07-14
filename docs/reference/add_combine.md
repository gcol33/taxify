# Add mammal traits (COMBINE)

A thin wrapper around
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md),
kept so existing code keeps working. New code should call
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
(reported values) or
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)
(phylogenetically imputed values) explicitly.

## Usage

``` r
add_combine(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same as
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
(the `combine_*` reported columns).

## See also

[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md),
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)

## Examples

``` r
# \donttest{
taxify("Vulpes vulpes", backend = "gbif") |>
  add_combine()
# }
```

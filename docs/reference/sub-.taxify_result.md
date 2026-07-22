# Subset a taxify_result, preserving its metadata

The default data.frame `[` method drops the `taxify_meta` attribute that
the downstream doors
([`add_data()`](https://gillescolling.com/taxify/reference/add_data.md),
[`cite()`](https://gillescolling.com/taxify/reference/cite.md),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md))
read. This method carries `taxify_meta` and the `taxify_result` class
through row/column subsetting, so a subset (including one taken
internally by a door that reorders columns) still exposes its
provenance. A subset that collapses to a single column via `drop = TRUE`
returns the bare vector, as it would for a plain data.frame.

## Usage

``` r
# S3 method for class 'taxify_result'
x[...]
```

## Arguments

- x:

  A `taxify_result` object.

- ...:

  Row/column indices passed to the data.frame `[` method.

## Value

The subset: a `taxify_result` with `taxify_meta` preserved while it
remains a data.frame, otherwise the bare column.

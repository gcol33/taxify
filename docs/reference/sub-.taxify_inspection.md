# Subset a taxify inspection report

A subset is returned as a plain data.frame. The report header counts the
names inspected and flagged in the whole report, which a subset of its
rows or columns no longer matches; `min_tier` in
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
filters a report while keeping it one.

## Usage

``` r
# S3 method for class 'taxify_inspection'
x[...]
```

## Arguments

- x:

  A `taxify_inspection` object.

- ...:

  Row/column indices passed to the data.frame `[` method.

## Value

A data.frame, or the bare column when `drop = TRUE` collapses it to one.

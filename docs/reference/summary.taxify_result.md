# Summarise a taxify_result

Prints a compact digest of match quality and life-form scope to the
console. Uses [`cat()`](https://rdrr.io/r/base/cat.html) so output is
captured by
[`capture.output()`](https://rdrr.io/r/utils/capture.output.html) and
rendered correctly in knitr chunks.

## Usage

``` r
# S3 method for class 'taxify_result'
summary(object, ...)
```

## Arguments

- object:

  A `taxify_result` object.

- ...:

  Ignored.

## Value

`object`, invisibly.

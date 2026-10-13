# Print the keys of a dry-run GBIF request

Shows the keys alone. The `taxa` table and the match metadata stay
attached for
[`gbif_backmatch()`](https://gillescolling.com/taxify/reference/gbif_backmatch.md)
and [`cite()`](https://gillescolling.com/taxify/reference/cite.md);
`attr(x, "taxa")` shows the table.

## Usage

``` r
# S3 method for class 'taxify_gbif_keys'
print(x, ...)
```

## Arguments

- x:

  The value of `gbif_request(dry_run = TRUE)`.

- ...:

  Passed to [`print()`](https://rdrr.io/r/base/print.html).

## Value

`x`, invisibly.

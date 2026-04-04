# Look up a genus in the register

Returns the register row for the given genus, or `NULL` if not found.
Auto-loads the register on first call.

## Usage

``` r
lookup_genus(genus)
```

## Arguments

- genus:

  Character scalar. The genus name to look up.

## Value

A one-row data.frame, or `NULL` if the genus is not in the register.

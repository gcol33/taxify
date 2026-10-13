# Print a taxify_result

Delegates to the standard data.frame print method. `n_ids` and
`accepted_ids` are left out of the display when no row has more than one
accepted ID, since `accepted_id` then says the same; the object keeps
them.

## Usage

``` r
# S3 method for class 'taxify_result'
print(x, ...)
```

## Arguments

- x:

  A `taxify_result` object.

- ...:

  Passed to the next method.

## Value

`x`, invisibly.

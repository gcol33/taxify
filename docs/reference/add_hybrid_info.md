# Add hybrid parent and type information

Parses the `input_name` column from a
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md) result
to extract hybrid parent names and classify the hybrid type.

## Usage

``` r
add_hybrid_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md).

## Value

The same data.frame with additional columns:

- hybrid_parent_1:

  First parent (full binomial), `NA` if not a hybrid formula.

- hybrid_parent_2:

  Second parent (full binomial, abbreviated genus expanded), `NA` if not
  a hybrid formula.

- hybrid_type:

  One of `"nothogenus"`, `"nothospecies"`, `"formula"`, or `NA` if not a
  hybrid.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Quercus pyrenaica x Q. petraea") |>
  add_hybrid_info()
} # }
```

# Add qualifier information

Parses the `input_name` column from a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result to extract taxonomic qualifiers (cf., aff., s.l., etc.) and their
positions.

## Usage

``` r
add_qualifier_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Value

The same data.frame with additional columns:

- qualifier:

  The qualifier found (e.g., `"cf."`, `"aff."`), or `NA` if none.

- qualifier_position:

  Integer position (character index) of the qualifier in the original
  name, or `NA` if none.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Pinus cf. sylvestris") |>
  add_qualifier_info()
} # }
```

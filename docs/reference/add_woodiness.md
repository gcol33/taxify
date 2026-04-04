# Add woodiness classification

Joins woodiness data from Zanne et al. (2014) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_woodiness(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with an additional column:

- woodiness:

  One of `"woody"`, `"herbaceous"`, `"variable"`, or `NA` if not in the
  dataset.

## Details

Source: Zanne et al. 2014, Nature (Dryad, CC0). Coverage: ~50k plant
species. Plants only.

## References

Zanne AE et al. (2014) Three keys to the radiation of angiosperms into
freezing environments. Nature 506:89-92.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Quercus robur") |>
  add_woodiness()
} # }
```

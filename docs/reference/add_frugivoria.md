# Add Neotropical frugivore traits (Frugivoria)

Joins shared bird/mammal frugivore traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_frugivoria(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `frugivoria_` columns: categorical
`taxon_group`, `diet_category`; numeric `diet_breadth`, `body_mass_g`,
`body_size_mm`, `longevity`, `generation_time`.

## Details

Source: Gerstner et al. (2023) Frugivoria (EDI, CC-BY 4.0).

## References

Gerstner BE et al. (2023) Frugivoria: a trait database for birds and
mammals exhibiting frugivory across contiguous Neotropical moist
forests. EDI (edi.1220.5).

## Examples

``` r
# \donttest{
taxify("Ramphastos toco", backend = "gbif") |>
  add_frugivoria()
# }
```

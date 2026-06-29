# Add saproxylic beetle morphology (Hagge)

Joins European deadwood-beetle body and appendage morphometrics to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_saproxylic(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric `saproxylic_` columns:
`body_length_mm`, `body_width_mm`, `body_height_mm`, `mass_mg`,
`colour_lightness`, `head_length_mm`, `pronotum_length_mm`,
`elytra_length_mm`, `wing_length_mm`, `wing_aspect`,
`antenna_length_mm`, `eye_length_mm`.

## Details

Source: Hagge et al. (2021) saproxylic beetle morphology (Dryad, CC0).

## References

Hagge J et al. (2021) Morphological trait database of European
saproxylic beetles. Dryad.
[doi:10.5061/dryad.2fqz612p3](https://doi.org/10.5061/dryad.2fqz612p3)

## Examples

``` r
# \donttest{
taxify("Rhysodes sulcatus", backend = "gbif") |>
  add_saproxylic()
# }
```

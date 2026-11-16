# Add saproxylic beetle morphology (Hagge)

Joins European deadwood-beetle body and appendage morphometrics to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_saproxylic(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric `saproxylic_` columns:
`saproxylic_body_length_mm`, `saproxylic_body_width_mm`,
`saproxylic_body_height_mm`, `saproxylic_mass_mg`,
`saproxylic_colour_lightness`, `saproxylic_head_length_mm`,
`saproxylic_pronotum_length_mm`, `saproxylic_elytra_length_mm`,
`saproxylic_wing_length_mm`, `saproxylic_wing_aspect`,
`saproxylic_antenna_length_mm`, `saproxylic_eye_length_mm`.

## Details

Source: Hagge et al. (2021) saproxylic beetle morphology (Dryad, CC0).

## References

Hagge J et al. (2021) Morphological trait database of European
saproxylic beetles. Dryad.
[doi:10.5061/dryad.2fqz612p3](https://doi.org/10.5061/dryad.2fqz612p3)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Rhysodes sulcatus", backbone = "gbif") |>
  add_saproxylic()
} # }
```

# Add amphibian morphometrics (Huang)

Joins species-level amphibian body measurements to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Only measurements comparable across Anura,
Caudata and Gymnophiona are carried; per-specimen values are reduced to
species medians.

## Usage

``` r
add_huang_amph(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric `huang_amph_svl_mm`,
`huang_amph_head_length_mm`, `huang_amph_head_width_mm`,
`huang_amph_eye_diameter_mm`, `huang_amph_forelimb_length_mm`,
`huang_amph_hindlimb_length_mm` and categorical
`huang_amph_taxon_order`.

## Details

Source: Huang amphibian morphological dataset (figshare, CC-BY 4.0).

## References

Huang et al. A global amphibian morphological trait dataset. figshare.
[doi:10.6084/m9.figshare.21159229](https://doi.org/10.6084/m9.figshare.21159229)

## Examples

``` r
# \donttest{
taxify("Bufo bufo", backend = "gbif") |>
  add_huang_amph()
# }
```

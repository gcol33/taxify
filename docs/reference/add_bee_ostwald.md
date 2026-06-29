# Add bee morphometrics (Ostwald)

Joins global bee morphological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Long-format measurements are reduced to
species medians.

## Usage

``` r
add_bee_ostwald(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with numeric columns `bee_ostwald_itd_mm`
(intertegular distance), `bee_ostwald_forewing_length_mm`,
`bee_ostwald_tongue_length_mm`, `bee_ostwald_tongue_width_mm`,
`bee_ostwald_body_length_mm`, `bee_ostwald_thorax_length_mm`,
`bee_ostwald_hair_length_mm`, `bee_ostwald_hair_coverage_pct`.

## Details

Source: Ostwald et al. global bee morphology (Zenodo, CC-BY 4.0).

## References

Ostwald MM et al. (2024) A global database of bee morphological traits.
Zenodo.
[doi:10.5281/zenodo.13366989](https://doi.org/10.5281/zenodo.13366989)

## Examples

``` r
# \donttest{
taxify("Apis mellifera", backend = "gbif") |>
  add_bee_ostwald()
# }
```

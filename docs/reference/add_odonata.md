# Add odonate behavioural/ecological traits (OPD)

Joins Odonate Phenotypic Database categorical traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name` (modal value per species).

## Usage

``` r
add_odonata(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with categorical `odonata_territoriality`,
`odonata_flight_mode`, `odonata_mate_guarding`,
`odonata_habitat_openness`, `odonata_has_wing_pigment`.

## Details

Source: Odonate Phenotypic Database (Waller et al., Dryad, CC-BY 4.0).

## References

Waller JT et al. The Odonate Phenotypic Database. Dryad.
[doi:10.5061/dryad.15pm5qc](https://doi.org/10.5061/dryad.15pm5qc)

## Examples

``` r
# \donttest{
taxify("Calopteryx splendens", backend = "gbif") |>
  add_odonata()
# }
```

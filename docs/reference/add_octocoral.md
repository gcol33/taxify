# Add octocoral traits (Octocoral Trait Database)

Joins soft-coral (octocoral) colony, polyp, skeleton, symbiosis and
feeding traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Built from long-format records reduced to one
value per species.

## Usage

``` r
add_octocoral(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `octocoral_` columns: numeric `colony_height`,
`colony_width`, `tentacles_per_polyp`; categorical `growth_form`,
`type_of_growth`, `type_of_skeleton`, `polyp_retractability`,
`polyp_dimorphism`, `zooxanthellate`, `axis_presence`,
`feeding_mechanism`, `coloniality`, `skeletal_rigidity`,
`calcareous_sclerites_presence`.

## Details

Source: Octocoral Trait Database v2.2 (Gomez-Gras et al., CC-BY 4.0).

## References

Octocoral Trait Database v2.2. Zenodo.
[doi:10.5281/zenodo.14228404](https://doi.org/10.5281/zenodo.14228404)

## Examples

``` r
# \donttest{
taxify("Gorgonia ventalina", backend = "gbif") |>
  add_octocoral()
# }
```

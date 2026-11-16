# Add octocoral traits (Octocoral Trait Database)

Joins soft-coral (octocoral) colony, polyp, skeleton, symbiosis and
feeding traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Built from long-format records reduced to one
value per species.

## Usage

``` r
add_octocoral(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `octocoral_` columns: numeric
`octocoral_colony_height`, `octocoral_colony_width`,
`octocoral_tentacles_per_polyp`; categorical `octocoral_growth_form`,
`octocoral_type_of_growth`, `octocoral_type_of_skeleton`,
`octocoral_polyp_retractability`, `octocoral_polyp_dimorphism`,
`octocoral_zooxanthellate`, `octocoral_axis_presence`,
`octocoral_feeding_mechanism`, `octocoral_coloniality`,
`octocoral_skeletal_rigidity`,
`octocoral_calcareous_sclerites_presence`.

## Details

Source: Octocoral Trait Database v2.2 (Gomez-Gras et al., CC-BY 4.0).

## References

Octocoral Trait Database v2.2. Zenodo.
[doi:10.5281/zenodo.14228404](https://doi.org/10.5281/zenodo.14228404)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Gorgonia ventalina", backbone = "gbif") |>
  add_octocoral()
} # }
```

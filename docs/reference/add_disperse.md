# Add aquatic-invertebrate dispersal traits (DISPERSE)

Joins genus-level dispersal-related traits for European aquatic
macroinvertebrates to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `genus`. Each fuzzy-coded trait is reduced to its dominant
modality (with the database's own labels).

## Usage

``` r
add_disperse(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with categorical `disperse_body_size_cm`,
`disperse_life_cycle`, `disperse_repro_cycles`, `disperse_dispersal`,
`disperse_adult_lifespan`, `disperse_female_wing_mm`,
`disperse_wing_type`, `disperse_fecundity` (joined on genus).

## Details

Source: DISPERSE (Sarremejane et al. 2020, Scientific Data, CC-BY 4.0).
Joins on genus because the database is genus-resolved.

## References

Sarremejane R et al. (2020) DISPERSE, a trait database to assess the
dispersal potential of European aquatic macroinvertebrates. Scientific
Data 7:386.
[doi:10.6084/m9.figshare.c.5000633](https://doi.org/10.6084/m9.figshare.c.5000633)

## Examples

``` r
# \donttest{
taxify("Baetis rhodani", backend = "gbif") |>
  add_disperse()
# }
```

# Add reef-fish traits (Quimbayo)

Joins Atlantic and Eastern-Pacific reef-fish life-history, ecology and
behaviour traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_quimbayo(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `quimbayo_` columns: numeric
`body_size_max_cm`, `aspect_ratio`, `trophic_level`, `depth_min_m`,
`depth_max_m`, `temp_occurrence_mean_c`; categorical `home_range`,
`diel_activity`, `water_level`, `body_shape`, `mouth_position`, `diet`,
`spawning`, `size_group`.

## Details

Source: Quimbayo et al. (2021) reef-fish trait database (ESA data paper;
Zenodo, open).

## References

Quimbayo JP et al. (2021) Life-history traits, geographical range, and
conservation aspects of reef fishes. Ecology.
[doi:10.5281/zenodo.4455016](https://doi.org/10.5281/zenodo.4455016)

## Examples

``` r
# \donttest{
taxify("Thalassoma bifasciatum", backend = "gbif") |>
  add_quimbayo()
# }
```

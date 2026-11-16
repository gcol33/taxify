# Add reef-fish traits (Quimbayo)

Joins Atlantic and Eastern-Pacific reef-fish life-history, ecology and
behaviour traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_quimbayo(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `quimbayo_` columns: numeric
`quimbayo_body_size_max_cm`, `quimbayo_aspect_ratio`,
`quimbayo_trophic_level`, `quimbayo_depth_min_m`,
`quimbayo_depth_max_m`, `quimbayo_temp_occurrence_mean_c`; categorical
`quimbayo_home_range`, `quimbayo_diel_activity`, `quimbayo_water_level`,
`quimbayo_body_shape`, `quimbayo_mouth_position`, `quimbayo_diet`,
`quimbayo_spawning`, `quimbayo_size_group`.

## Details

Source: Quimbayo et al. (2021) reef-fish trait database (ESA data paper;
Zenodo, open).

## References

Quimbayo JP et al. (2021) Life-history traits, geographical range, and
conservation aspects of reef fishes. Ecology.
[doi:10.5281/zenodo.4455016](https://doi.org/10.5281/zenodo.4455016)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Thalassoma bifasciatum", backbone = "gbif") |>
  add_quimbayo()
} # }
```

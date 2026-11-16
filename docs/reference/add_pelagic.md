# Add pelagic species traits

Joins pelagic fish/cephalopod/gelatinous traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_pelagic(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `pelagic_` columns: numeric
`pelagic_depth_min_m`, `pelagic_depth_max_m`, `pelagic_temp_min_c`,
`pelagic_temp_max_c`, `pelagic_temp_mean_c`, `pelagic_length_min_tl_cm`,
`pelagic_length_max_tl_cm`, `pelagic_trophic_level`; categorical
`pelagic_vert_habitat`, `pelagic_horz_habitat`, `pelagic_body_shape`,
`pelagic_phys_defense`, `pelagic_gregarious`.

## Details

Source: Gleiber et al. (2024) Pelagic Species Trait Database (Borealis,
CC-BY 4.0).

## References

Gleiber MR et al. (2024) A trait database for pelagic species.
Scientific Data.
[doi:10.5683/SP3/0YFJED](https://doi.org/10.5683/SP3/0YFJED)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Thunnus albacares", backbone = "gbif") |>
  add_pelagic()
} # }
```

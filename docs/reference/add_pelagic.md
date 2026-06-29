# Add pelagic species traits

Joins pelagic fish/cephalopod/gelatinous traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_pelagic(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `pelagic_` columns: numeric `depth_min_m`,
`depth_max_m`, `temp_min_c`, `temp_max_c`, `temp_mean_c`,
`length_min_tl_cm`, `length_max_tl_cm`, `trophic_level`; categorical
`vert_habitat`, `horz_habitat`, `body_shape`, `phys_defense`,
`gregarious`.

## Details

Source: Gleiber et al. (2024) Pelagic Species Trait Database (Borealis,
CC-BY 4.0).

## References

Gleiber MR et al. (2024) A trait database for pelagic species.
Scientific Data.
[doi:10.5683/SP3/0YFJED](https://doi.org/10.5683/SP3/0YFJED)

## Examples

``` r
# \donttest{
taxify("Thunnus albacares", backend = "gbif") |>
  add_pelagic()
# }
```

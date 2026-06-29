# Add Mediterranean plant traits (BROT 2.0)

Joins Mediterranean-Basin plant fire-response, regeneration and
functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_brot(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `brot_` columns: numeric `seed_mass_mg`,
`sla_mm2_mg`, `height_m`, `leaf_area_mm2`; categorical `resp_fire`,
`growth_form`, `disp_mode`, `fruit_type`, `soil_seed_bank`,
`seedling_emergence`.

## Details

Source: BROT 2.0 (Tavsanoglu & Pausas 2018, Scientific Data, CC-BY 4.0).

## References

Tavsanoglu C, Pausas JG (2018) A functional trait database for
Mediterranean Basin plants (BROT 2.0). Scientific Data 5:180135.
[doi:10.6084/m9.figshare.c.3843841](https://doi.org/10.6084/m9.figshare.c.3843841)

## Examples

``` r
# \donttest{
taxify("Quercus coccifera", backend = "gbif") |>
  add_brot()
# }
```

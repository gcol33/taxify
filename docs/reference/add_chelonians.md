# Add turtle traits (CheloniansTraits)

Joins species-level turtle and tortoise traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_chelonians(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- chelonian_carapace_length_mm:

  Maximum straight-line carapace length (mm).

- chelonian_max_mass_g:

  Maximum body mass (g).

- chelonian_clutch_size_mean:

  Mean clutch size (count).

- chelonian_clutch_size_max:

  Maximum clutch size (count).

- chelonian_clutches_per_year:

  Clutches per year (count).

- chelonian_incubation_d:

  Incubation period (days).

- chelonian_age_maturity_y:

  Age at sexual maturity (years).

- chelonian_max_lifespan_y:

  Maximum lifespan (years).

- chelonian_range_size_km2:

  Range size (km2).

- chelonian_diet:

  Diet (herbivorous/carnivorous/omnivorous).

- chelonian_activity_time:

  Activity time.

- chelonian_microhabitat:

  Microhabitat (aquatic/terrestrial/...).

- chelonian_habitat_type:

  Habitat type.

- chelonian_shell_type:

  Shell type (hardshell/softshell).

## Details

Source: CheloniansTraits (Wang et al. 2025, figshare, CC BY 4.0).
Coverage: 358 turtle and tortoise species. Numeric values reported as
"min-max" ranges in the source are reduced to their midpoint.

## References

Wang Y et al. (2025) CheloniansTraits: a comprehensive trait database of
global turtles and tortoises. figshare.
[doi:10.6084/m9.figshare.28828241](https://doi.org/10.6084/m9.figshare.28828241)

## Examples

``` r
# \donttest{
taxify("Chelonia mydas", backend = "gbif") |>
  add_chelonians()
# }
```

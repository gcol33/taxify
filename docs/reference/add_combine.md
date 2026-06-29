# Add mammal traits (COMBINE)

Joins COMBINE mammal traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. COMBINE is a separate, coalesced
mammal trait source; it is offered alongside
[`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md),
not as a replacement. Reported (not phylogenetically imputed) values are
used.

## Usage

``` r
add_combine(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- combine_adult_mass_g:

  Adult body mass (g).

- combine_adult_body_length_mm:

  Adult head-body length (mm).

- combine_litter_size_n:

  Litter size (count).

- combine_litters_per_year_n:

  Litters per year (count).

- combine_max_longevity_d:

  Maximum longevity (days).

- combine_gestation_length_d:

  Gestation length (days).

- combine_weaning_age_d:

  Weaning age (days).

- combine_generation_length_d:

  Generation length (days).

- combine_dispersal_km:

  Natal dispersal distance (km).

- combine_habitat_breadth_n:

  Number of IUCN habitats (count).

- combine_diet_breadth_n:

  Number of diet categories (count).

- combine_trophic_level:

  Trophic level (1 herbivore, 2 omnivore, 3 carnivore).

- combine_activity_cycle:

  Activity cycle (1 nocturnal, 2 cathemeral, 3 diurnal).

- combine_foraging_stratum:

  Foraging stratum (G/Ar/A/S/M).

- combine_biogeographical_realm:

  Biogeographical realm(s).

## Details

Source: COMBINE (Soria et al. 2021, Ecology, CC0). Coverage: ~6.2k
mammal species. Keyed on the IUCN 2020 binomial.

## References

Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic
and extrinsic traits. Ecology 102:e03344.
[doi:10.1002/ecy.3344](https://doi.org/10.1002/ecy.3344)

## Examples

``` r
# \donttest{
taxify("Vulpes vulpes", backend = "gbif") |>
  add_combine()
# }
```

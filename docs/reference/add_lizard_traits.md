# Add lizard life-history and ecological traits (Meiri 2018)

Joins lizard trait data from Meiri (2018) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_lizard_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- lizard_body_mass_g:

  Body mass in grams.

- lizard_svl_mm:

  Snout-vent length in mm.

- lizard_tail_length_mm:

  Tail length in mm.

- lizard_clutch_size:

  Clutch size.

- lizard_clutch_frequency:

  Clutches per year.

- lizard_longevity_yr:

  Maximum longevity in years.

- lizard_diet:

  Diet category.

- lizard_habitat:

  Habitat type.

- lizard_activity_time:

  Activity time (diurnal/nocturnal/crepuscular).

- lizard_foraging_mode:

  Foraging mode (sit-and-wait/active).

## Details

Source: Meiri (2018, Global Ecology and Biogeography, CC BY 4.0).
Coverage: ~6,600 lizard species. Lizards only.

## References

Meiri S (2018) Traits of lizards of the world: Variation around a
successful evolutionary design. Global Ecology and Biogeography
27:1168-1172.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Pogona vitticeps", backend = "gbif") |>
  add_lizard_traits()

options(old)
```

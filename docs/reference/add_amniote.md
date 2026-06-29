# Add amniote life-history traits (Amniote Life History Database)

Joins uniform life-history traits for birds, mammals and reptiles to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_amniote(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- amniote_class:

  Taxonomic class (Aves/Mammalia/Reptilia).

- amniote_adult_body_mass_g:

  Adult body mass (g).

- amniote_no_sex_body_mass_g:

  Unsexed adult body mass (g).

- amniote_female_body_mass_g:

  Female body mass (g).

- amniote_male_body_mass_g:

  Male body mass (g).

- amniote_adult_svl_cm:

  Adult snout-vent length (cm).

- amniote_maximum_longevity_y:

  Maximum longevity (years).

- amniote_litter_clutch_size:

  Litter or clutch size (count).

- amniote_clutches_per_y:

  Litters or clutches per year (count).

- amniote_egg_mass_g:

  Egg mass (g).

- amniote_incubation_d:

  Incubation period (days).

- amniote_female_maturity_d:

  Age at female maturity (days).

- amniote_gestation_d:

  Gestation length (days).

- amniote_weaning_d:

  Weaning age (days).

- amniote_birth_hatching_wt_g:

  Birth or hatching weight (g).

## Details

Source: Amniote Life History Database (Myhrvold et al. 2015, Ecology,
CC0). Coverage: 21,322 species across birds, mammals and reptiles.

## References

Myhrvold NP et al. (2015) An amniote life-history database to perform
comparative analyses with birds, mammals, and reptiles. Ecology 96:3109.
[doi:10.1890/15-0846R.1](https://doi.org/10.1890/15-0846R.1)

## Examples

``` r
# \donttest{
taxify("Accipiter badius", backend = "gbif") |>
  add_amniote()
# }
```
